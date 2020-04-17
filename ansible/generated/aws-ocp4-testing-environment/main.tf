# Ansible managed

# Setup the core provider information.
provider "aws" {
  region  = var.region
}

# Obtain information on the execution agent (person)
module "aws-caller" {
  source = "../../../../../automation-incubator/terraform/modules/aws-caller"
}

# Setup common tags to be set against created resources
locals {
  # Common tags to be assigned to all resources
  common_tags = {
    "InfraName"         = "ocp4-testing-1"
    "Owner"             = module.aws-caller.arn
    "User"              = module.aws-caller.user
    "Account"           = module.aws-caller.account_id
  }
}

# Create a public key reference in AWS for machines to accept
resource "aws_key_pair" "keypair" {
  key_name   = "ocp4-testing-1-sshkey"
  public_key = file(var.ssh-public-key-file)
}

 
# Create custom security groups
resource "aws_security_group" "o1_security_group" {
  name        = "o1_security_group"
  description = "Network rules for o1 env"
  vpc_id      = "vpc-07e7d2553a8cf4117"

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
    cidr_blocks = ["10.0.0.0/16"]
  }


  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = merge(
           local.common_tags,
           map(
             "Name", "o1_security_group",
             "infra_name", "ocp4-testing-1"
           )
         )
}


# Establish AMIs to use
module "rhel_7_7-images" {
  source      = "../../../../../automation-incubator/terraform/modules/aws-images"
  account_num = "309956199498"
  os_name = "RHEL-7.7*"
}
# Establish AMIs to use
module "centos_7-images" {
  source      = "../../../../../automation-incubator/terraform/modules/aws-images"
  account_num = "679593333241"
  os_name = "CentOS7*"
}



# Create all environment nodes

resource "aws_instance" "o1_anode_instance_1" {
  ami                    = module.rhel_7_7-images.ami_id
  instance_type          = "t2.micro"
  iam_instance_profile   = "ocp4test-v5tj6-bootstrap-profile"
  subnet_id              = "subnet-02b3ba54a444329ba"
  vpc_security_group_ids = ["sg-0268ce964a906ea5d", "sg-04feddf60c969a995",
                            aws_security_group.o1_security_group.id]
  key_name               = "ocp4-testing-1-sshkey"

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }


  tags = merge(
    local.common_tags,
    map(
      "Name", "o1-anode.openshift.local"
    )
  )
}


// Get elastic IP for server if required.
resource "aws_eip" "o1_anode_instance_1_instance_eip" {
  instance = aws_instance.o1_anode_instance_1.id
  vpc      = true
  tags = merge(
    local.common_tags,
    map(
      "Name", "o1-anode.openshift.local"
    )
  )
}



// Collect together all of the output variables required downstream

// AWS exposed data
data "template_file" "terraform_exposed_vars" {
  template = "${file("${path.cwd}/terraform_exposed_vars.yml.tpl")}"
  vars = {
    o1_anode_addresses = "'${aws_instance.o1_anode_instance_1.private_dns}'"
  }
}

//  Create the ansible variable file for aws secrets.
resource "local_file" "terraform_exposed_vars_yml" {
  content  = "${data.template_file.terraform_exposed_vars.rendered}"
  filename = "${path.cwd}/terraform_exposed_vars.yml"
}
