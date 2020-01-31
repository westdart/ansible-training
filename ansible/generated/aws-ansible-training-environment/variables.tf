# Ansible managed

//  The region we will deploy our cloud into.
variable "region" {
  description = "Region to deploy the cloud into"
  default = "eu-west-2"
}

// To override, pass in on the terraform command line with -var="ssh-public-key-file=/path/to/public-key.pub"
//
// To use for a connection, add this to ~/.ssh/config file:
//
//     Host aws_bastion
//         Hostname ec2-3-9-166-52.eu-west-2.compute.amazonaws.com
//         IdentityFile ~/work/devops-in-a-box/automation-incubator/terraform/test/test-key
//         IdentitiesOnly yes
//
// The permssions on ~/.ssh/config must be u=rw,g-rwx,o-rwx (400).
//
// The permissions on the private key file must be u=r,g-rwx,o-rwx (400).
//
// The permissions on the public key can be u=r,g=r,o=r (600).
//
// Then connect like this:
//
//     $ ssh ec2-user@aws_bastion
//
variable "ssh-public-key-file" {
  description="Default SSH public key file."
  default="~/.ssh/id_rsa.pub"
}

variable "initials" {
    type = "string"
    default = null
}