class TestData

  def self.apps
    [{"metadata" => {"guid" => "app-guid", "url" => "/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622", "created_at" => "2016-06-08T16:41:45Z", "updated_at" => "2016-06-08T16:41:45Z"}, "entity" => {"name" => "name-2443", "production" => false, "space_guid" => "space_guid", "stack_guid" => "stack_guid", "buildpack" => nil, "detected_buildpack" => nil, "detected_buildpack_guid" => nil, "environment_json" => nil, "memory" => 1024, "instances" => 1, "disk_quota" => 1024, "state" => "STOPPED", "version" => "f5696e0f-087d-49b0-9ad7-4756c49a6ba6", "command" => nil, "console" => false, "debug" => nil, "staging_task_id" => nil, "package_state" => "PENDING", "health_check_type" => "port", "health_check_timeout" => nil, "staging_failed_reason" => nil, "staging_failed_description" => nil, "diego" => false, "docker_image" => nil, "package_updated_at" => "2016-06-08T16:41:45Z", "detected_start_command" => "", "enable_ssh" => true, "docker_credentials_json" => {"redacted_message" => "[PRIVATE DATA HIDDEN]"}, "ports" => nil, "space_url" => "/v2/spaces/9c5c8a91-a728-4608-9f5e-6c8026c3a2ac", "stack_url" => "/v2/stacks/f6c960cc-98ba-4fd1-b197-ecbf39108aa2", "routes_url" => "/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/routes", "events_url" => "/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/events", "service_bindings_url" => "/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/service_bindings", "route_mappings_url" => "/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/route_mappings"}}]
  end

  def self.orgs
    [{"metadata" => {"guid" => "org_guid", "url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20", "created_at" => "2016-06-08T16:41:33Z", "updated_at" => "2016-06-08T16:41:26Z"}, "entity" => {"name" => "the-system_domain-org-name", "billing_enabled" => false, "quota_definition_guid" => "quota_id", "status" => "active", "quota_definition_url" => "/v2/quota_definitions/dcb680a9-b190-4838-a3d2-b84aa17517a6", "spaces_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20/spaces", "domains_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20/domains", "private_domains_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20/private_domains", "users_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20/users", "managers_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20/managers", "billing_managers_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20/billing_managers", "auditors_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20/auditors", "app_events_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20/app_events", "space_quota_definitions_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20/space_quota_definitions"}}]
  end

  def self.quotas
    [{"metadata" => {"guid" => "quota_id", "url" => "/v2/quota_definitions/095a6b8c-31a7-4bc0-a11c-c6a829cfd74c", "created_at" => "2016-06-08T16:41:39Z", "updated_at" => "2016-06-08T16:41:26Z"}, "entity" => {"name" => "default", "non_basic_services_allowed" => true, "total_services" => 100, "total_routes" => 1000, "total_private_domains" => -1, "memory_limit" => 10240, "trial_db_allowed" => false, "instance_memory_limit" => -1, "app_instance_limit" => -1, "app_task_limit" => -1, "total_service_keys" => -1, "total_reserved_route_ports" => 0}}]
  end

  def self.spaces
    [{"metadata" => {"guid" => "space_guid", "url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4", "created_at" => "2016-06-08T16:41:40Z", "updated_at" => "2016-06-08T16:41:26Z"}, "entity" => {"name" => "name-2050", "organization_guid" => "org_guid", "space_quota_definition_guid" => nil, "allow_ssh" => true, "organization_url" => "/v2/organizations/d154425c-dccc-42e6-b6b4-27d46c3b42cb", "developers_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/developers", "managers_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/managers", "auditors_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/auditors", "apps_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/apps", "routes_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/routes", "domains_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/domains", "service_instances_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/service_instances", "app_events_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/app_events", "events_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/events", "security_groups_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/security_groups", "staging_security_groups_url" => "/v2/spaces/2e100106-0b74-4062-8671-0d375f951cb4/staging_security_groups"}}]
  end

  def self.stacks
    [{"metadata" => {"guid" => "stack_guid", "url" => "/v2/stacks/6d4efea3-c3ff-42ff-9f10-7e8f3f8662b7", "created_at" => "2016-06-08T16:41:21Z", "updated_at" => "2016-06-08T16:41:26Z"}, "entity" => {"name" => "cflinuxfs2", "description" => "cflinuxfs2"}}]
  end

  def self.domains
    [{"metadata" => {"guid" => "domain_guid", "url" => "/v2/shared_domains/fa1385de-55ba-41d3-beb2-f83919c634d6", "created_at" => "2016-06-08T16:41:33Z", "updated_at" => "2016-06-08T16:41:26Z"}, "entity" => {"name" => "customer-app-domain1.com", "router_group_guid" => nil, "router_group_type" => nil}}, {"metadata" => {"guid" => "ca13b618-afb1-4ba4-b322-63b226b05d53", "url" => "/v2/shared_domains/ca13b618-afb1-4ba4-b322-63b226b05d53", "created_at" => "2016-06-08T16:41:33Z", "updated_at" => "2016-06-08T16:41:26Z"}, "entity" => {"name" => "customer-app-domain2.com", "router_group_guid" => nil, "router_group_type" => nil}}, {"metadata" => {"guid" => "ef91529f-7659-424c-96ac-68c55decb7bf", "url" => "/v2/private_domains/ef91529f-7659-424c-96ac-68c55decb7bf", "created_at" => "2016-06-08T16:41:33Z", "updated_at" => "2016-06-08T16:41:26Z"}, "entity" => {"name" => "vcap.me", "owning_organization_guid" => "a7aff246-5f5b-4cf8-87d8-f316053e4a20", "owning_organization_url" => "/v2/organizations/a7aff246-5f5b-4cf8-87d8-f316053e4a20", "spaces_url" => "/v2/domains/ef91529f-7659-424c-96ac-68c55decb7bf/spaces"}}, {"metadata" => {"guid" => "493e1582-8b12-4fea-8a5f-b0d7171b146f", "url" => "/v2/shared_domains/493e1582-8b12-4fea-8a5f-b0d7171b146f", "created_at" => "2016-06-08T16:41:35Z", "updated_at" => "2016-06-08T16:41:26Z"}, "entity" => {"name" => "domain-33.example.com", "router_group_guid" => nil, "router_group_type" => nil}}]
  end

  def self.route
    [{"metadata" => {"guid" => "a3ae744d-97ba-4939-a2a1-8f195f284a8f", "url" => "/v2/routes/a3ae744d-97ba-4939-a2a1-8f195f284a8f", "created_at" => "2016-08-18T13:43:44Z", "updated_at" => nil}, "entity" => {"host" => "de-netmon-es", "path" => "", "domain_guid" => "domain_guid", "space_guid" => "b113f179-7952-46c6-bf52-65dd3a480d1a", "service_instance_guid" => nil, "port" => nil, "domain_url" => "/v2/shared_domains/1b245fdd-8199-47cb-8416-222e214ca559", "space_url" => "/v2/spaces/b113f179-7952-46c6-bf52-65dd3a480d1a", "apps_url" => "/v2/routes/a3ae744d-97ba-4939-a2a1-8f195f284a8f/apps", "route_mappings_url" => "/v2/routes/a3ae744d-97ba-4939-a2a1-8f195f284a8f/route_mappings"}}]
  end

  def self.app_data
    [{:metadata =>
          {:guid => 'app-guid',
           :url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622',
           :created_at => '2016-06-08T16:41:45Z',
           :updated_at => '2016-06-08T16:41:45Z'},
      :entity =>
          {:name => 'name-2443',
           :production => false,
           :space_guid => 'space_guid',
           :stack_guid => 'stack_guid',
           :buildpack => nil,
           :detected_buildpack => nil,
           :detected_buildpack_guid => nil,
           :environment_json => nil,
           :memory => 1024,
           :instances => 1,
           :disk_quota => 1024,
           :state => 'STOPPED',
           :version => 'f5696e0f-087d-49b0-9ad7-4756c49a6ba6',
           :command => nil,
           :console => false,
           :debug => nil,
           :staging_task_id => nil,
           :package_state => 'PENDING',
           :health_check_type => 'port',
           :health_check_timeout => nil,
           :staging_failed_reason => nil,
           :staging_failed_description => nil,
           :diego => false,
           :docker_image => nil,
           :package_updated_at => '2016-06-08T16:41:45Z',
           :detected_start_command => '',
           :enable_ssh => true,
           :docker_credentials_json =>
               {:redacted_message => '[PRIVATE DATA HIDDEN]'},
           :ports => nil,
           :space_url => '/v2/spaces/9c5c8a91-a728-4608-9f5e-6c8026c3a2ac',
           :stack_url => '/v2/stacks/f6c960cc-98ba-4fd1-b197-ecbf39108aa2',
           :routes_url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/routes',
           :events_url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/events',
           :service_bindings_url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/service_bindings',
           :route_mappings_url => '/v2/apps/6064d98a-95e6-400b-bc03-be65e6d59622/route_mappings'}}].to_json
  end

end