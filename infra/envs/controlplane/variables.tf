variable "enable_github" {
  type    = bool
  default = false
}

variable "github_owner" {
  type    = string
  default = ""

  validation {
    condition     = !var.enable_github || var.github_owner != ""
    error_message = "github_owner is required when enable_github=true."
  }
}

variable "github_token" {
  type      = string
  sensitive = true
  default   = ""

  validation {
    condition     = !var.enable_github || var.github_token != ""
    error_message = "github_token is required when enable_github=true."
  }
}

variable "github_repository_environments" {
  type = map(set(string))
  default = {
    "course-platform" = ["test", "production"]
  }
}

variable "github_repository_variables" {
  type = map(map(string))
  default = {
    "course-platform" = {
      TEST_APP_HOSTNAME  = "susanoo-test.longhair-eagle.ts.net"
      TEST_APP_BASE_PATH = "/courseplatform"
      PROD_APP_HOSTNAME  = "courseplatform.com"
      PROD_APP_BASE_PATH = "/"
    }
  }
}

variable "github_repository_secrets" {
  type      = map(map(string))
  sensitive = true
  default   = {}
}

variable "github_environment_variables" {
  type = map(map(map(string)))
  default = {
    "course-platform" = {
      "test" = {
        APP_ENV = "test"
      }
      "production" = {
        APP_ENV = "prod"
      }
    }
  }
}

variable "github_environment_secrets" {
  type      = map(map(map(string)))
  sensitive = true
  default   = {}
}

variable "enable_tailscale_policy" {
  type    = bool
  default = false
}

variable "tailscale_tailnet" {
  type    = string
  default = ""

  validation {
    condition     = !var.enable_tailscale_policy || var.tailscale_tailnet != ""
    error_message = "tailscale_tailnet is required when enable_tailscale_policy=true."
  }
}

variable "tailscale_oauth_client_id" {
  type      = string
  sensitive = true
  default   = ""

  validation {
    condition     = !var.enable_tailscale_policy || var.tailscale_oauth_client_id != ""
    error_message = "tailscale_oauth_client_id is required when enable_tailscale_policy=true."
  }
}

variable "tailscale_oauth_client_secret" {
  type      = string
  sensitive = true
  default   = ""

  validation {
    condition     = !var.enable_tailscale_policy || var.tailscale_oauth_client_secret != ""
    error_message = "tailscale_oauth_client_secret is required when enable_tailscale_policy=true."
  }
}

variable "tailscale_admin_group" {
  type    = string
  default = "group:admin"
}

variable "tailscale_ci_terraform_sources" {
  type    = list(string)
  default = ["tag:ci-terraform"]
}

variable "tailscale_ci_terraform_destinations" {
  type    = list(string)
  default = ["tag:ops:9000"]
}

variable "tailscale_ci_secrets_sources" {
  type    = list(string)
  default = ["tag:ci-secrets"]
}

variable "tailscale_ci_secrets_destinations" {
  type    = list(string)
  default = ["tag:test:22", "tag:prod:22"]
}

variable "tailscale_ci_app_sources" {
  type    = list(string)
  default = ["tag:ci-courseplatform"]
}

variable "tailscale_ci_app_destinations" {
  type    = list(string)
  default = ["tag:test:22", "tag:prod:22"]
}

variable "tailscale_admin_destinations" {
  type    = list(string)
  default = ["tag:prod:*", "tag:test:*", "tag:ops:*"]
}

variable "tailscale_opencl_agent_tag" {
  type    = string
  default = "tag:solus-agent"
}

variable "tailscale_opencl_agent_sources" {
  type    = list(string)
  default = ["tag:solus-agent"]
}

variable "tailscale_opencl_account_sources" {
  type    = list(string)
  default = ["solus.assistant@gmail.com"]
}

variable "tailscale_opencl_account_destinations" {
  type = list(string)
  default = [
    "tag:test:443",
    "tag:test:8080",
    "tag:test:9100",
    "tag:ops:3000",
    "tag:ops:9090",
    "tag:ops:3100",
    "tag:ops:3200",
    "tag:ops:4317",
    "tag:ops:4318",
    "tag:ops:18080",
    "tag:ops:19100"
  ]
}

variable "tailscale_opencl_agent_destinations" {
  type = list(string)
  default = [
    "tag:test:443",
    "tag:test:8080",
    "tag:test:9100",
    "tag:ops:3000",
    "tag:ops:9090",
    "tag:ops:3100",
    "tag:ops:3200",
    "tag:ops:4317",
    "tag:ops:4318",
    "tag:ops:18080",
    "tag:ops:19100"
  ]
}

variable "tailscale_opencl_admin_sources" {
  type    = list(string)
  default = ["eduard.valentin1996@gmail.com"]
}

variable "tailscale_opencl_admin_destinations" {
  type    = list(string)
  default = ["tag:solus-agent:*"]
}

variable "tailscale_regular_member_sources" {
  type    = list(string)
  default = []
}

variable "tailscale_regular_member_destinations" {
  type    = list(string)
  default = ["tag:prod:*", "tag:test:*", "tag:ops:*"]
}

variable "tailscale_ssh_destinations" {
  type    = list(string)
  default = ["tag:prod", "tag:test", "tag:ops"]
}

variable "tailscale_ssh_users" {
  type    = list(string)
  default = ["root", "ubuntu"]
}

variable "tailnet_name" {
  type    = string
  default = "longhair-eagle.ts.net"
}

variable "placeholder_prod_domain" {
  type    = string
  default = "courseplatform.com"
}

variable "app_names" {
  type    = set(string)
  default = ["courseplatform"]
}

variable "app_brand_domains" {
  type    = map(list(string))
  default = {}
}

variable "bootstrap_template_app_name" {
  type    = string
  default = "courseplatform"
}

variable "bootstrap_hostname_test" {
  type    = string
  default = "susanoo-test"
}

variable "bootstrap_hostname_ops" {
  type    = string
  default = "susanoo-ops"
}

variable "bootstrap_hostname_prod" {
  type    = string
  default = "courseplatform-prod"
}

variable "bootstrap_tailscale_auth_key_test" {
  type      = string
  sensitive = true
  default   = ""
}

variable "bootstrap_tailscale_auth_key_ops" {
  type      = string
  sensitive = true
  default   = ""
}

variable "bootstrap_tailscale_auth_key_prod" {
  type      = string
  sensitive = true
  default   = ""
}

variable "bootstrap_tailscale_tags_test" {
  type    = string
  default = "tag:test"
}

variable "bootstrap_tailscale_tags_ops" {
  type    = string
  default = "tag:ops"
}

variable "bootstrap_tailscale_tags_prod" {
  type    = string
  default = "tag:prod"
}

variable "ops_loki_host" {
  type    = string
  default = "susanoo-ops.longhair-eagle.ts.net"
}

variable "ops_test_hosts" {
  type    = list(string)
  default = []
}

variable "ops_prod_hosts" {
  type    = list(string)
  default = []
}

variable "ops_low_resource_mode" {
  type    = bool
  default = false
}

variable "ops_grafana_admin_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "ops_terraform_backend_enabled" {
  type    = bool
  default = true
}

variable "ops_terraform_backend_bucket" {
  type    = string
  default = "terraform-state"
}

variable "ops_terraform_backend_bind_ip" {
  type    = string
  default = ""
}

variable "ops_terraform_backend_port" {
  type    = number
  default = 9000
}

variable "ops_terraform_backend_access_key" {
  type    = string
  default = "terraform-state"
}

variable "ops_terraform_backend_secret_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "prod_pg_backup_enabled" {
  type    = bool
  default = true
}

variable "prod_pg_backup_oncalendar" {
  type    = string
  default = "*-*-* 03:15:00"
}

variable "prod_pg_backup_local_dir" {
  type    = string
  default = "/srv/backups/postgres"
}

variable "prod_pg_backup_local_retention_days" {
  type    = number
  default = 14
}

variable "prod_pg_backup_nas_dir" {
  type    = string
  default = ""
}

variable "prod_pg_backup_nas_retention_days" {
  type    = number
  default = 14
}
