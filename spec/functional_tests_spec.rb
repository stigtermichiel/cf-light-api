require 'spec_helper'
require_relative '../lib/cf_light_api/worker'
require 'mock_redis'

describe CFLightAPIWorker do

  before do
    fake_lock
    # @worker = CFLightAPIWorker.new
    @fake_redis_server = MockRedis.new
    time_mock
  end

  # it 'updates cf data in Redis' do
  #   @worker.update_cf_data
  #   expect(@fake_redis_server.get("#{ENV['REDIS_KEY_PREFIX']}:orgs")).to eq '[{"guid":"org_guid","name":"the-system_domain-org-name","quota":{"total_services":100,"total_routes":1000,"memory_limit":10737418240}}]'
  #   expect(@fake_redis_server.get("#{ENV['REDIS_KEY_PREFIX']}:apps")).to eq "[{\"buildpack\":null,\"data_from\":#{@time.to_i},\"diego\":false,\"docker\":false,\"docker_image\":null,\"guid\":\"app-guid\",\"last_uploaded\":\"2016-06-08 16:41:45 +0000\",\"name\":\"name-2443\",\"org\":\"the-system_domain-org-name\",\"routes\":[\"de-netmon-es.customer-app-domain1.com\"],\"space\":\"name-2050\",\"stack\":\"cflinuxfs2\",\"state\":\"STOPPED\",\"running\":false,\"instances\":[],\"error\":null}]"
  #   expect(@fake_redis_server.get("#{ENV['REDIS_KEY_PREFIX']}:last_updated")).to eq "{\"last_updated\":\"#{@time.to_s}\"}"
  # end

  def time_mock
    @time = Time.new
    allow(Time).to receive(:now).and_return(@time)
  end

  def fake_lock
    @fake_lock_manager = double("LockManager")
    allow(@fake_lock_manager).to receive(:lock).with("cf_light_api_live:lock", 300000).and_return(true)
    allow(@fake_lock_manager).to receive(:unlock).and_return("Doesn't matter")
  end

end