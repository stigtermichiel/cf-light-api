require 'rufus-scheduler'
require_relative './worker.rb'
require 'logger'

class Scheduler
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime} [cf_light_api:worker]: #{msg}\n"
    end
    @scheduler = Rufus::Scheduler.new
    @update_interval = set_update_interval
    @update_timeout = set_update_timeout
    @cf_light_api_worker = CFLightAPIWorker.new((Redis.new :url => ENV['REDIS_URI']), @logger)
  end

  def set_schedule
    @scheduler.every @update_interval, :first_in => '5s', :overlap => false, :timeout => @update_timeout do
      @cf_light_api_worker.update_cf_data
    end
  end

  def set_update_timeout
    update_timeout = (ENV['UPDATE_TIMEOUT'] || '5m').to_s
    @logger.info "Update timeout:  '#{@update_timeout}'"
    update_timeout
  end

  def set_update_interval
    update_interval = (ENV['UPDATE_INTERVAL'] || '5m').to_s # If you change the default '5m' here, also remember to change the default age validity in sinatra/cf_light_api.rb:31
    @logger.info "Update interval: '#{@update_interval}'"
    update_interval
  end
end