require 'rufus-scheduler'

class Scheduler

  def initialize(proc, logger)
    @logger = logger
    @scheduler = Rufus::Scheduler.new
    @scheduler.every set_update_interval, :first_in => '5s', :overlap => false, :timeout => set_update_timeout do
      begin
      proc.call
      rescue Rufus::Scheduler::TimeoutError
        @logger.info 'Data update took too long and was aborted, waiting for the lock to expire before trying again...'
        # @cf_client.logout
      end

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