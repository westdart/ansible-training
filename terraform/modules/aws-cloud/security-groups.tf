//  This security group allows intra-node communication on all ports with all
//  protocols.
//  Security group which allows SSH access to a host.
resource "aws_security_group" "cloud-ssh" {
  name        = "cloud-ssh"
  description = "Security group that allows public ingress over SSH."
  vpc_id      = aws_vpc.cloud.id

  //  SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common-tags
}

//  This security group allows public ingress to the instances for HTTP, HTTPS
//  and common HTTP/S proxy ports.
resource "aws_security_group" "web-public-ingress" {
  name        = "web-public-ingress"
  description = "Security group that allows public ingress to instances, HTTP, HTTPS and more."
  vpc_id      = aws_vpc.cloud.id

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

  tags = var.common-tags
}

//  This security group allows public egress from the instances for HTTP and
//  HTTPS, which is needed for yum updates, git access etc etc.
resource "aws_security_group" "web-public-egress" {
  name        = "web-public-egress"
  description = "Security group that allows egress to the internet for instances over HTTP and HTTPS."
  vpc_id      = aws_vpc.cloud.id

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

  tags = var.common-tags
}
