terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.20.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

resource "random_password" "server_password" {
  length  = 16
  special = true
}

variable "linode_token" {
  type      = string
  sensitive = true
}

variable "private_key_path" {
  type = string
}

variable "public_key_path" {
  type = string
}

resource "linode_instance" "server" {
  image            = "linode/debian10"
  label            = "helium3"
  group            = "helium3"
  region           = "us-west"
  type             = "g6-nanode-1"
  authorized_users = ["sidneynemzer"]
  root_pass        = random_password.server_password.result

  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y"]

    connection {
      host        = self.ip_address
      user        = "root"
      type        = "ssh"
      private_key = file(var.private_key_path)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ip_address},' --private-key ${var.private_key_path} -e 'pub_key=${var.public_key_path}' ../playbook.yaml"
  }
}

output "server_ip" {
  value = linode_instance.server.ip_address
}
