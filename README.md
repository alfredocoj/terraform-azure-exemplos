# terraform-azure-exemplos
Exemplos com Terraform na Azure.

# Commands
```
az login
```

ou se houve algum cache de contas antigas:

```
az account clear
az login
```

# Utils commands to terraform

```
terraform init
terraform plan
terraform apply
terraform init -get-plugins=true -reconfigure
terraform destroy
```

# Location

https://azure.microsoft.com/en-us/global-infrastructure/geographies/

# VMs size

https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general

### Referênces: 

https://docs.microsoft.com/pt-br/azure/developer/terraform/getting-started-cloud-shell

https://docs.microsoft.com/pt-br/azure/developer/terraform/getting-started-cloud-shell#specify-the-current-azure-subscription

https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html

https://www.terraform.io/docs/providers/azure/r/security_group_rule.html

https://docs.microsoft.com/pt-br/azure/developer/terraform/hub-spoke-on-prem

https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ansible-on-ubuntu-16-04