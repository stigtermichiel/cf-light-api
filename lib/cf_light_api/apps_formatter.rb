class AppsFormatter
  def initialize(apps, spaces, orgs, stacks, domains, client, logger)
    @apps = apps
    @spaces = spaces
    @orgs = orgs
    @stacks = stacks
    @domains = domains
    @client = client
    @logger = logger
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

  def format_routes_for_app(app)
    routes = cf_rest(app['entity']['routes_url'], @client)
    routes.collect do |route|
      host = route['entity']['host']
      path = route['entity']['path']

      domain = @domains.find {|a_domain| a_domain['metadata']['guid'] == route['entity']['domain_guid']}
      domain = domain['entity']['name']

      "#{host}.#{domain}#{path}"
    end
  end

  def formatted_instance_stats_for(app)
    instances = cf_rest("/v2/apps/#{app['metadata']['guid']}/stats", @client)[0]
    raise "Unable to retrieve app instance stats: '#{instances['error_code']}'" if instances['error_code']
    instances.map {|_, value| value}
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

end