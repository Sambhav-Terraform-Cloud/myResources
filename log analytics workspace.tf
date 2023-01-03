# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                      = "vmloganalytics"
  resource_group_name             = azurerm_resource_group.name
  location                        = azurerm_resource_group.location
  sku                       = "PerGB2018"
  internet_query_enabled    = false
}
