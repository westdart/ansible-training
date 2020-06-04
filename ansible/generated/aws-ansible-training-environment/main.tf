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
    "InfraName"         = "ansible-training-1"
    "Owner"             = data.aws_caller_identity.current.arn
    "User"              = data.aws_caller_identity.current.user_id
    "Account"           = data.aws_caller_identity.current.account_id
  }
}

# Create a public key reference in AWS for machines to accept
resource "aws_key_pair" "keypair" {
  key_name   = "ansible-training-1-sshkey"
  public_key = file(var.ssh-public-key-file)
}


# Create VPC and other cloud wide resources
## Setup IAM objects
resource "aws_iam_role" "sts-instance-role" {
  name = "ansible-training-1-sts-instance-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = local.common_tags
}

//  This policy allows an instance to forward logs to CloudWatch, and
//  create the Log Stream or Log Group if it doesn't exist.
resource "aws_iam_policy" "application-policy-forward-logs" {
  name        = "ansible-training-1-instance-forward-logs"
  path        = "/"
  description = "Allows an instance to forward logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

//  Attach the policies to the roles.
resource "aws_iam_policy_attachment" "application-attachment-forward-logs" {
  name       = "ansible-training-1-attachment-forward-logs"
  roles      = [aws_iam_role.sts-instance-role.name]
  policy_arn = aws_iam_policy.application-policy-forward-logs.arn
}

//  Create a instance profile for the role.
resource "aws_iam_instance_profile" "sts-instance-profile" {
  name  = "ansible-training-1-sts-instance-profile"
  role = "${aws_iam_role.sts-instance-role.name}"
}

//  Create a user and access key for application-only permissions
resource "aws_iam_user" "application-aws-user" {
  name = "ansible-training-1-aws-user"
  path = "/"

  tags = local.common_tags
}

//  Policy taken from https://github.com/openshift/openshift-ansible-contrib/blob/9a6a546581983ee0236f621ae8984aa9dfea8b6e/reference-architecture/aws-ansible/playbooks/roles/cloudformation-infra/files/greenfield.json.j2#L844
resource "aws_iam_user_policy" "application-aws-user" {
  name = "ansible-training-1-aws-user-policy"
  user = aws_iam_user.application-aws-user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVolume*",
        "ec2:CreateVolume",
        "ec2:CreateTags",
        "ec2:DescribeInstance*",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:DeleteVolume",
        "ec2:DescribeSubnets",
        "ec2:CreateSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeRouteTables",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:CreateLoadBalancerListeners",
        "elasticloadbalancing:ConfigureHealthCheck",
        "elasticloadbalancing:DeleteLoadBalancerListeners",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:DescribeLoadBalancerAttributes"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "application-aws-user" {
  user    = aws_iam_user.application-aws-user.name
}

## Create VPC
resource "aws_vpc" "cloud" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = merge(
    local.common_tags,
    map(
      "Name", "ansible-training-1"
    )
  )
}

locals {
  vpc_id = aws_vpc.cloud.id
}

## Add Network resources
// TODO: review - Create an Internet Gateway for the VPC.
resource "aws_internet_gateway" "default_gateway" {
  vpc_id = local.vpc_id
  tags   = local.common_tags
}

// TODO: review - Create a route table allowing all addresses access to the IGW.
resource "aws_route_table" "public_route" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_gateway.id
  }
  tags = local.common_tags
}

## Add Security Groups
// TODO - refactor all this into the 'custom' security groups - i.e. make it all data defined
//  This security group allows intra-node communication on all ports with all
//  protocols.
//  Security group which allows SSH access to a host.
resource "aws_security_group" "cloud-ssh" {
  name        = "cloud-ssh"
  description = "Security group that allows public ingress over SSH."
  vpc_id      = local.vpc_id

  //  SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

//  This security group allows public ingress to the instances for HTTP, HTTPS
//  and common HTTP/S proxy ports.
resource "aws_security_group" "web-public-ingress" {
  name        = "web-public-ingress"
  description = "Security group that allows public ingress to instances, HTTP, HTTPS and more."
  vpc_id      = local.vpc_id

  //  HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //  HTTP Proxy
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //  HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //  HTTPS Proxy
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

//  This security group allows public egress from the instances for HTTP and
//  HTTPS, which is needed for yum updates, git access etc etc.
resource "aws_security_group" "web-public-egress" {
  name        = "web-public-egress"
  description = "Security group that allows egress to the internet for instances over HTTP and HTTPS."
  vpc_id      = local.vpc_id

  //  HTTP
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //  HTTPS
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}



 
# Create environment subnets and route table associations
resource "aws_subnet" "t1_public_subnet" {
  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
  depends_on              = ["aws_vpc.cloud"]
  tags = merge(
    local.common_tags,
    map(
      "Name", "t1-default-public-subnet",
      "Type", "Public",
      "infra_name", "ansible-training-1"
    )
  )
}
resource "aws_route_table_association" "t1_public_subnet_asoc" {
  subnet_id      = aws_subnet.t1_public_subnet.id
  route_table_id = aws_route_table.public_route.id
}



# Create custom security groups
resource "aws_security_group" "ansible-training-1_security_group" {
  name        = "ansible-training-1_security_group"
  description = "Network rules for ansible-training-1 env"
  vpc_id      = local.vpc_id

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
    cidr_blocks = []
  }

  ingress {
    from_port = "0"
    to_port   = "22"
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
    cidr_blocks = []
  }

  tags = merge(
           local.common_tags,
           map(
             "Name", "ansible-training-1_security_group",
             "infra_name", "ansible-training-1"
           )
         )
}


# Establish AMIs to use
# Find the AMI by:
# Account, Latest, x86_64, EBS, HVM, OS Name
data "aws_ami" "rhel_7_7_aws_ami" {
  most_recent = true

  owners = ["309956199498"]

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
    values = ["RHEL-7.7*"]
  }
}

# Establish AMIs to use
# Find the AMI by:
# Account, Latest, x86_64, EBS, HVM, OS Name
data "aws_ami" "rhel_8_2_aws_ami" {
  most_recent = true

  owners = ["309956199498"]

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
    values = ["RHEL-8.2*"]
  }
}

# Establish AMIs to use
# Find the AMI by:
# Account, Latest, x86_64, EBS, HVM, OS Name
data "aws_ami" "centos_7_aws_ami" {
  most_recent = true

  owners = ["679593333241"]

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
    values = ["CentOS7*"]
  }
}




# Create all environment nodes

resource "aws_instance" "t1_tnode_instance_1" {
  ami                    = data.aws_ami.rhel_7_7_aws_ami.id
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.sts-instance-profile.id
  subnet_id              = aws_subnet.t1_public_subnet.id
  vpc_security_group_ids = [aws_security_group.cloud-ssh.id,aws_security_group.web-public-ingress.id,aws_security_group.web-public-egress.id,
                            ]
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
  ami                    = data.aws_ami.rhel_7_7_aws_ami.id
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.sts-instance-profile.id
  subnet_id              = aws_subnet.t1_public_subnet.id
  vpc_security_group_ids = [aws_security_group.cloud-ssh.id,aws_security_group.web-public-ingress.id,aws_security_group.web-public-egress.id,
                            ]
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
  ami                    = data.aws_ami.rhel_7_7_aws_ami.id
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.sts-instance-profile.id
  subnet_id              = aws_subnet.t1_public_subnet.id
  vpc_security_group_ids = [aws_security_group.cloud-ssh.id,aws_security_group.web-public-ingress.id,aws_security_group.web-public-egress.id,
                            ]
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




