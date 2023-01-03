# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                      = "vmloganalytics"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  sku                       = "PerGB2018"
  internet_query_enabled    = false
}
