provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "example" {
  name     = "test-dcr"
  location = "eastus"
}
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "tesstlaw"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "vminsights" {
  solution_name         = "VMInsights"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  workspace_name        = azurerm_log_analytics_workspace.workspace.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}

# Data Collection Rules
resource "azurerm_monitor_data_collection_rule" "rule" {
  name                = "test-dcr"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
      name                  = "destination-log"
    }

    azure_monitor_metrics {
      name = "destination-metrics"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["destination-metrics"]
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf", "Microsoft-WindowsEvent"]
    destinations = ["destination-log"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
      name                          = "VMInsightsPerfCounters"
    }

  }
  depends_on = [
    azurerm_log_analytics_solution.vminsights
  ]
}
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

#VM
resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  identity {
    type         = "SystemAssigned"
  }
}

# Azure Monitor Extension
resource "azurerm_virtual_machine_extension" "azuremonitorwindowsagent" {
  depends_on                 = [azurerm_virtual_machine_extension.da]
  name                       = "AzureMonitorWindowsAgent"
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = 1.8
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = "true"
  virtual_machine_id         = azurerm_windows_virtual_machine.example.id

  settings = jsonencode({
    workspaceId               = azurerm_log_analytics_workspace.workspace.id
    azureResourceId           = azurerm_windows_virtual_machine.example.id
    stopOnMultipleConnections = false

  })
  protected_settings = jsonencode({
    "workspaceKey" = azurerm_log_analytics_workspace.workspace.primary_shared_key
  })
}

resource "azurerm_virtual_machine_extension" "da" {
  name                       = "DAExtension"
  virtual_machine_id         = azurerm_windows_virtual_machine.example.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.10"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
}

resource "azurerm_monitor_data_collection_rule_association" "example1" {
  name                    = "example1-dcra"
  target_resource_id      = azurerm_windows_virtual_machine.example.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.rule.id
  description             = "example"
}
