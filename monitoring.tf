# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.resource_prefix}-law"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags

  # Security settings
  internet_ingestion_enabled = true
  internet_query_enabled     = true
}

# Application Insights
resource "azurerm_application_insights" "this" {
  name                = "${local.resource_prefix}-ai"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  retention_in_days   = 90
  tags                = local.common_tags
}

# Monitor Action Group for alerts
resource "azurerm_monitor_action_group" "this" {
  name                = "${local.resource_prefix}-action-group"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = "webapp-ag"
  tags                = local.common_tags

  email_receiver {
    name          = "admin-email"
    email_address = "admin@company.com" # Replace with actual email
  }
}

# Monitor Metric Alert for App Service CPU
resource "azurerm_monitor_metric_alert" "app_service_cpu" {
  name                = "${local.resource_prefix}-app-cpu-alert"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_linux_web_app.this.id]
  description         = "Alert when App Service CPU usage is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# Monitor Metric Alert for PostgreSQL CPU
resource "azurerm_monitor_metric_alert" "postgresql_cpu" {
  name                = "${local.resource_prefix}-pg-cpu-alert"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_postgresql_flexible_server.this.id]
  description         = "Alert when PostgreSQL CPU usage is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# Monitor Metric Alert for Application Gateway Backend Health
resource "azurerm_monitor_metric_alert" "appgw_backend_health" {
  name                = "${local.resource_prefix}-appgw-health-alert"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_application_gateway.this.id]
  description         = "Alert when Application Gateway backend health is low"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "HealthyHostCount"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}