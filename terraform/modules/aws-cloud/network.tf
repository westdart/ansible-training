// TODO: review - Create an Internet Gateway for the VPC.
resource "aws_internet_gateway" "default_gateway" {
  vpc_id = aws_vpc.cloud.id
  tags   = var.common-tags
}

// TODO: review - Create a route table allowing all addresses access to the IGW.
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.cloud.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_gateway.id
  }
  tags = var.common-tags
}
