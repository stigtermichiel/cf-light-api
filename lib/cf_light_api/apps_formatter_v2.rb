require 'parallel'

class AppsFormatterV2

  def initialize(apps, logger, cf_service, graphite)
    @apps = apps
    @logger = logger
    @cf_service = cf_service
    @graphite = graphite
  end

  def format
    stacks = @cf_service.get_data_for('/v2/stacks?results-per-page=100')
    spaces = @cf_service.get_data_for('/v2/spaces?results-per-page=100')
    orgs = @cf_service.get_data_for('/v2/organizations?results-per-page=100')

    parallel_connections = EnvironmentChecker.number_of_threads_env

    Parallel.map(@apps, in_threads: parallel_connections) do |app|
      app_summary = @cf_service.json_response("/v2/apps/#{app['metadata']['guid']}/summary")

      space = spaces.find {|a_space| a_space['metadata']['guid'] == app_summary['space_guid']}
      stack = stacks.find {|a_stack| a_stack['metadata']['guid'] == app_summary['stack_guid']}
      org = orgs.find {|an_org| an_org['metadata']['guid'] == space['entity']['organization_guid']}

      running = app_summary['state'] == 'STARTED'

      base_data = {
          :buildpack => app_summary['buildpack'],
          :data_from => Time.now.to_i,
          :diego => app_summary['diego'],
          :docker => app_summary['docker_image'] ? true : false,
          :docker_image => app_summary['docker_image'],
          :guid => app_summary['guid'],
          :last_uploaded => (app['metadata']['updated_at'] ? DateTime.parse(app['metadata']['updated_at']).strftime('%Y-%m-%d %T %z') : nil),
          :name => app_summary['name'],
          :org => org['entity']['name'],
          :routes => format_routes(app_summary['routes']),
          :space => space['entity']['name'],
          :stack => stack['entity']['name'],
          :state => app['entity']['state']
      }


      additional_data = {}

      begin
        instance_stats = []
        if running
          instance_stats = formatted_instance_stats_for(app_summary['guid'], app_summary['name'])
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

  def format_routes(routes)
    routes.map do |route|
      host = route['host']
      path = route['path']

      domain = route['domain']['name']

      "#{host}.#{domain}#{path}"
    end
  end

  def formatted_instance_stats_for(guid, name)
    @logger.info "making stats request for #{name}"
    instances = @cf_service.json_response("/v2/apps/#{guid}/stats")
    raise "Unable to retrieve app instance stats: '#{instances['error_code']}'" if instances['error_code']
    instances.map {|_, value| value}
  end


end