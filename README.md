# using-terraform-rackspace-node-for-ansible
A simple example on how to user the terraform-rackspace-node-for-ansible to provision ansible inventory


This is a simple example which uses the [terraform-rackspace-node-for-ansible](https://github.com/AccountTechnologies/terraform-rackspace-node-for-ansible) module to provision nodes for an Ansible inventory file.
It allows you to join both RackSpace and other servers into a single inventory for simple management.

There are a number of variables that need to be changed, these include those in the test.tfvars file (terraform --var-file)
the location of the [terraform-rackspace-node-for-ansible](https://github.com/AccountTechnologies/terraform-rackspace-node-for-ansible) module in the main.tf file amoungst others

Basically each server goup is should be treated as a local module, such that 

```
module "internal" {
  source                  = "./modules/terraform-rackspace-node-for-ansible"
  node_count              = "1"
  name_prefix             = "${var.cluster_prefix}-internal"
  flavor_name             = "${var.flavor_name}"
  image_name              = "${var.image_name}"
  networks                = [{name="private",uuid="11111111-1111-1111-1111-111111111111"},{name="${var.internal_network_name}",uuid="${var.internal_network_uuid}"}]
  internal_network_uuid   = "${var.internal_network_uuid}"
  ssh_user                = "${var.ssh_user}"
  ssh_key                 = "${var.ssh_key}"
  ssh_keypair             = "${var.ssh_keypair}"
  ssh_bastion_host        = module.external.servers[0].public_network_ip
  ssh_allow_ip            = module.external.servers[*].internal_network_ip
  ssh_alt_user            = module.external.servers[0].ssh_user
  roles                   = ["roleASlave","roleB"]
}
 ```
Describes a number (1 or more) servers which can be joined to similar roles, and what sort of infrastructure they require (networks etc)
Local/Static servers not provisioned via Terraform can be added to the inventory via a locals.server_test variable in the main.tf file, which is added to the locals.servers variable. (any new roles need to be added into this)

This is then expanded into a inventory.yaml which can be tweaked, but simply groups servers into roles

You will need to 
```
terraform init
 ```

 and source the rackspace variables 
```
rc.sh
  ```

and provision the nodes 
```
terraform apply -var-file=test.tfvars
  ```
