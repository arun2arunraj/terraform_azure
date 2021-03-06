provider "azurerm" {
	subscription_id="39ac48fb-fea0-486a-ba84-e0ae9b06c663"
	#client_id=""
	#client_secret=""
	#tenant_id=""
}
resource "azurerm_resource_group" "myterraformgroup" {
	name = "myResourceGroup"
	location = "eastus"
	tags {
		environment="Terraform Demo"
	}
}
resource "azurerm_virtual_network" "myterraformnetwork" {
	name =	"myVnet"
	address_space = ["10.0.0.0/16"]
	location = "eastus"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
	tags {
		environment="Terraform Demo"
	}
}
resource "azurerm_subnet" "myterraformsubnet" {
	name = "mySubnet"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
	virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
	address_prefix="10.0.2.0/24"
}
#resource "azurerm_public_ip" "myterraformpublicip" {
#	name = "myPublicIP"
#	location = "eastus"
#	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
#	public_ip_address_allocation = dynamic
#	tags {
#		environment = "Terraform Demo"
#	}
#}
resource "azurerm_network_security_group" "temyterraformpublicipnsg" {
	name = "myNetworkSecurityGroup"
	location = "eastus"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
	
	security_rule {
		name = "SSH"
		priority = 1001
		direction = "Inbound"
		access = "allow"
		protocol = "Tcp"
		source_port_range = "*"
		destination_port_range = "22"
		source_address_prefix = "*"
		destination_address_prefix= "*"
	}
	
	tags {
		environment = "Terraform Demo"
	}
}
resource "azurerm_network_interface" "myterraformnic" {
	name = "myNIC"
	location = "eastus"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
	network_security_group_id ="${azurerm_network_security_group.temyterraformpublicipnsg.id}"
	ip_configuration {
		name = "myNicConfiguration"
		subnet_id = "${azurerm_subnet.myterraformsubnet.id}"
		private_ip_address_allocation = "dynamic"
	#	public_ip_address_id = "${azurerm_public_ip.myterraformpublicip.id}"
	}
	tags {
		environment="Terraform Demo"
	}
}
resource "random_id" "randomId" {
	keepers = {
		resource_group="${azurerm_resource_group.myterraformgroup.name}"
	}
	byte_length = 8
}
resource "azurerm_storage_account" "mystorageaccount" {
	name = "diag${random_id.randomId.hex}"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
	location = "eastus"
	account_tier = "Standard"
	account_replication_type = "LRS"
	tags {
		environment = "Terraform Demo"
	}
}
resource "azurerm_virtual_machine" "myterraformVM" {
	name = "myVM"
	location = "eastus"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
	network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
	vm_size = "Standard_DS1_v2"

	storage_os_disk {
		name = "myOSDisk"
		caching = "ReadWrite"
		create_option = "FromImage"
		managed_disk_type = "Premium_LRS"
	}
	
	storage_image_reference {
		publisher = "Canonical"
		offer = "UbuntuServer"
		sku = "16.04.0-LTS"
		version = "latest"
	}
	
	os_profile {
		computer_name = "myvm"
		admin_username = "sre"
	}
	
	os_profile_linux_config {
		disable_password_authentication = true
		ssh_keys {
			path = "/home/sre/.ssh/authorized_keys"
			key_data = "ssh-rsa AAAAB3Nz{snip}hwhqT9h"
		}
	}
	boot_diagnostics {
		enabled = "true"
		storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
	}
	tags {
		environment = "Terraform Demo"
	}
}
