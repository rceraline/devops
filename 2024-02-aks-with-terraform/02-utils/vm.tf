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
