provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

variable "prefix" {
  default = "devops"
}


#############################################################
################# RESOURCE GROUP ############################
#############################################################
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-resources"
  location = "West US 2"
}


#############################################################
################# VIRTUAL NETWORK ###########################
#############################################################

resource "azurerm_virtual_network" "vn" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#############################################################
################# SUBNETS ###################################
#############################################################

## SN LOAD BALANCER
resource "azurerm_subnet" "sn-balanceador" {
  name                 = "${var.prefix}-sn-balanceador"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefix       = "10.0.1.0/24"
}

## SN SERVICES
resource "azurerm_subnet" "sn-services" {
  name                 = "${var.prefix}-sn-services"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefix       = "10.0.2.0/24"
}

## SN MONITORING
resource "azurerm_subnet" "sn-monitoring" {
  name                 = "${var.prefix}-sn-monitoring"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefix       = "10.0.3.0/24"
}


#############################################################
################# PUBLIC IP TO LOAD BALANCER ################
#############################################################

resource "azurerm_public_ip" "pip-balanceador" {
    name                         = "${var.prefix}-pip-balanceador"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Dynamic"
}


#############################################################
################# NETWORK INTERFACES ########################
#############################################################

## NI LOAD BALANCER
resource "azurerm_network_interface" "nic-balanceador" {
  name                = "${var.prefix}-nic-balanceador"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipc-balanceador"
    subnet_id                     = azurerm_subnet.sn-balanceador.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-balanceador.id
  }
}

## NI SERVICE MASTER
resource "azurerm_network_interface" "nic-services-master" {
  name                = "${var.prefix}-nic-services-master"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipc-services-master"
    subnet_id                     = azurerm_subnet.sn-services.id
    private_ip_address_allocation = "Dynamic"
  }
}

## NI SERVICE NODE
resource "azurerm_network_interface" "nic-services-node" {
  name                = "${var.prefix}-nic-services-node"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipc-services-node"
    subnet_id                     = azurerm_subnet.sn-services.id
    private_ip_address_allocation = "Dynamic"
  }
}

## NI MONITORING
resource "azurerm_network_interface" "nic-monitoring" {
  name                = "${var.prefix}-nic-monitoring"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipc-monitoring"
    subnet_id                     = azurerm_subnet.sn-monitoring.id
    private_ip_address_allocation = "Dynamic"
  }
}

#############################################################
################# VITUAL MACHINES ###########################
#############################################################

## Load Balancer
resource "azurerm_virtual_machine" "vm-balanceador" {
  name                  = "${var.prefix}-vm-balanceador"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic-balanceador.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm-balanceador"
    admin_username = var.user
    admin_password = var.password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

## k8s Master
resource "azurerm_virtual_machine" "vm-master" {
  name                  = "${var.prefix}-vm-master"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic-services-master.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk-master"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm-master"
    admin_username = var.user
    admin_password = var.password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

## k8s node
resource "azurerm_virtual_machine" "vm-node" {
  name                  = "${var.prefix}-vm-node"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic-services-node.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk-node"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm-node"
    admin_username = var.user
    admin_password = var.password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}



## Monitoring
resource "azurerm_virtual_machine" "vm-monitoring" {
  name                  = "${var.prefix}-vm-monitoring"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic-monitoring.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk-monitoring"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm-monitoring"
    admin_username = var.user
    admin_password = var.password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}