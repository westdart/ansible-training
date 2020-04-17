variable "cloud_name" {
  description = "The short definition for the cloud."
}

variable "cloud_cidr" {
  description = "The CIDR block for the VPC, e.g: 10.0.0.0/16"
  type = "string"
  default = "10.0.0.0/16"
}

variable "common-tags" {
  description = "Common tags to be applied to resources"
  type = "map"
  default = {}
}
