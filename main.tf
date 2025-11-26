# main.tf - Blueprint for all Azure resources (CORRECTED)

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
  name                = "rahgul-campus-mysql-server" # CHANGED NAME FOR GLOBAL UNIQUENESS
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "B_Standard_B1ms" # This is the minimal Burstable tier
  administrator_login = "campus"
  administrator_password = "Rahgul_220701212" # CHANGE THIS PASSWORD
  
  # REMOVED: public_network_access_enabled = true 
  # This is implicitly enabled by the firewall rule below.
}

# 3b. Add Firewall Rule to enable Public Access (REQUIRED FIX)
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_all_azure" {
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db.name
  
  # The IP range 0.0.0.0 to 0.0.0.0 is used to allow all Azure services access.
  # This enables the Web Apps to connect to the MySQL server.
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0" 
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
