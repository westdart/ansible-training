variable "instances" {
  description = "List of aws_instances"
  type = "list"
  default = []
}

variable "zone-domain" {
  description = "Domain for the zone"
}

variable "name" {
  description = "Descriptive (multi word) name for the zone"
}

variable "vpc-id" {
  description = "ID to the vpc to use"
}

variable "common-tags" {
  description = "Common tags to be applied to resources"
  type = "map"
  default = {}
}
