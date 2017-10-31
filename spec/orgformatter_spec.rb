require 'rspec'
require_relative '../lib/cf_light_api/org_formatter'
require_relative 'test_data'

describe OrgFormatter do

  quotas = TestData.quotas
  orgs = TestData.orgs

  let(:cf_service) {double("cf_service")}
  let(:org_formatter) {OrgFormatter.new(orgs, quotas, nil, Logger.new(STDOUT))}

  it 'format the apps response' do
    expected = [{:guid => "org_guid", :name => "the-system_domain-org-name", :quota => {:total_services => 100, :total_routes => 1000, :memory_limit => 10737418240}}]
    expect(org_formatter.format).to eq expected
  end
end