//  Create a Virtual Private Cloud.
resource "aws_vpc" "cloud" {
  cidr_block           = var.cloud_cidr
  enable_dns_hostnames = true
  tags = merge(
    var.common-tags,
    map(
      "Name", var.cloud_name
    )
  )
}
