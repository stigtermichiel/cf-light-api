require 'rspec'
require_relative '../lib/cf_light_api/apps_formatter'
require_relative 'test_data'

describe AppsFormatter do

  apps = TestData.apps
  spaces = TestData.spaces
  orgs = TestData.orgs
  stacks = TestData.stacks
  domains = TestData.domains
  route = TestData.route

  let(:cf_service) {double("cf_service")}
  let(:apps_formatter) {AppsFormatter.new(apps, spaces, orgs, stacks, domains, Logger.new(STDOUT), cf_service, nil)}

  it 'format the apps response' do
    expected = [{:buildpack => nil, :data_from => 1509110965, :diego => false, :docker => false, :docker_image => nil, :guid => "app-guid", :last_uploaded => "2016-06-08 16:41:45 +0000", :name => "name-2443", :org => "the-system_domain-org-name", :routes => ["de-netmon-es.customer-app-domain1.com"], :space => "name-2050", :stack => "cflinuxfs2", :state => "STOPPED", :running => false, :instances => [], :error => nil}]
    allow(Time).to receive(:now).and_return(1509110965)
    expect(cf_service).to receive(:get_data_for).with("/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622" + '/routes').and_return(route)
    expect(apps_formatter.format).to eq expected
  end
end