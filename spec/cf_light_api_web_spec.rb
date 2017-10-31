ENV['RACK_ENV'] = 'test'

require_relative '../lib/sinatra/cf_light_api' # <-- your sinatra app
require 'spec_helper'
require 'mock_redis'



describe 'CfLightApi' do
  include Rack::Test::Methods

  before do
    @fake_redis_server = MockRedis.new
    @app_data = [{:buildpack => nil, :data_from => 1509110965, :diego => false, :docker => false, :docker_image => nil, :guid => "app-guid", :last_uploaded => "2016-06-08 16:41:45 +0000", :name => "name-2443", :org => "the-system_domain-org-name", :routes => ["de-netmon-es.customer-app-domain1.com"], :space => "name-2050", :stack => "cflinuxfs2", :state => "STOPPED", :running => false, :instances => [], :error => nil}]
    @org_data = [{:guid => "org_guid", :name => "the-system_domain-org-name", :quota => {:total_services => 100, :total_routes => 1000, :memory_limit => 10737418240}}]
  end

  def app
    CfLightAPI.set :redis, @fake_redis_server
  end

  it 'going to /v1/apps returns empty json when nothing in redis' do
    get '/v1/apps'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('[]')
  end

  it 'going to /v1/apps returns the right json when stuff in redis' do
    @fake_redis_server.set("#{ENV['REDIS_KEY_PREFIX']}:apps", @app_data.to_json)
    get '/v1/apps'
    expect(last_response).to be_ok
    expect(last_response.body.size).to eq(362)
  end

  it 'going to /v1/apps/org returns the right json' do
    @fake_redis_server.set("#{ENV['REDIS_KEY_PREFIX']}:apps", @app_data.to_json)
    get '/v1/apps/the-system_domain-org-name'
    expect(last_response).to be_ok
    expect(last_response.body.size).to eq(362)
  end

  it 'going to /v1/apps/org with an org that does not exit returns empty json' do
    @fake_redis_server.set("#{ENV['REDIS_KEY_PREFIX']}:apps", @app_data.to_json)
    get '/v1/apps/non-existing-org'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('[]')
  end

  it 'going to /v1/orgs returns empty json when nothing in redis' do
    get '/v1/orgs'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('[]')
  end

  it 'going to /v1/orgs returns the right json when stuff in redis' do
    @fake_redis_server.set("#{ENV['REDIS_KEY_PREFIX']}:orgs", @org_data.to_json)
    get '/v1/orgs'
    expect(last_response).to be_ok
    expect(last_response.body.size).to eq(135)
  end

  it 'going to /v1/orgs/org returns the right json' do
    @fake_redis_server.set("#{ENV['REDIS_KEY_PREFIX']}:orgs", @org_data.to_json)
    get '/v1/orgs/org_guid'
    expect(last_response).to be_ok
    expect(last_response.body.size).to eq(135)
  end

  it 'going to /v1/orgs/org with an org that does not exit returns empty json' do
    @fake_redis_server.set("#{ENV['REDIS_KEY_PREFIX']}:orgs", @app_data.to_json)
    get '/v1/orgs/non-existing-org'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('[]')
  end
end