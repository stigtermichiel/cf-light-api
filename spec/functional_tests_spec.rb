require 'spec_helper'
require_relative '../lib/cf_light_api/worker'
require 'mock_redis'
require 'redis'


describe CFLightAPIWorker do

  let(:apps_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/apps.json')))}
  let(:orgs_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/orgs.json')))}
  let(:quotas_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/quotas.json')))}
  let(:spaces_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/spaces.json')))}
  let(:stacks_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/stacks.json')))}
  let(:domains_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/domains.json')))}
  let(:app_routes_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/app_routes_response.json')))}

  before do
    @fake_redis_server = MockRedis.new
    time_mock
    fake_lock
    @worker = CFLightAPIWorker.new(@fake_redis_server)
    cf_client_mocks
    api_mocks
  end

  it 'updates cf data in Redis' do
    @worker.update_cf_data
    expect(@fake_redis_server.get("#{ENV['REDIS_KEY_PREFIX']}:orgs")).to eq '[{"guid":"org_guid","name":"the-system_domain-org-name","quota":{"total_services":100,"total_routes":1000,"memory_limit":10737418240}}]'
    expect(@fake_redis_server.get("#{ENV['REDIS_KEY_PREFIX']}:apps")).to eq "[{\"buildpack\":null,\"data_from\":#{@time.to_i},\"diego\":false,\"docker\":false,\"docker_image\":null,\"guid\":\"app-guid\",\"last_uploaded\":\"2016-06-08 16:41:45 +0000\",\"name\":\"name-2443\",\"org\":\"the-system_domain-org-name\",\"routes\":[\"de-netmon-es.customer-app-domain1.com\"],\"space\":\"name-2050\",\"stack\":\"cflinuxfs2\",\"state\":\"STOPPED\",\"running\":false,\"instances\":[],\"error\":null}]"
    expect(@fake_redis_server.get("#{ENV['REDIS_KEY_PREFIX']}:last_updated")).to eq "{\"last_updated\":\"#{@time.to_s}\"}"
  end

  def time_mock
    @time = Time.new
    allow(Time).to receive(:now).and_return(@time)
  end

  def fake_lock
    @fake_lock_manager = double('LockManager')
    expect(Redlock::Client).to receive(:new).and_return(@fake_lock_manager)
    expect(@fake_lock_manager).to receive(:lock).with('cf_light_api_live:lock', 300000).and_return(true)
    expect(@fake_lock_manager).to receive(:unlock).and_return("Doesn't matter")
  end

  def api_mocks

    allow(@worker).to receive(:json_response).with('/v2/apps?results-per-page=100', @client, "GET").and_return(apps_response)
    allow(@worker).to receive(:json_response).with('/v2/organizations?results-per-page=100', @client, "GET").and_return(orgs_response)
    allow(@worker).to receive(:json_response).with('/v2/quota_definitions?results-per-page=100', @client, "GET").and_return(quotas_response)
    allow(@worker).to receive(:json_response).with('/v2/spaces?results-per-page=100', @client, "GET").and_return(spaces_response)
    allow(@worker).to receive(:json_response).with('/v2/stacks?results-per-page=100', @client, "GET").and_return(stacks_response)
    allow(@worker).to receive(:json_response).with('/v2/domains?results-per-page=100', @client, "GET").and_return(domains_response)
    allow_any_instance_of(AppsFormatter).to receive(:json_response).with('/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/routes', @client, "GET").and_return(app_routes_response)
  end

  def cf_client_mocks
    @client = double("cf_client")
    allow(@worker).to receive(:get_client).and_return(@client)
    allow(@client).to receive(:logout).and_return("asf")
  end


end