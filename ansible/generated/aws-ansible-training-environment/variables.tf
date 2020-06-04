# Ansible managed

variable "region" {
  description = "Region to deploy the cloud into"
  default = "eu-west-2"
}

variable "ssh-public-key-file" {
  description="Default SSH public key file."
  default="~/.ssh/id_rsa.pub"
}
