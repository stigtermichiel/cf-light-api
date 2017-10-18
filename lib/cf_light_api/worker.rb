require 'cfoundry'
require 'json'
require 'redlock'
require 'logger'
require 'graphite-api'
require 'date'
require 'redis'
require_relative 'environment_checker'

class CFLightAPIWorker
  if ENV['NEW_RELIC_LICENSE_KEY']
    require 'newrelic_rpm'
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    include NewRelic::Agent::MethodTracer
  end

  def initialize(redis)
    @logger = Logger.new(STDOUT)
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime} [cf_light_api:worker]: #{msg}\n"
    end

    EnvironmentChecker.new

    @redis = redis
    @lock_manager = Redlock::Client.new([@redis])
  end

  def formatted_instance_stats_for_app app
    instances = cf_rest("/v2/apps/#{app['metadata']['guid']}/stats")[0]
    raise "Unable to retrieve app instance stats: '#{instances['error_code']}'" if instances['error_code']
    instances.map {|key, value| value}
  end

  def cf_rest(path, method='GET')
    @logger.info "Making #{method} request for #{path}..."

    resources = []
    response = json_response(path, method)

    # Some endpoints return a 'resources' array, others are flat, depending on the path.
    if response['resources']
      resources << response['resources']
    else
      resources << response
    end

    # Handle the pagination by recursing over myself until we get a response which doesn't contain a 'next_url'
    # at which point all the resources are returned up the stack and flattened.
    resources << cf_rest(response['next_url'], method) unless response['next_url'] == nil
    resources.flatten
  end

  def json_response(path, method='GET')
    JSON.parse(@cf_client.base.rest_client.request(method, path)[1][:body])
  end

  def get_client(cf_api=ENV['CF_API'], cf_user=ENV['CF_USER'], cf_password=ENV['CF_PASSWORD'])
    client = CFoundry::Client.get(cf_api)
    client.login({:username => cf_user, :password => cf_password})
    client
  end

  def send_instance_usage_data_to_graphite(instance_stats, org, space, app_name)
    sanitised_app_name = app_name.gsub ".", "_" # Some apps have dots in the app name which breaks the Graphite key path

    instance_stats.each_with_index do |instance_data, index|
      graphite_base_key = "cf_apps.#{ENV['CF_ENV_NAME']}.#{org}.#{space}.#{sanitised_app_name}.#{index}"
      @logger.info "  Exporting app instance \##{index} usage statistics to Graphite, path '#{graphite_base_key}'"

      # Quota data
      ['mem_quota', 'disk_quota'].each do |key|
        @graphite.metrics "#{graphite_base_key}.#{key}" => instance_data['stats'][key]
      end

      # Usage data
      ['mem', 'disk', 'cpu'].each do |key|
        @graphite.metrics "#{graphite_base_key}.#{key}" => instance_data['stats']['usage'][key]
      end
    end
  end

  def send_org_quota_data_to_graphite(org_name, quota)
    graphite_base_key = "cf_orgs.#{ENV['CF_ENV_NAME']}.#{org_name}"
    @logger.info "  Exporting org quota statistics to Graphite, path '#{graphite_base_key}'"

    quota.keys.each do |key|
      @graphite.metrics "#{graphite_base_key}.quota.#{key}" => quota[key]
    end
  end

  def put_in_redis(key, data)
    @redis.set key, data.to_json
  end

  def format_duration(elapsed_seconds)
    seconds = elapsed_seconds % 60
    minutes = (elapsed_seconds / 60) % 60
    hours = elapsed_seconds / (60 * 60)
    format("%02d hrs, %02d mins, %02d secs", hours, minutes, seconds)
  end

  def format_routes_for_app(app, domains)
    routes = cf_rest app['entity']['routes_url']
    routes.collect do |route|
      host = route['entity']['host']
      path = route['entity']['path']

      domain = domains.find {|a_domain| a_domain['metadata']['guid'] == route['entity']['domain_guid']}
      domain = domain['entity']['name']

      "#{host}.#{domain}#{path}"
    end
  end

  def update_cf_data
    @cf_client = nil
    @graphite = GraphiteAPI.new(graphite: "#{ENV['GRAPHITE_HOST']}:#{ENV['GRAPHITE_PORT']}") if ENV['GRAPHITE_HOST'] and ENV['GRAPHITE_PORT'] and ENV['CF_ENV_NAME']

    begin
      lock = @lock_manager.lock("#{ENV['REDIS_KEY_PREFIX']}:lock", 5*60*1000)
      if lock
        start_time = Time.now

        @logger.info "Updating data..."
        @cf_client = get_client # Ensure we have a fresh auth token...

        apps = cf_rest('/v2/apps?results-per-page=100')
        orgs = cf_rest('/v2/organizations?results-per-page=100')
        quotas = cf_rest('/v2/quota_definitions?results-per-page=100')
        spaces = cf_rest('/v2/spaces?results-per-page=100')
        stacks = cf_rest('/v2/stacks?results-per-page=100')
        domains = cf_rest('/v2/domains?results-per-page=100')

        put_in_redis "#{ENV['REDIS_KEY_PREFIX']}:orgs", format_orgs(orgs, quotas)
        put_in_redis "#{ENV['REDIS_KEY_PREFIX']}:apps", format_apps(apps, spaces, orgs, stacks, domains)
        put_in_redis "#{ENV['REDIS_KEY_PREFIX']}:last_updated", {:last_updated => Time.now}

        @logger.info "Update completed in #{format_duration(Time.now.to_f - start_time.to_f)}..."
        @lock_manager.unlock(lock)
        @cf_client.logout
      else
        @logger.info "Update already running in another instance!"
      end

    rescue Rufus::Scheduler::TimeoutError
      @logger.info 'Data update took too long and was aborted, waiting for the lock to expire before trying again...'
      @cf_client.logout
    end
  end

  def format_apps(apps, spaces, orgs, stacks, domains)
    apps.map do |app|
      # TODO: This is a bit repetative, could maybe improve?
      space = spaces.find {|a_space| a_space['metadata']['guid'] == app['entity']['space_guid']}
      org = orgs.find {|an_org| an_org['metadata']['guid'] == space['entity']['organization_guid']}
      stack = stacks.find {|a_stack| a_stack['metadata']['guid'] == app['entity']['stack_guid']}
      routes = format_routes_for_app(app, domains)

      running = (app['entity']['state'] == "STARTED")

      base_data = {
          :buildpack => app['entity']['buildpack'],
          :data_from => Time.now.to_i,
          :diego => app['entity']['diego'],
          :docker => app['entity']['docker_image'] ? true : false,
          :docker_image => app['entity']['docker_image'],
          :guid => app['metadata']['guid'],
          :last_uploaded => app['metadata']['updated_at'] ? DateTime.parse(app['metadata']['updated_at']).strftime('%Y-%m-%d %T %z') : nil,
          :name => app['entity']['name'],
          :org => org['entity']['name'],
          :routes => routes,
          :space => space['entity']['name'],
          :stack => stack['entity']['name'],
          :state => app['entity']['state']
      }

      # Add additional data, such as instance usage statistics - but this is only possible if the instances are running.
      additional_data = {}

      begin
        instance_stats = []
        if running
          instance_stats = formatted_instance_stats_for_app(app)
          running_instances = instance_stats.select {|instance| instance['stats']['uris'] if instance['state'] == 'RUNNING'}
          raise "There are no running instances of this app." if running_instances.empty?

          if @graphite
            send_instance_usage_data_to_graphite(instance_stats, org['entity']['name'], space['entity']['name'], app['entity']['name'])
          end
        end

        additional_data = {
            :running => running,
            :instances => instance_stats,
            :error => nil
        }

      rescue => e
        # Most exceptions here will be caused by the app or one of the instances being in a non-standard state,
        # for example, trying to query an app which was present when the worker began updating, but was stopped
        # before we reached this section, so we just catch all exceptions, log the reason and move on.
        @logger.info "  #{org['entity']['name']} #{space['entity']['name']}: '#{app['entity']['name']}' error: #{e.message}"
        additional_data = {
            :running => 'error',
            :instances => [],
            :error => e.message
        }
      end

      base_data.merge additional_data
    end
  end

  def format_orgs(orgs, quotas)
    orgs.map do |org|
      quota = quotas.find {|a_quota| a_quota['metadata']['guid'] == org['entity']['quota_definition_guid']}

      quota = {
          :total_services => quota['entity']['total_services'],
          :total_routes => quota['entity']['total_routes'],
          :memory_limit => quota['entity']['memory_limit'] * 1024 * 1024
      }

      send_org_quota_data_to_graphite(org['entity']['name'], quota) if @graphite

      {
          :guid => org['metadata']['guid'],
          :name => org['entity']['name'],
          :quota => quota
      }
    end
  end


  if ENV['NEW_RELIC_LICENSE_KEY']
    add_transaction_tracer :update_cf_data, category: :task
    add_method_tracer :update_cf_data
  end

end
