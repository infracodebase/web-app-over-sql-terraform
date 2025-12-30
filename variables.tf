# Input variables
variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed"
  default     = "East US"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
  default     = "dev"
}

variable "app_name" {
  type        = string
  description = "Name of the application (used for resource naming)"
  default     = "webapp"
}

variable "admin_username" {
  type        = string
  description = "Administrator username for PostgreSQL server"
  default     = "pgadmin"
}

variable "app_service_sku" {
  type        = string
  description = "SKU for the App Service Plan"
  default     = "P1v3"
}

variable "postgresql_sku" {
  type        = string
  description = "SKU for PostgreSQL Flexible Server"
  default     = "B_Standard_B1ms"
}

variable "storage_tier" {
  type        = string
  description = "Storage tier for the storage account"
  default     = "Standard"
}

variable "storage_replication_type" {
  type        = string
  description = "Replication type for the storage account"
  default     = "LRS"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Environment = "dev"
    Project     = "webapp"
    ManagedBy   = "terraform"
  }
}