# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                      = "vmloganalytics"
  resource_group_name             = local.rg_name
  location                        = local.rg_location
  sku                       = "PerGB2018"
  internet_query_enabled    = false
}
