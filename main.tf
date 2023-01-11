provider "azurerm" {
    application_insights {
      disable_generated_rule = true
    }

    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    template_deployment {
      delete_nested_items_during_deletion = true
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = true
    }

    virtual_machine_scale_set {
      force_delete                  = true
      roll_instances_when_required  = true
      scale_to_zero_before_deletion = true
    }
  }
}
