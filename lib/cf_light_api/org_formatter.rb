class OrgFormatter

  def initialize(orgs, quotas, graphite, logger)
    @orgs = orgs
    @quotas = quotas
    @graphite = graphite
    @logger = logger
  end

  def format
    @orgs.map do |org|
      quota = @quotas.find {|a_quota| a_quota['metadata']['guid'] == org['entity']['quota_definition_guid']}

      quota = {
          :total_services => quota['entity']['total_services'],
          :total_routes => quota['entity']['total_routes'],
          :memory_limit => quota['entity']['memory_limit'] * 1024 * 1024
      }

      send_org_quota_data_to_graphite(org['entity']['name'], quota) if @graphite

      {
          :guid => org['metadata']['guid'],
          :name => org['entity']['name'],
          :quota => quota
      }
    end
  end

  def send_org_quota_data_to_graphite(org_name, quota)
    graphite_base_key = "cf_orgs.#{ENV['CF_ENV_NAME']}.#{org_name}"
    @logger.info "  Exporting org quota statistics to Graphite, path '#{graphite_base_key}'"

    quota.keys.each do |key|
      @graphite.metrics "#{graphite_base_key}.quota.#{key}" => quota[key]
    end
  end


end