//  Notes: We could make the internal domain a variable, but not sure it is
//  really necessary.

//  Create the internal DNS.
resource "aws_route53_zone" "internal" {
  name = var.zone-domain
  comment = var.name
  vpc {
    vpc_id = var.vpc-id
  }

  tags = merge(
    var.common-tags,
    map(
      "Name", var.name
    )
  )
}
