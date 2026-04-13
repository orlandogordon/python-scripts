# In the module, you don't typically need to specify the provider on each
# resource — the module receives the provider via the `providers = {}` block
# in the root module's `module` invocation, and all resources in the module
# inherit it.
#
# So your existing resource blocks stay as-is. The only thing the module
# itself needs to declare is which provider configuration it requires:

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.0"
      configuration_aliases = [azurerm]
    }
  }
}