class AppsFormatter
  def initialize(apps, spaces, orgs, stacks, domains, logger, cf_service)
    @apps = apps
    @spaces = spaces
    @orgs = orgs
    @stacks = stacks
    @domains = domains
    @logger = logger
    @cf_service = cf_service
  end

  def format_apps
    @apps.map do |app|
      # TODO: This is a bit repetative, could maybe improve?
      space = @spaces.find {|a_space| a_space['metadata']['guid'] == app['entity']['space_guid']}
      org = @orgs.find {|an_org| an_org['metadata']['guid'] == space['entity']['organization_guid']}
      stack = @stacks.find {|a_stack| a_stack['metadata']['guid'] == app['entity']['stack_guid']}
      routes = format_routes_for_app(app)

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
          instance_stats = formatted_instance_stats_for(app)
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

  def format_routes_for_app(app)
    routes = @cf_service.get_data_for(app['entity']['routes_url'])
    routes.collect do |route|
      host = route['entity']['host']
      path = route['entity']['path']

      domain = @domains.find {|a_domain| a_domain['metadata']['guid'] == route['entity']['domain_guid']}
      domain = domain['entity']['name']

      "#{host}.#{domain}#{path}"
    end
  end

  def formatted_instance_stats_for(app)
    instances = @cf_service.get_data_for("/v2/apps/#{app['metadata']['guid']}/stats")[0]
    raise "Unable to retrieve app instance stats: '#{instances['error_code']}'" if instances['error_code']
    instances.map {|_, value| value}
  end
end