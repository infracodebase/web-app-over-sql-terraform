# Azure Web Application Infrastructure

This Terraform configuration deploys a secure, scalable web application infrastructure on Azure with comprehensive monitoring and logging capabilities.

## Architecture Overview

The infrastructure includes:

- **Application Gateway** with Web Application Firewall (WAF) for secure ingress
- **App Service** with VNet integration and managed identity
- **PostgreSQL Flexible Server** for database storage
- **Key Vault** for secrets management
- **Storage Account** with private endpoints for blob storage
- **Log Analytics Workspace** and **Application Insights** for monitoring
- **Virtual Network** with multiple subnets and Network Security Groups

## Security Features

- **Private Endpoints**: Key Vault and Storage Account accessible only through private network
- **VNet Integration**: App Service deployed into dedicated subnet
- **Network Security Groups**: Configured with least-privilege access rules
- **Managed Identity**: App Service uses managed identity for secure resource access
- **WAF Protection**: Application Gateway configured with OWASP and Bot Manager rules
- **SSL/TLS**: HTTPS enforcement with TLS 1.2 minimum version
- **Azure AD Authentication**: Configured for App Service authentication

## Monitoring & Logging

- **Application Insights**: Application performance monitoring and telemetry
- **Log Analytics**: Centralized logging for all resources
- **Diagnostic Settings**: Enabled for all resources to capture logs and metrics
- **Metric Alerts**: CPU monitoring for App Service and PostgreSQL
- **Action Groups**: Email notifications for alerts

## File Structure

```
├── terraform.tf          # Terraform configuration and required providers
├── providers.tf          # Provider configuration
├── variables.tf          # Input variables
├── locals.tf             # Local values and naming conventions
├── main.tf               # Core resources (RG, VNet, subnets)
├── network.tf            # Network Security Groups and associations
├── keyvault.tf           # Key Vault and private endpoint
├── postgresql.tf         # PostgreSQL Flexible Server
├── appservice.tf         # App Service and Service Plan
├── storage.tf            # Storage Account with private endpoint
├── monitoring.tf         # Log Analytics, Application Insights, alerts
├── applicationgateway.tf # Application Gateway with WAF
├── diagnostics.tf        # Diagnostic settings for all resources
├── outputs.tf            # Output values
├── .gitignore            # Git ignore file for Terraform
└── README.md             # This file
```

## Prerequisites

1. Azure CLI installed and configured
2. Terraform >= 1.13 installed
3. Azure subscription with appropriate permissions
4. Service Principal or managed identity with:
   - Contributor role on the subscription
   - Key Vault Administrator role (for RBAC-enabled Key Vault)

## Deployment

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Review and customize variables:**
   ```bash
   # Create terraform.tfvars file
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Plan deployment:**
   ```bash
   terraform plan
   ```

4. **Deploy infrastructure:**
   ```bash
   terraform apply
   ```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `location` | Azure region for deployment | `"East US"` |
| `environment` | Environment name | `"dev"` |
| `app_name` | Application name prefix | `"webapp"` |
| `admin_username` | PostgreSQL admin username | `"pgadmin"` |
| `app_service_sku` | App Service Plan SKU | `"P1v3"` |
| `postgresql_sku` | PostgreSQL server SKU | `"B_Standard_B1ms"` |
| `storage_tier` | Storage account tier | `"Standard"` |
| `storage_replication_type` | Storage replication type | `"LRS"` |

## Outputs

The configuration provides several useful outputs:

- Application Gateway public IP and FQDN
- App Service hostname and URL
- PostgreSQL server FQDN
- Key Vault URI
- Storage Account details
- Log Analytics Workspace ID
- Application Insights connection string

## Post-Deployment Steps

1. **Update DNS**: Point your domain to the Application Gateway public IP
2. **Replace SSL Certificate**: Replace the self-signed certificate with a real one
3. **Configure Application**: Deploy your web application to the App Service
4. **Set up Database**: Create database schema and initial data
5. **Configure Monitoring**: Set up custom dashboards and alerts in Log Analytics

## Security Considerations

- The PostgreSQL admin password is randomly generated and stored in Key Vault
- All secrets are accessed via Key Vault references in App Service
- Network access is restricted using NSGs and private endpoints
- SSL/TLS is enforced throughout the architecture
- Regular security updates should be applied to all components

## Cost Optimization

- Resources are configured with cost-effective SKUs suitable for development
- For production, consider:
  - Upgrading to higher SKUs for better performance
  - Enabling geo-redundant backup for PostgreSQL
  - Using reserved instances for cost savings
  - Implementing auto-scaling for App Service

## Maintenance

- Monitor costs using Azure Cost Management
- Review security recommendations in Microsoft Defender for Cloud
- Keep Terraform state secure and backed up
- Regularly update Terraform provider versions
- Review and rotate secrets in Key Vault

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data.

## Support

For issues or questions:
1. Check the Azure documentation for specific services
2. Review Terraform Azure provider documentation
3. Check Azure service health status
4. Contact your Azure support team if needed