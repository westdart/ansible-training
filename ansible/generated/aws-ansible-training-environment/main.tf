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
    "InfraName"         = "ansible-training-1"
    "Owner"             = module.aws-caller.arn
    "User"              = module.aws-caller.user
    "Account"           = module.aws-caller.account_id
  }
}

# Setup IAM objects
module "aws-iam" {
  source      = "../../../../../automation-incubator/terraform/modules/aws-iam"
  name        = "ansible-training-1"
  prefix      = "ansible-training-1-"
  common-tags = local.common_tags
}

# Create VPC and other cloud wide resources
module "aws-cloud" {
  source         = "../../../../../automation-incubator/terraform/modules/aws-cloud"
  cloud_cidr     = "10.0.0.0/16"
  cloud_name     = "Ansible Training Env"
  common-tags    = local.common_tags
}


# Create environment subnets and route table associations
resource "aws_subnet" "t1_public_subnet" {
  vpc_id                  = module.aws-cloud.vpc-id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
  depends_on              = ["module.aws-cloud"]
  tags = merge(
    local.common_tags,
    map(
      "Name", "Ansible Training 1 env",
      "Type", "Public",
      "infra_name", "ansible-training-1"
    )
  )
}
resource "aws_route_table_association" "t1_public_subnet_asoc" {
  subnet_id      = aws_subnet.t1_public_subnet.id
  route_table_id = module.aws-cloud.public_route_id
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

# Create a public key reference in AWS for machines to accept
resource "aws_key_pair" "keypair" {
  key_name   = "ansible-training-1-sshkey"
  public_key = file(var.ssh-public-key-file)
}

# Create custom security groups
resource "aws_security_group" "t1_security_group" {
  name        = "t1_security_group"
  description = "Network rules for t1 env"
  vpc_id      = module.aws-cloud.vpc-id

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
    cidr_blocks = ["10.0.1.0/24"]
  }


  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
    cidr_blocks = ["10.0.1.0/24"]
  }

  tags = merge(
           local.common_tags,
           map(
             "Name", "t1_security_group",
             "infra_name", "ansible-training-1"
           )
         )
}





# Create all environment nodes

resource "aws_instance" "t1_tnode_instance_1" {
  ami                    = module.rhel_7_7-images.ami_id
  instance_type          = "t2.micro"
  iam_instance_profile   = module.aws-iam.sts-instance-profile-id
  subnet_id              = aws_subnet.t1_public_subnet.id
  vpc_security_group_ids = [module.aws-cloud.public-security-group,module.aws-cloud.ingres-security-group,module.aws-cloud.egres-security-group,
                            aws_security_group.t1_security_group.id]
  key_name               = "ansible-training-1-sshkey"

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }


  tags = merge(
    local.common_tags,
    map(
      "Name", "t1-tnode1.at.local"
    )
  )
}


resource "aws_instance" "t1_tnode_instance_2" {
  ami                    = module.rhel_7_7-images.ami_id
  instance_type          = "t2.micro"
  iam_instance_profile   = module.aws-iam.sts-instance-profile-id
  subnet_id              = aws_subnet.t1_public_subnet.id
  vpc_security_group_ids = [module.aws-cloud.public-security-group,module.aws-cloud.ingres-security-group,module.aws-cloud.egres-security-group,
                            aws_security_group.t1_security_group.id]
  key_name               = "ansible-training-1-sshkey"

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }


  tags = merge(
    local.common_tags,
    map(
      "Name", "t1-tnode2.at.local"
    )
  )
}


resource "aws_instance" "t1_tnode_instance_3" {
  ami                    = module.rhel_7_7-images.ami_id
  instance_type          = "t2.micro"
  iam_instance_profile   = module.aws-iam.sts-instance-profile-id
  subnet_id              = aws_subnet.t1_public_subnet.id
  vpc_security_group_ids = [module.aws-cloud.public-security-group,module.aws-cloud.ingres-security-group,module.aws-cloud.egres-security-group,
                            aws_security_group.t1_security_group.id]
  key_name               = "ansible-training-1-sshkey"

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }


  tags = merge(
    local.common_tags,
    map(
      "Name", "t1-tnode3.at.local"
    )
  )
}





// Collect together all of the output variables required downstream

// AWS secrets data
data "template_file" "terraform_secret_vars" {
  template = "${file("${path.cwd}/../../templates/terraform_secret_vars.yml.tpl")}"
  vars = {
    aws_access_key = "${module.aws-iam.application-user-access-key}"
    aws_secret_key = "${module.aws-iam.application-user-access-secret}"
  }
}

//  Create the ansible variable file for aws secrets.
resource "local_file" "terraform_secret_vars_yml" {
  content     = "${data.template_file.terraform_secret_vars.rendered}"
  filename = "${path.cwd}/terraform_secret_vars.yml"
}

// AWS exposed data
data "template_file" "terraform_exposed_vars" {
  template = "${file("${path.cwd}/terraform_exposed_vars.yml.tpl")}"
  vars = {
    t1_tnode_addresses = "'${aws_instance.t1_tnode_instance_1.private_dns}'"
  }
}

//  Create the ansible variable file for aws secrets.
resource "local_file" "terraform_exposed_vars_yml" {
  content  = "${data.template_file.terraform_exposed_vars.rendered}"
  filename = "${path.cwd}/terraform_exposed_vars.yml"
}
