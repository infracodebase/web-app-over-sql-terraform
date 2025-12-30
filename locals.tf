# Local values
locals {
  # Resource naming convention
  resource_prefix = "${var.app_name}-${var.environment}"

  # Network configuration
  vnet_address_space     = "10.0.0.0/16"
  appgw_subnet_prefix    = "10.0.1.0/24"
  app_subnet_prefix      = "10.0.2.0/24"
  db_subnet_prefix       = "10.0.3.0/24"
  private_endpoint_subnet_prefix = "10.0.4.0/24"

  # Common tags
  common_tags = merge(var.tags, {
    Location = var.location
  })
}