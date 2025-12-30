# App Service Plan
resource "azurerm_service_plan" "this" {
  name                = "${local.resource_prefix}-plan"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = local.common_tags
}

# App Service
resource "azurerm_linux_web_app" "this" {
  name                      = "${local.resource_prefix}-app"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_service_plan.this.location
  service_plan_id           = azurerm_service_plan.this.id
  client_affinity_enabled   = false
  client_certificate_enabled = false
  https_only               = true
  tags                     = local.common_tags

  # Enable managed identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    # Always on for production workloads
    always_on = true

    # Security settings
    ftps_state                = "Disabled"
    http2_enabled            = true
    minimum_tls_version      = "1.2"
    remote_debugging_enabled = false
    use_32_bit_worker        = false

    # Application stack - using Python as example
    application_stack {
      python_version = "3.11"
    }

    # IP restrictions to only allow traffic from Application Gateway
    ip_restriction {
      action                    = "Allow"
      name                      = "Allow-ApplicationGateway"
      priority                  = 100
      virtual_network_subnet_id = azurerm_subnet.appgw.id
    }

    # Default deny rule
    ip_restriction {
      action   = "Deny"
      name     = "Deny-All"
      priority = 2147483647
      ip_address = "0.0.0.0/0"
    }
  }

  # Application settings
  app_settings = {
    # Database connection settings
    "DATABASE_HOST"     = azurerm_postgresql_flexible_server.this.fqdn
    "DATABASE_NAME"     = azurerm_postgresql_flexible_server_database.app_db.name
    "DATABASE_USER"     = var.admin_username
    "DATABASE_SSL_MODE" = "require"

    # Key Vault reference for database password
    "DATABASE_PASSWORD" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.this.name};SecretName=${azurerm_key_vault_secret.postgresql_admin_password.name})"

    # Application Insights
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.this.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"

    # Storage account connection
    "AZURE_STORAGE_ACCOUNT_NAME" = azurerm_storage_account.this.name
    "AZURE_STORAGE_ACCOUNT_KEY"  = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.this.name};SecretName=${azurerm_key_vault_secret.storage_account_key.name})"

    # Security settings
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "8000"
  }

  # Connection strings for database
  connection_string {
    name  = "DefaultConnection"
    type  = "PostgreSQL"
    value = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.this.name};SecretName=${azurerm_key_vault_secret.connection_string.name})"
  }

  # Authentication configuration
  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    default_provider       = "azureactivedirectory"

    unauthenticated_action = "RedirectToLoginPage"

    active_directory_v2 {
      tenant_auth_endpoint = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/v2.0"
      client_id            = data.azurerm_client_config.current.client_id
    }
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
}

# VNet integration for App Service
resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  app_service_id = azurerm_linux_web_app.this.id
  subnet_id      = azurerm_subnet.app.id
}

# Key Vault role assignment for App Service managed identity
resource "azurerm_role_assignment" "app_service_kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.this.identity[0].principal_id
}

# Store database connection string in Key Vault
resource "azurerm_key_vault_secret" "connection_string" {
  name         = "database-connection-string"
  value        = "Host=${azurerm_postgresql_flexible_server.this.fqdn};Database=${azurerm_postgresql_flexible_server_database.app_db.name};Username=${var.admin_username};Password=${random_password.postgresql_admin_password.result};SSL Mode=Require;"
  key_vault_id = azurerm_key_vault.this.id
  tags         = local.common_tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_secrets_officer
  ]
}