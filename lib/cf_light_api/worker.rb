require 'cfoundry'
require 'json'
require 'redlock'
require 'logger'
require 'graphite-api'
require 'date'
require 'redis'
require_relative 'environment_checker'
require_relative 'org_formatter'
require_relative 'apps_formatter'

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
    @graphite = GraphiteAPI.new(graphite: "#{ENV['GRAPHITE_HOST']}:#{ENV['GRAPHITE_PORT']}") if ENV['GRAPHITE_HOST'] and ENV['GRAPHITE_PORT'] and ENV['CF_ENV_NAME']
  end

  def update_cf_data
      lock = @lock_manager.lock("#{ENV['REDIS_KEY_PREFIX']}:lock", 5*60*1000)
      if lock
        start_time = Time.now

        @logger.info "Updating data..."
        cf_client = get_client # Ensure we have a fresh auth token...

        apps = cf_rest('/v2/apps?results-per-page=100', cf_client)
        orgs = cf_rest('/v2/organizations?results-per-page=100', cf_client)
        quotas = cf_rest('/v2/quota_definitions?results-per-page=100', cf_client)
        spaces = cf_rest('/v2/spaces?results-per-page=100', cf_client)
        stacks = cf_rest('/v2/stacks?results-per-page=100', cf_client)
        domains = cf_rest('/v2/domains?results-per-page=100', cf_client)

        put_in_redis "#{ENV['REDIS_KEY_PREFIX']}:orgs", OrgFormatter.new(orgs, quotas, @graphite).format_orgs
        put_in_redis "#{ENV['REDIS_KEY_PREFIX']}:apps", AppsFormatter.new(apps, spaces, orgs, stacks, domains, cf_client, @logger).format_apps
        put_in_redis "#{ENV['REDIS_KEY_PREFIX']}:last_updated", {:last_updated => Time.now}

        @logger.info "Update completed in #{format_duration(Time.now.to_f - start_time.to_f)}..."
        @lock_manager.unlock(lock)
        cf_client.logout
      else
        @logger.info "Update already running in another instance!"
      end

  end

  def cf_rest(path, client, method='GET')
    @logger.info "Making #{method} request for #{path}..."

    resources = []
    response = json_response(path, client, method)

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

  def json_response(path, client, method='GET')
    JSON.parse(client.base.rest_client.request(method, path)[1][:body])
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

  def put_in_redis(key, data)
    @redis.set key, data.to_json
  end

  def format_duration(elapsed_seconds)
    seconds = elapsed_seconds % 60
    minutes = (elapsed_seconds / 60) % 60
    hours = elapsed_seconds / (60 * 60)
    format("%02d hrs, %02d mins, %02d secs", hours, minutes, seconds)
  end

  if ENV['NEW_RELIC_LICENSE_KEY']
    add_transaction_tracer :update_cf_data, category: :task
    add_method_tracer :update_cf_data
  end

end
