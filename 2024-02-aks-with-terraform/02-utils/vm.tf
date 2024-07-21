resource "azurerm_network_interface" "nic_01" {
  name                = "nic-01"
  location            = data.azurerm_resource_group.rg_01.location
  resource_group_name = data.azurerm_resource_group.rg_01.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.utils_01.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm_01" {
  name                = "vm-01"
  resource_group_name = data.azurerm_resource_group.rg_01.name
  location            = data.azurerm_resource_group.rg_01.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = var.vm_password
  network_interface_ids = [
    azurerm_network_interface.nic_01.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "install_tools" {
  name                 = "tools"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_01.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
 {
  "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${filebase64("${path.module}/install_tools.ps1")}')) | Out-File -filepath install_tools.ps1\" && powershell -ExecutionPolicy Unrestricted -File install_tools.ps1"
 }
SETTINGS
}

