# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "${local.resource_prefix}-appgw-pip"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.common_tags
}

# Web Application Firewall Policy
resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${local.resource_prefix}-waf-policy"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.common_tags

  policy_settings {
    enabled                     = true
    mode                       = "Prevention"
    request_body_check         = true
    file_upload_limit_in_mb    = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }

    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "0.1"
    }
  }
}

# Self-signed certificate for demonstration (replace with real certificate in production)
resource "azurerm_key_vault_certificate" "appgw_ssl" {
  name         = "appgw-ssl-cert"
  key_vault_id = azurerm_key_vault.this.id
  tags         = local.common_tags

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["${local.resource_prefix}.example.com"]
      }

      subject            = "CN=${local.resource_prefix}.example.com"
      validity_in_months = 12
    }
  }

  depends_on = [
    azurerm_role_assignment.current_user_kv_secrets_officer
  ]
}

# User assigned managed identity for Application Gateway
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "${local.resource_prefix}-appgw-identity"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

# Key Vault access policy for Application Gateway managed identity
resource "azurerm_role_assignment" "appgw_kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
}

# Application Gateway
resource "azurerm_application_gateway" "this" {
  name                = "${local.resource_prefix}-appgw"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  enable_http2        = true
  zones               = ["1", "2", "3"]
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id
  tags                = local.common_tags

  # SKU configuration
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  # Managed identity for Key Vault access
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  # Gateway IP configuration
  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  # Frontend port configurations
  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  # Frontend IP configurations
  frontend_ip_configuration {
    name                 = "public-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Backend address pool
  backend_address_pool {
    name  = "app-backend-pool"
    fqdns = [azurerm_linux_web_app.this.default_hostname]
  }

  # Backend HTTP settings
  backend_http_settings {
    name                  = "app-backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    pick_host_name_from_backend_address = true

    probe_name = "app-health-probe"
  }

  # Health probe
  probe {
    name                                      = "app-health-probe"
    protocol                                  = "Https"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true

    match {
      status_code = ["200-399"]
    }
  }

  # HTTP listener (redirect to HTTPS)
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "public-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # HTTPS listener
  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "public-frontend-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "ssl-certificate"
  }

  # SSL certificate from Key Vault
  ssl_certificate {
    name                = "ssl-certificate"
    key_vault_secret_id = azurerm_key_vault_certificate.appgw_ssl.secret_id
  }

  # HTTP to HTTPS redirect rule
  request_routing_rule {
    name                        = "http-redirect-rule"
    rule_type                   = "Basic"
    priority                    = 100
    http_listener_name          = "http-listener"
    redirect_configuration_name = "http-to-https-redirect"
  }

  # HTTPS routing rule
  request_routing_rule {
    name                       = "https-routing-rule"
    rule_type                  = "Basic"
    priority                   = 200
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "app-backend-pool"
    backend_http_settings_name = "app-backend-http-settings"
  }

  # HTTP to HTTPS redirect configuration
  redirect_configuration {
    name                 = "http-to-https-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "https-listener"
    include_path         = true
    include_query_string = true
  }

  depends_on = [
    azurerm_role_assignment.appgw_kv_secrets_user
  ]
}