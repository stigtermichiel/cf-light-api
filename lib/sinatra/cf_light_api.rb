require 'json'
require 'sinatra/base'
require 'redis'

if ENV['NEW_RELIC_LICENSE_KEY']
  require 'newrelic_rpm'
  NewRelic::Agent.manual_start
end

class CfLightAPI < Sinatra::Base
  set :port => ENV['PORT'] ? ENV['PORT'] : 1245

  redis = Redis.new(:uri => ENV['REDIS_URI'])

  get '/v1/apps/?:org?' do
    content_type :json
    redis_val = redis.get("#{ENV['REDIS_KEY_PREFIX']}:apps")
    all_apps = redis_val ? JSON.parse(redis_val) : []

    if params[:org]
      all_apps.select {|an_app| an_app['org'] == params[:org]}.to_json
    else
      all_apps.to_json
    end
  end

  get '/v1/orgs/?:guid?' do
    content_type :json
    all_orgs = JSON.parse(redis.get("#{ENV['REDIS_KEY_PREFIX']}:orgs"))

    if params[:guid]
      all_orgs.select {|an_org| an_org['guid'] == params[:guid]}.to_json
    else
      all_orgs.to_json
    end
  end

  get '/v1/last_updated' do
    content_type :json
    updated_json = redis.get("#{ENV['REDIS_KEY_PREFIX']}:last_updated")

    last_updated = DateTime.parse JSON.parse(updated_json)["last_updated"]
    seconds_since_update = ((DateTime.now - last_updated) * 24 * 60 * 60).to_i

    status 503 if seconds_since_update >= (ENV['DATA_AGE_VALIDITY'] || '600'.to_i)
    updated_json
  end

end



