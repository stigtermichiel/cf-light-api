require 'rspec'
require_relative '../lib/cf_light_api/apps_formatter_v2'
require_relative 'test_data'

describe AppsFormatterV2 do

  apps = TestData.apps

  let(:cf_service) {double("cf_service")}
  let(:apps_formatter) {AppsFormatterV2.new(apps, Logger.new(STDOUT), cf_service, nil)}
  let(:app_summary) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/app_summary.json')))}
  let(:app_stats) {JSON.parse(IO.read(File.join(Dir.getwd, '/spec/api_mock_responses/app_stats.json')))}

  before do
    allow(cf_service).to receive(:get_data_for).with("/v2/stacks?results-per-page=100").and_return(TestData.stacks)
    allow(cf_service).to receive(:get_data_for).with("/v2/spaces?results-per-page=100").and_return(TestData.spaces)
    allow(cf_service).to receive(:get_data_for).with("/v2/organizations?results-per-page=100").and_return(TestData.orgs)
    allow(cf_service).to receive(:json_response).with("/v2/apps/app-guid/summary").and_return(app_summary)
    allow(cf_service).to receive(:json_response).with("/v2/apps/app-guid/stats").and_return(app_stats)
    @time = Time.new
    allow(Time).to receive(:now).and_return(@time)
  end

  it 'format the apps response' do
    expected = [{:buildpack => app_summary['buildpack'], :data_from => @time.to_i, :diego => app_summary['diego'], :docker => !app_summary['docker'].nil?,
                 :docker_image => app_summary['docker'], :guid => app_summary['guid'], :last_uploaded => "2016-06-08 16:41:45 +0000",
                 :name => app_summary['name'], :org => "the-system_domain-org-name", :routes => ["host.domain.io"], :space => "name-2050",
                 :stack => "cflinuxfs2", :state => "STOPPED", :running => true, :instances => [
            app_stats["0"]
        ], :error => nil}]
    expect(apps_formatter.format).to eq expected
  end

  it 'format the apps response when app is not running' do
    app_summary['state'] = "STOPPED"
    expected = [{:buildpack => app_summary['buildpack'], :data_from => @time.to_i, :diego => app_summary['diego'], :docker => !app_summary['docker'].nil?,
                 :docker_image => app_summary['docker'], :guid => app_summary['guid'], :last_uploaded => "2016-06-08 16:41:45 +0000",
                 :name => app_summary['name'], :org => "the-system_domain-org-name", :routes => ["host.domain.io"], :space => "name-2050",
                 :stack => "cflinuxfs2", :state => "STOPPED", :running => false, :instances => [], :error => nil}]

    expect(apps_formatter.format).to eq expected
  end
end