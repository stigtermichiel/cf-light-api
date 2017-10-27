require_relative '../lib/sinatra/cf_light_api' # <-- your sinatra app
require 'spec_helper'
require 'mock_redis'


ENV['RACK_ENV'] = 'test'

describe 'CfLightApi' do
  include Rack::Test::Methods

  before do
    @fake_redis_server = MockRedis.new
  end

  def app
    CfLightAPI
  end

  it 'going to /v1/apps returns empty json when nothing in redis' do
    get '/v1/apps'
    puts last_response
    expect(last_response).to be_ok
    expect(last_response.body).to eq('[]')
  end

  it 'going to /v1/apps returns the right json when stuff in redis' do
    get '/v1/apps'
    puts last_response
    expect(last_response).to be_ok
    expect(last_response.body).to eq('[]')
  end
end