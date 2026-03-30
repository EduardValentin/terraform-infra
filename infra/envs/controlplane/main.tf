locals {
  github_repository_environment_records = flatten([
    for repository, environments in var.github_repository_environments : [
      for environment in environments : {
        key         = "${repository}:${environment}"
        repository  = repository
        environment = environment
      }
    ]
  ])

  github_repository_variable_records = flatten([
    for repository, variables in var.github_repository_variables : [
      for variable_name, value in variables : {
        key           = "${repository}:${variable_name}"
        repository    = repository
        variable_name = variable_name
        value         = value
      }
    ]
  ])

  github_environment_variable_records = flatten([
    for repository, environments in var.github_environment_variables : [
      for environment, variables in environments : [
        for variable_name, value in variables : {
          key           = "${repository}:${environment}:${variable_name}"
          repository    = repository
          environment   = environment
          variable_name = variable_name
          value         = value
        }
      ]
    ]
  ])

  github_repository_secret_records = flatten([
    for repository, secrets in nonsensitive(var.github_repository_secrets) : [
      for secret_name, value in secrets : {
        key         = "${repository}:${secret_name}"
        repository  = repository
        secret_name = secret_name
        value       = value
      }
    ]
  ])

  github_environment_secret_records = flatten([
    for repository, environments in nonsensitive(var.github_environment_secrets) : [
      for environment, secrets in environments : [
        for secret_name, value in secrets : {
          key         = "${repository}:${environment}:${secret_name}"
          repository  = repository
          environment = environment
          secret_name = secret_name
          value       = value
        }
      ]
    ]
  ])

  tailscale_ci_ssh_destinations = distinct([
    for destination in concat(var.tailscale_ci_app_destinations, var.tailscale_ci_secrets_destinations) :
    replace(destination, ":22", "")
  ])

  tailscale_policy = {
    tagOwners = {
      "tag:prod"                          = [var.tailscale_admin_group]
      "tag:test"                          = [var.tailscale_admin_group]
      "tag:ops"                           = [var.tailscale_admin_group]
      "${var.tailscale_opencl_agent_tag}" = distinct(concat([var.tailscale_admin_group], var.tailscale_opencl_agent_tag_owners))
      "tag:ci-app-deploy"                    = [var.tailscale_admin_group]
      "tag:ci-secrets"                    = [var.tailscale_admin_group]
      "tag:ci-terraform"                  = [var.tailscale_admin_group]
    }
    acls = concat(
      [
        {
          action = "accept"
          src    = var.tailscale_ci_terraform_sources
          dst    = var.tailscale_ci_terraform_destinations
        },
        {
          action = "accept"
          src    = var.tailscale_ci_secrets_sources
          dst    = var.tailscale_ci_secrets_destinations
        },
        {
          action = "accept"
          src    = var.tailscale_ci_app_sources
          dst    = var.tailscale_ci_app_destinations
        },
        {
          action = "accept"
          src    = ["tag:ops"]
          dst = [
            "tag:test:443",
            "tag:test:8080",
            "tag:test:9100",
            "tag:prod:443",
            "tag:prod:8080",
            "tag:prod:9100"
          ]
        },
        {
          action = "accept"
          src = [
            "tag:test",
            "tag:prod"
          ]
          dst = [
            "tag:ops:3100",
            "tag:ops:4317",
            "tag:ops:4318"
          ]
        }
      ],
      length(var.tailscale_regular_member_sources) > 0 ? [
        {
          action = "accept"
          src    = var.tailscale_regular_member_sources
          dst    = var.tailscale_regular_member_destinations
        }
      ] : [],
      length(var.tailscale_opencl_account_sources) > 0 ? [
        {
          action = "accept"
          src    = var.tailscale_opencl_account_sources
          dst    = var.tailscale_opencl_account_destinations
        }
      ] : [],
      length(var.tailscale_opencl_agent_sources) > 0 ? [
        {
          action = "accept"
          src    = var.tailscale_opencl_agent_sources
          dst    = var.tailscale_opencl_agent_destinations
        }
      ] : [],
      length(var.tailscale_opencl_admin_sources) > 0 ? [
        {
          action = "accept"
          src    = var.tailscale_opencl_admin_sources
          dst    = var.tailscale_opencl_admin_destinations
        }
      ] : [],
      [
        {
          action = "accept"
          src    = [var.tailscale_admin_group]
          dst    = var.tailscale_admin_destinations
        }
      ]
    )
    ssh = [
      {
        action = "accept"
        src    = [var.tailscale_admin_group]
        dst    = var.tailscale_ssh_destinations
        users  = var.tailscale_ssh_users
      },
      {
        action = "accept"
        src    = var.tailscale_ci_app_sources
        dst    = local.tailscale_ci_ssh_destinations
        users  = ["root"]
      },
      {
        action = "accept"
        src    = var.tailscale_ci_secrets_sources
        dst    = local.tailscale_ci_ssh_destinations
        users  = ["root"]
      }
    ]
  }

  tailscale_policy_json = jsonencode(local.tailscale_policy)

  generated_test_hostname = "${var.bootstrap_hostname_test}.${var.tailnet_name}"

  generated_ops_test_hosts = length(var.ops_test_hosts) > 0 ? var.ops_test_hosts : [local.generated_test_hostname]
  generated_ops_prod_hosts = var.ops_prod_hosts

  generated_app_domains = {
    for app_name in sort(tolist(var.app_names)) : app_name => {
      test_hostname  = "${app_name}-test.${var.tailnet_name}"
      test_base_path = "/${app_name}"
      prod_hostnames = length(lookup(var.app_brand_domains, app_name, [])) > 0 ? lookup(var.app_brand_domains, app_name, []) : ["${app_name}.${var.placeholder_prod_domain}"]
    }
  }

  bootstrap_test_tailscale_auth_key      = var.bootstrap_tailscale_auth_key_test != "" ? nonsensitive(var.bootstrap_tailscale_auth_key_test) : "tskey-replace"
  bootstrap_ops_tailscale_auth_key       = var.bootstrap_tailscale_auth_key_ops != "" ? nonsensitive(var.bootstrap_tailscale_auth_key_ops) : "tskey-replace"
  bootstrap_prod_tailscale_auth_key      = var.bootstrap_tailscale_auth_key_prod != "" ? nonsensitive(var.bootstrap_tailscale_auth_key_prod) : "tskey-replace"
  bootstrap_ops_grafana_password         = var.ops_grafana_admin_password != "" ? nonsensitive(var.ops_grafana_admin_password) : "replace-with-strong-password"
  bootstrap_ops_terraform_backend_secret = var.ops_terraform_backend_secret_key != "" ? nonsensitive(var.ops_terraform_backend_secret_key) : "replace-with-strong-secret"

  bootstrap_test_env_content = templatefile("../../templates/bootstrap-test.env.tftpl", {
    hostname_override  = var.bootstrap_hostname_test
    tailscale_auth_key = local.bootstrap_test_tailscale_auth_key
    tailscale_tags     = var.bootstrap_tailscale_tags_test
    app_name           = var.bootstrap_template_app_name
    ops_loki_url       = "http://${var.ops_loki_host}:3100/loki/api/v1/push"
  })

  bootstrap_ops_env_content = templatefile("../../templates/bootstrap-ops.env.tftpl", {
    hostname_override            = var.bootstrap_hostname_ops
    tailscale_auth_key           = local.bootstrap_ops_tailscale_auth_key
    tailscale_tags               = var.bootstrap_tailscale_tags_ops
    app_name                     = var.bootstrap_template_app_name
    test_hosts                   = join(",", local.generated_ops_test_hosts)
    prod_hosts                   = join(",", local.generated_ops_prod_hosts)
    low_resource_mode            = var.ops_low_resource_mode ? "true" : "false"
    grafana_admin_password       = local.bootstrap_ops_grafana_password
    terraform_backend_enabled    = var.ops_terraform_backend_enabled ? "true" : "false"
    terraform_backend_bucket     = var.ops_terraform_backend_bucket
    terraform_backend_bind_ip    = var.ops_terraform_backend_bind_ip
    terraform_backend_port       = tostring(var.ops_terraform_backend_port)
    terraform_backend_access_key = var.ops_terraform_backend_access_key
    terraform_backend_secret_key = local.bootstrap_ops_terraform_backend_secret
  })

  bootstrap_prod_env_content = templatefile("../../templates/bootstrap-prod.env.tftpl", {
    hostname_override                   = var.bootstrap_hostname_prod
    tailscale_auth_key                  = local.bootstrap_prod_tailscale_auth_key
    tailscale_tags                      = var.bootstrap_tailscale_tags_prod
    app_name                            = var.bootstrap_template_app_name
    ops_loki_url                        = "http://${var.ops_loki_host}:3100/loki/api/v1/push"
    prod_pg_backup_enabled              = var.prod_pg_backup_enabled ? "true" : "false"
    prod_pg_backup_oncalendar           = var.prod_pg_backup_oncalendar
    prod_pg_backup_local_dir            = var.prod_pg_backup_local_dir
    prod_pg_backup_local_retention_days = tostring(var.prod_pg_backup_local_retention_days)
    prod_pg_backup_nas_dir              = var.prod_pg_backup_nas_dir
    prod_pg_backup_nas_retention_days   = tostring(var.prod_pg_backup_nas_retention_days)
  })
}

resource "github_repository_environment" "managed" {
  for_each = var.enable_github ? { for record in local.github_repository_environment_records : record.key => record } : {}

  repository  = each.value.repository
  environment = each.value.environment
}

resource "github_actions_variable" "repository" {
  for_each = var.enable_github ? { for record in local.github_repository_variable_records : record.key => record } : {}

  repository    = each.value.repository
  variable_name = each.value.variable_name
  value         = each.value.value
}

resource "github_actions_environment_variable" "environment" {
  for_each = var.enable_github ? { for record in local.github_environment_variable_records : record.key => record } : {}

  repository    = each.value.repository
  environment   = each.value.environment
  variable_name = each.value.variable_name
  value         = each.value.value

  depends_on = [github_repository_environment.managed]
}

resource "github_actions_secret" "repository" {
  for_each = var.enable_github ? { for record in local.github_repository_secret_records : record.key => record } : {}

  repository      = each.value.repository
  secret_name     = each.value.secret_name
  plaintext_value = each.value.value
}

resource "github_actions_environment_secret" "environment" {
  for_each = var.enable_github ? { for record in local.github_environment_secret_records : record.key => record } : {}

  repository      = each.value.repository
  environment     = each.value.environment
  secret_name     = each.value.secret_name
  plaintext_value = each.value.value

  depends_on = [github_repository_environment.managed]
}

resource "tailscale_acl" "policy" {
  count = var.enable_tailscale_policy ? 1 : 0

  acl = local.tailscale_policy_json
}
