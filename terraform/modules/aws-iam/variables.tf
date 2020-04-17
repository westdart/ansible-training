variable "name" {
  description = "Name of the project"
}

variable "prefix" {
  description = "Prefix for the resources (enables multiple instances to be created)"
  default = ""
}

variable "common-tags" {
  description = "Common tags to be applied to resources"
  type = "map"
  default = {}
}
