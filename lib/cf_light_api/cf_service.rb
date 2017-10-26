class CfService

  def initialize(client, logger)
    @client = client
    @logger = logger
  end

  def get_data_for(path, method='GET')
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
    resources << get_data_for(response['next_url'], method) unless response['next_url'] == nil
    resources.flatten
  end

  def json_response(path, method='GET')
    JSON.parse(@client.base.rest_client.request(method, path)[1][:body])
  end

  def self.get_client(cf_api=ENV['CF_API'], cf_user=ENV['CF_USER'], cf_password=ENV['CF_PASSWORD'])
    client = CFoundry::Client.get(cf_api)
    client.login({:username => cf_user, :password => cf_password})
    client
  end
end