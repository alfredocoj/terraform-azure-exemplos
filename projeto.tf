provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
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
  address_prefixes       = ["10.0.1.0/24"]
}

# ## SN SERVICES
# resource "azurerm_subnet" "sn-services" {
#   name                 = "${var.prefix}-sn-services"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vn.name
#   address_prefix       = ["10.0.2.0/24"]
# }

## SN MONITORING
resource "azurerm_subnet" "sn-monitoring" {
  name                 = "${var.prefix}-sn-monitoring"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes       = ["10.0.3.0/24"]
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

# ## NI SERVICE MASTER
# resource "azurerm_network_interface" "nic-services-master" {
#   name                = "${var.prefix}-nic-services-master"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   ip_configuration {
#     name                          = "ipc-services-master"
#     subnet_id                     = azurerm_subnet.sn-services.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# ## NI SERVICE NODE
# resource "azurerm_network_interface" "nic-services-node" {
#   name                = "${var.prefix}-nic-services-node"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   ip_configuration {
#     name                          = "ipc-services-node"
#     subnet_id                     = azurerm_subnet.sn-services.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

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

###################################### KUBERNETES ############################################

#############################################################
################# RESOURCE GROUP KUBERNETES #################
#############################################################
resource "azurerm_resource_group" "rg-k8s" {
  name     = "${var.prefix-k8s}-resources"
  location = "Central US"
}

#############################################################
################# VIRTUAL NETWORK KUBERNETES ################
#############################################################

resource "azurerm_virtual_network" "vn-k8s" {
  name                = "${var.prefix-k8s}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name
}

#############################################################
################# SUBNETS KUBERNETES ########################
#############################################################

## SN KUBERNETES
resource "azurerm_subnet" "sn-k8s" {
  name                 = "${var.prefix-k8s}-sn-k8s"
  resource_group_name  = azurerm_resource_group.rg-k8s.name
  virtual_network_name = azurerm_virtual_network.vn-k8s.name
  address_prefixes       = ["10.0.2.0/24"]
}

#############################################################
################# PUBLIC IP TO KUBERNETES MASTER ############
#############################################################

resource "azurerm_public_ip" "pip-k8s" {
    name                         = "${var.prefix-k8s}-pip-k8s"
    location            = azurerm_resource_group.rg-k8s.location
    resource_group_name = azurerm_resource_group.rg-k8s.name
    allocation_method   = "Dynamic"
}

#############################################################
################# NETWORK INTERFACES ########################
#############################################################

## NI SERVICE MASTER
resource "azurerm_network_interface" "nic-k8s-master" {
  name                = "${var.prefix-k8s}-nic-k8s-master"
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name

  ip_configuration {
    name                          = "ipc-k8s-master"
    subnet_id                     = azurerm_subnet.sn-k8s.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-k8s.id
  }
}

## NI SERVICE NODE
resource "azurerm_network_interface" "nic-k8s-node" {
  name                = "${var.prefix-k8s}-nic-k8s-node"
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name

  ip_configuration {
    name                          = "ipc-k8s-node"
    subnet_id                     = azurerm_subnet.sn-k8s.id
    private_ip_address_allocation = "Dynamic"
  }
}

#############################################################
################# VITUAL MACHINES KUBERNETES ################
#############################################################

## k8s Master
resource "azurerm_virtual_machine" "vm-master" {
  name                  = "${var.prefix-k8s}-vm-master"
  location              = azurerm_resource_group.rg-k8s.location
  resource_group_name   = azurerm_resource_group.rg-k8s.name
  network_interface_ids = [azurerm_network_interface.nic-k8s-master.id]
  vm_size               = "Standard_D2s_v3"
  # B2s

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
  name                  = "${var.prefix-k8s}-vm-node"
  location              = azurerm_resource_group.rg-k8s.location
  resource_group_name   = azurerm_resource_group.rg-k8s.name
  network_interface_ids = [azurerm_network_interface.nic-k8s-node.id]
  vm_size               = "Standard_D2s_v3"

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


#################################################################
####################### SECURITY ################################
#################################################################

# resource "azurerm_network_security_group" "sg-general" {
#   name                = "${var.prefix}-sg-general"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

resource "azurerm_network_security_group" "sg-k8s" {
  name                = "${var.prefix-k8s}-sg-k8s"
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name

  security_rule {
    name                       = "ssh-access-rule"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = azurerm_public_ip.pip-balanceador.ip_address
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "sga-k8s" {
  subnet_id                 = azurerm_subnet.sn-k8s.id
  network_security_group_id = azurerm_network_security_group.sg-k8s.id
}

# resource "azure_security_group_rule" "ssh_access-k8s" {
#   name                       = "ssh-access-rule"
#   security_group_names       = ["${azure_security_group.sg-k8s.name}"]
#   type                       = "Inbound"
#   action                     = "Allow"
#   priority                   = 200
#   source_address_prefix      = azurerm_public_ip.pip-balanceador.ip_address
#   source_port_range          = "*"
#   destination_address_prefix = "10.0.0.0/16"
#   destination_port_range     = "22"
#   protocol                   = "TCP"
# }