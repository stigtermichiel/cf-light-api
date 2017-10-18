class EnvChecker
  def initialize(logger)
    @logger = logger
    check_cf_env
    check_graphite_env
  end

  def check_graphite_env
    # If either of the Graphite settings are set, verify that they are both set, or exit with an error. CF_ENV_NAME is used
    # to prefix the Graphite key, to allow filtering by environment if you run more than one.
    if ENV['GRAPHITE_HOST'] or ENV['GRAPHITE_PORT']
      ['GRAPHITE_HOST', 'GRAPHITE_PORT', 'CF_ENV_NAME'].each do |env|
        unless ENV[env]
          @logger.info "Error: please set the '#{env}' environment variable to enable exporting to Graphite."
          exit 1
        end
      end
    end
    if ENV['GRAPHITE_HOST'] and ENV['GRAPHITE_PORT']
      @logger.info "Graphite server: #{ENV['GRAPHITE_HOST']}:#{ENV['GRAPHITE_PORT']}"
    else
      @logger.info 'Graphite server: Disabled'
    end
  end

  def check_cf_env
    ['CF_API', 'CF_USER', 'CF_PASSWORD'].each do |env|
      unless ENV[env]
        @logger.info "Error: please set the '#{env}' environment variable."
        exit 1
      end
    end
  end

  def check_redis_env
    ['REDIS_URI', 'REDIS_KEY_PREFIX'].each do |env|
      abort "[cf_light_api] Error: please set the '#{env}' environment variable." unless ENV[env]
    end

    @logger.info "[cf_light_api] Using Redis at '#{ENV['REDIS_URI']}' with key '#{ENV['REDIS_KEY_PREFIX']}'"
  end
end