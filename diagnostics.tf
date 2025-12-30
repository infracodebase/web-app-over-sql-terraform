# Diagnostic settings for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "${local.resource_prefix}-appgw-diagnostics"
  target_resource_id         = azurerm_application_gateway.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # Application Gateway logs
  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  # Application Gateway metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic settings for App Service
resource "azurerm_monitor_diagnostic_setting" "app_service" {
  name                       = "${local.resource_prefix}-app-diagnostics"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # App Service logs
  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  # App Service metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic settings for PostgreSQL
resource "azurerm_monitor_diagnostic_setting" "postgresql" {
  name                       = "${local.resource_prefix}-pg-diagnostics"
  target_resource_id         = azurerm_postgresql_flexible_server.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # PostgreSQL logs
  enabled_log {
    category = "PostgreSQLLogs"
  }

  # PostgreSQL metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "${local.resource_prefix}-kv-diagnostics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # Key Vault logs
  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  # Key Vault metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "${local.resource_prefix}-storage-diagnostics"
  target_resource_id         = azurerm_storage_account.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # Storage metrics
  metric {
    category = "Transaction"
    enabled  = true
  }

  metric {
    category = "Capacity"
    enabled  = true
  }
}

# Diagnostic settings for Virtual Network
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "${local.resource_prefix}-vnet-diagnostics"
  target_resource_id         = azurerm_virtual_network.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # VNet logs
  enabled_log {
    category = "VMProtectionAlerts"
  }

  # VNet metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic settings for Network Security Groups
resource "azurerm_monitor_diagnostic_setting" "nsg_appgw" {
  name                       = "${local.resource_prefix}-nsg-appgw-diagnostics"
  target_resource_id         = azurerm_network_security_group.appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # NSG logs
  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_app" {
  name                       = "${local.resource_prefix}-nsg-app-diagnostics"
  target_resource_id         = azurerm_network_security_group.app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # NSG logs
  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# Activity log diagnostic setting for the resource group
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "${local.resource_prefix}-activity-log"
  target_resource_id         = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # Activity log categories
  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }
}