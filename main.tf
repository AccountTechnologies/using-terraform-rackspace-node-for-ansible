module "external" {
  source                  = "./modules/terraform-rackspace-node-for-ansible"
  node_count              = "1"
  name_prefix             = "${var.cluster_prefix}-external"
  flavor_name             = "${var.flavor_name}"
  image_name              = "${var.image_name}"
  networks                = [{name="public",uuid="00000000-0000-0000-0000-000000000000"},{name="private",uuid="11111111-1111-1111-1111-111111111111"},{name="${var.internal_network_name}",uuid="${var.internal_network_uuid}"}]
  internal_network_uuid   = "${var.internal_network_uuid}"
  ssh_user                = "${var.ssh_user}"
  ssh_key                 = "${var.ssh_key}"
  ssh_keypair             = "${var.ssh_keypair}"
  ssh_bastion_host        = ""
  ssh_allow_ip            = var.ssh_allow_ip
  ssh_alt_user            = "${var.ssh_alt_user}"
  roles                   = ["roleC","Basition"]
}

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


locals {
  server_test = {
      "id" = "00000000-0000-0000-0000-000000000000",
      "ssh_bastion_host" = "",
      "ssh_key" = var.ssh_key,
      "ssh_user" = var.ssh_alt_user,
      "ssh_host" = "#.#.#.#",
      "internal_network_ip" = "#.#.#.#"
      "public_network_ip" = "#.#.#.#"
      "hostname" = "static-server"
      "host" = "#.#.#.#"
      "roles" = ["roleAMaster"]
  }
}

locals {
  other_servers = [local.server_test]
  servers = distinct(flatten([module.external.servers,module.internal.servers, local.other_servers ]))
  roles = distinct(flatten(local.servers[*].roles))
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.yaml"
  content =<<EOT
all:
  hosts:
  children:
    external:
      hosts:
%{ for server in local.servers ~}
        ${server.hostname}:
          #ansible_port: 5555
          ansible_ssh_private_key_file: ${server.ssh_key}
          ansible_host: ${server.host}
          internal_network_ip: ${server.internal_network_ip}
          public_network_ip: ${server.public_network_ip}
          %{ if server.ssh_bastion_host != "" }ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${server.ssh_key} -q ${server.ssh_user}@${server.ssh_bastion_host}"'%{ else }ansible_ssh_common_args: '-o StrictHostKeyChecking=no '%{ endif ~}

%{ endfor ~}

%{ for role in local.roles ~}

${role}:
      hosts:%{ for server in local.servers ~}
%{ if contains(server.roles, role) }
        ${server.hostname}:%{ endif ~}
%{ endfor ~}      
%{ endfor ~}
EOT

}

