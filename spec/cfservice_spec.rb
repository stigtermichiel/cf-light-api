require 'spec_helper'
require_relative '../lib/cf_light_api/worker'
require 'mock_redis'
require 'redis'
require 'json'
require 'test_data'

describe CfService do

  let(:apps_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/apps.json')))}
  let(:apps_response_with_next_url) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/apps_response_with_next_url.json')))}
  let(:next_url_response) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/next_url_response.json')))}
  let(:client) {double('client')}
  let(:cf_service) {CfService.new(client, Logger.new(STDOUT))}


  it 'Collects data from cf for a response without pagination' do
    allow(cf_service).to receive(:json_response).with('/v2/apps?results-per-page=100', 'GET').and_return(apps_response)
    app_data = cf_service.get_data_for('/v2/apps?results-per-page=100', 'GET')
    expect(app_data.to_json.to_s).to eq(TestData.app_data.to_s)
  end

  it 'Collects data from cf for a response with pagination' do
    allow(cf_service).to receive(:json_response).with('/v2/apps?results-per-page=100', 'GET').and_return(apps_response_with_next_url)
    allow(cf_service).to receive(:json_response).with('/v2/apps?order-direction=asc&page=2&results-per-page=100', 'GET').and_return(next_url_response)
    expected = "[{\"metadata\":{\"guid\":\"app-guid\"},\"entity\":{\"name\":\"app1\"}},{\"metadata\":{\"guid\":\"app-guid2\"},\"entity\":{\"name\":\"app2\"}}]"
    app_data = cf_service.get_data_for('/v2/apps?results-per-page=100', 'GET')
    expect(app_data.to_json).to eq(expected)
  end

end
