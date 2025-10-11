# main.tf - Blueprint for all Azure resources

# 1. Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. Create a Resource Group to hold everything
resource "azurerm_resource_group" "rg" {
  name     = "CampusRecovery-RG"
  location = "Southeast Asia"
}

# 3. Create the MySQL Database
resource "azurerm_mysql_flexible_server" "db" {
  name                = "campuserver"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "B_Standard_B1ms" # This is the minimal Burstable tier
  administrator_login = "campus"
  administrator_password = "Rahgul_220701212" # CHANGE THIS PASSWORD
  public_network_access_enabled = true # This enables Public Access
}

resource "azurerm_mysql_flexible_database" "main_db" {
  name                = "CampusDatabase"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# 4. Create a single App Service Plan (Free F1 Tier) for both apps
resource "azurerm_service_plan" "plan" {
  name                = "Campus-AppServicePlan-Free"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1" # F1 is the Free tier
}

# 5. Create the Student Web App
resource "azurerm_linux_web_app" "student_app" {
  name                = "StudentApp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.plan.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      php_version = "8.2"
    }
  }

  app_settings = {
    "DB_HOST" = azurerm_mysql_flexible_server.db.fqdn
    "DB_NAME" = azurerm_mysql_flexible_database.main_db.name
    "DB_USER" = azurerm_mysql_flexible_server.db.administrator_login
    "DB_PASSWORD" = azurerm_mysql_flexible_server.db.administrator_password
  }
}

# 6. Create the Admin Web App
resource "azurerm_linux_web_app" "admin_app" {
  name                = "AdminApp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.plan.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      php_version = "8.2"
    }
  }

  app_settings = {
    "DB_HOST" = azurerm_mysql_flexible_server.db.fqdn
    "DB_NAME" = azurerm_mysql_flexible_database.main_db.name
    "DB_USER" = azurerm_mysql_flexible_server.db.administrator_login
    "DB_PASSWORD" = azurerm_mysql_flexible_server.db.administrator_password
  }
}
