# Ansible managed

# Setup the core provider information.
provider "aws" {
  region  = var.region
}

# Obtain information on the execution agent (person)
data "aws_caller_identity" "current" {}

# Setup common tags to be set against created resources
locals {
  # Common tags to be assigned to all resources
  common_tags = {
    "InfraName"         = "k1"
    "Owner"             = data.aws_caller_identity.current.arn
    "User"              = data.aws_caller_identity.current.user_id
    "Account"           = data.aws_caller_identity.current.account_id
  }
}

# Create a public key reference in AWS for machines to accept
resource "aws_key_pair" "keypair" {
  key_name   = "k1-sshkey"
  public_key = file(var.ssh-public-key-file)
}

# Setup IAM objects
module "aws-iam" {
  source      = "/home/davids/code/westdart/ansible_roles/ar_aws_infra/files/terraform/modules/aws-iam"
  name        = "k1"
  prefix      = "k1-"
  common-tags = local.common_tags
}

# Create VPC and other cloud wide resources
module "aws-cloud2" {
  source         = "/home/davids/code/westdart/ansible_roles/ar_aws_infra/files/terraform/modules/aws-cloud2"
  cloud_cidr     = "10.0.0.0/16"
  cloud_name     = "k1"
  common-tags    = local.common_tags
}


 
locals {
  vpc_id = module.aws-cloud2.vpc-id
}

# Create subnets and route table associations
resource "aws_subnet" "k1-public-subnet" {
  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
  depends_on              = ["module.aws-cloud2"]
  tags = merge(
    local.common_tags,
    map(
      "Name", "k1-public-subnet",
      "Type", "Public",
      "infra_name", "k1"
    )
  )
}

resource "aws_route_table_association" "k1-public-subnet_asoc" {
  subnet_id      = aws_subnet.k1-public-subnet.id
  route_table_id = module.aws-cloud2.public_route_id
}

 
resource "aws_subnet" "k1-private-subnet" {
  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2a"
  depends_on              = ["module.aws-cloud2"]
  tags = merge(
    local.common_tags,
    map(
      "Name", "k1-private-subnet",
      "Type", "Private",
      "infra_name", "k1"
    )
  )
}

resource "aws_route_table_association" "k1-private-subnet_asoc" {
  subnet_id      = aws_subnet.k1-private-subnet.id
  route_table_id = module.aws-cloud2.public_route_id
}

resource "aws_eip" "k1-private-subnet_nat_gw_ip" {
  vpc = true
}

resource "aws_nat_gateway" "k1-private-subnet_nat_gw" {
  allocation_id = aws_eip.k1-private-subnet_nat_gw_ip.id
  subnet_id     = aws_subnet.k1-private-subnet.id

  tags = {
    Name = "k1 - k1-private-subnet NAT GW"
  }
}
 
 

# Create custom security groups
resource "aws_security_group" "default_group" {
  name        = "default_group"
  description = "Default rules for k1 env"
  vpc_id      = local.vpc_id

  ingress {
    from_port = "22"
    to_port   = "22"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "Server maintenance"
  }

  ingress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "Default web access"
  }

  ingress {
    from_port = "443"
    to_port   = "443"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "Default secure web access"
  }

 
  egress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "Default web services"
  }

  egress {
    from_port = "443"
    to_port   = "443"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "Default secure web services"
  }

   tags = merge(
           local.common_tags,
           map(
             "Name", "default_group",
             "infra_name", "k1"
           )
         )
}

resource "aws_security_group" "control_group" {
  name        = "control_group"
  description = "Kube Control Group"
  vpc_id      = local.vpc_id

  ingress {
    from_port = "6443"
    to_port   = "6443"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API server"
  }

  ingress {
    from_port = "2379"
    to_port   = "2380"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "etcd server client API"
  }

  ingress {
    from_port = "10250"
    to_port   = "10250"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubelet API"
  }

  ingress {
    from_port = "10251"
    to_port   = "10251"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "kube-scheduler"
  }

  ingress {
    from_port = "10252"
    to_port   = "10252"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "kube-controller-manager"
  }

 
   tags = merge(
           local.common_tags,
           map(
             "Name", "control_group",
             "infra_name", "k1"
           )
         )
}

resource "aws_security_group" "worker_group" {
  name        = "worker_group"
  description = "Kube Worker Group"
  vpc_id      = local.vpc_id

  ingress {
    from_port = "10250"
    to_port   = "10250"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubelet API"
  }

  ingress {
    from_port = "30000"
    to_port   = "32767"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort Services"
  }

 
   tags = merge(
           local.common_tags,
           map(
             "Name", "worker_group",
             "infra_name", "k1"
           )
         )
}

 
# Establish AMIs to use
module "rhel_7_8-images" {
  source      = "/home/davids/code/westdart/ansible_roles/ar_aws_infra/files/terraform/modules/aws-images"
  account_num = "309956199498"
  os_name = "RHEL-7.8*"
}
# Establish AMIs to use
module "rhel_8_2-images" {
  source      = "/home/davids/code/westdart/ansible_roles/ar_aws_infra/files/terraform/modules/aws-images"
  account_num = "309956199498"
  os_name = "RHEL-8.2*"
}
 


# Create all nodes

resource "aws_instance" "k1_kubectrl_instance_1" {
  ami                    = module.rhel_7_8-images.ami_id
  instance_type          = "t2.micro"
  iam_instance_profile   = module.aws-iam.sts-instance-profile-id
  subnet_id              = aws_subnet.k1-public-subnet.id
  vpc_security_group_ids = [aws_security_group.default_group.id,aws_security_group.control_group.id]
  key_name               = "k1-sshkey"

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }


  tags = merge(
    local.common_tags,
    map(
      "Name", "kubectrl.localdomain"
    )
  )
}


 

resource "aws_instance" "k1_kubework_instance_1" {
  ami                    = module.rhel_7_8-images.ami_id
  instance_type          = "t2.micro"
  iam_instance_profile   = module.aws-iam.sts-instance-profile-id
  subnet_id              = aws_subnet.k1-private-subnet.id
  vpc_security_group_ids = [aws_security_group.default_group.id,aws_security_group.worker_group.id]
  key_name               = "k1-sshkey"

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }


  tags = merge(
    local.common_tags,
    map(
      "Name", "kubework.localdomain"
    )
  )
}


 
 
