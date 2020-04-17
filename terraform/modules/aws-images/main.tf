# Find the AMI by:
# Account, Latest, x86_64, EBS, HVM, OS Name
data "aws_ami" "machine" {
  most_recent = true

  owners = [var.account_num]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = [var.os_name]
  }
}
