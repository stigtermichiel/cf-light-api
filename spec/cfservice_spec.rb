require 'spec_helper'
require_relative '../lib/cf_light_api/worker'
require 'mock_redis'
require 'redis'
require 'json'

describe CfService do

  let(:apps_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/apps.json')))}
  let(:apps_response_with_next_url) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/apps_response_with_next_url.json')))}
  let(:next_url_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/next_url_response.json')))}
  let(:client) {double('client')}
  let(:cf_service) {CfService.new(client, Logger.new(STDOUT))}

  it 'Collects data from cf for a response without pagination' do
    allow(cf_service).to receive(:json_response).with('/v2/apps?results-per-page=100', 'GET').and_return(apps_response)
    app_data = cf_service.get_data_for('/v2/apps?results-per-page=100', 'GET')
    expect(app_data.to_json).to eq(exp)
  end

  it 'Collects data from cf for a response with pagination' do
    allow(cf_service).to receive(:json_response).with('/v2/apps?results-per-page=100', 'GET').and_return(apps_response_with_next_url)
    allow(cf_service).to receive(:json_response).with('/v2/apps?order-direction=asc&page=2&results-per-page=100', 'GET').and_return(next_url_response)
    expected = "[{\"metadata\":{\"guid\":\"app-guid\"},\"entity\":{\"name\":\"app1\"}},{\"metadata\":{\"guid\":\"app-guid2\"},\"entity\":{\"name\":\"app2\"}}]"
    app_data = cf_service.get_data_for('/v2/apps?results-per-page=100', 'GET')
    expect(app_data.to_json).to eq(expected)
  end

end

def exp
  [{:metadata =>
        {:guid => 'app-guid',
         :url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622',
         :created_at => '2016-06-08T16:41:45Z',
         :updated_at => '2016-06-08T16:41:45Z'},
    :entity =>
        {:name => 'name-2443',
         :production => false,
         :space_guid => 'space_guid',
         :stack_guid => 'stack_guid',
         :buildpack => nil,
         :detected_buildpack => nil,
         :detected_buildpack_guid => nil,
         :environment_json => nil,
         :memory => 1024,
         :instances => 1,
         :disk_quota => 1024,
         :state => 'STOPPED',
         :version => 'f5696e0f-087d-49b0-9ad7-4756c49a6ba6',
         :command => nil,
         :console => false,
         :debug => nil,
         :staging_task_id => nil,
         :package_state => 'PENDING',
         :health_check_type => 'port',
         :health_check_timeout => nil,
         :staging_failed_reason => nil,
         :staging_failed_description => nil,
         :diego => false,
         :docker_image => nil,
         :package_updated_at => '2016-06-08T16:41:45Z',
         :detected_start_command => '',
         :enable_ssh => true,
         :docker_credentials_json =>
             {:redacted_message => '[PRIVATE DATA HIDDEN]'},
         :ports => nil,
         :space_url => '/v2/spaces/9c5c8a91-a728-4608-9f5e-6c8026c3a2ac',
         :stack_url => '/v2/stacks/f6c960cc-98ba-4fd1-b197-ecbf39108aa2',
         :routes_url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/routes',
         :events_url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/events',
         :service_bindings_url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/service_bindings',
         :route_mappings_url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/route_mappings'}}].to_json
end
