require 'cfoundry'
require 'json'
require 'redlock'
require 'logger'
require 'graphite-api'
require 'date'
require 'redis'
require_relative 'environment_checker'
require_relative 'org_formatter'
require_relative 'apps_formatter'
require_relative 'cf_service'

class CFLightAPIWorker
  if ENV['NEW_RELIC_LICENSE_KEY']
    require 'newrelic_rpm'
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    include NewRelic::Agent::MethodTracer
  end

  def initialize(redis, graphite, lock, logger)
    @redis = redis
    @lock_manager = lock
    @graphite = graphite
    @logger = logger
  end

  def update_cf_data(client)
    begin
      lock = @lock_manager.lock("#{ENV['REDIS_KEY_PREFIX']}:lock", 5*60*1000)
      if lock
        start_time = Time.now

        @logger.info 'Updating data...'
        cf_service = CfService.new(client, @logger)

        apps = cf_service.get_data_for('/v2/apps?results-per-page=100')
        orgs = cf_service.get_data_for('/v2/organizations?results-per-page=100')
        quotas = cf_service.get_data_for('/v2/quota_definitions?results-per-page=100')
        spaces = cf_service.get_data_for('/v2/spaces?results-per-page=100')
        stacks = cf_service.get_data_for('/v2/stacks?results-per-page=100')
        domains = cf_service.get_data_for('/v2/domains?results-per-page=100')

        put_in_redis "#{ENV['REDIS_KEY_PREFIX']}:orgs", OrgFormatter.new(orgs, quotas, @graphite, @logger).format
        put_in_redis "#{ENV['REDIS_KEY_PREFIX']}:apps", AppsFormatter.new(apps, spaces, orgs, stacks, domains, @logger, cf_service, @graphite).format
        put_in_redis "#{ENV['REDIS_KEY_PREFIX']}:last_updated", {:last_updated => Time.now}

        @logger.info "Update completed in #{format_duration(Time.now.to_f - start_time.to_f)}..."
        @lock_manager.unlock(lock)
        client.logout
      else
        @logger.info 'Update already running in another instance!'
      end
    rescue StandardError => e
      @logger.info "Unknown exception happened, #{e}"
      @lock_manager.unlock(lock)
    end
  end

  def put_in_redis(key, data)
    @redis.set key, data.to_json
  end

  def format_duration(elapsed_seconds)
    seconds = elapsed_seconds % 60
    minutes = (elapsed_seconds / 60) % 60
    hours = elapsed_seconds / (60 * 60)
    format('%02d hrs, %02d mins, %02d secs', hours, minutes, seconds)
  end

  if ENV['NEW_RELIC_LICENSE_KEY']
    add_transaction_tracer :update_cf_data, category: :task
    add_method_tracer :update_cf_data
  end

end
