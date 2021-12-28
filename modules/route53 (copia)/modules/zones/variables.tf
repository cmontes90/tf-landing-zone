variable "create_zone" {
  description = "Whether to create Route53 zone"
  type        = bool
  default     = true
}

variable "create_vpc_association_authorization" {
  description = "Whether to create authorization for vpcs to associate to the route 53 zone "
  type        = bool
  default     = false

}

variable "create_vpc_association" {
  description = "Whether to create for vpcs to association to a an existing route 53 zone "
  type        = bool
  default     = false
}

variable "zones" {
  description = "Map of Route53 zone parameters"
  type        = any
  default     = {}
}

variable "vpc_associations" {
  description = "A list of vpcs to associate to a Route 53 zone"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "ID of an existing Route 53 zone id"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags added to all zones. Will take precedence over tags from the 'zones' variable"
  type        = map(any)
  default     = {}
}
