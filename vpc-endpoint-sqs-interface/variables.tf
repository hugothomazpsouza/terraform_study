variable default_public_ingress {
  description = "Ingress rules related to the Public SG"
  type = map(object({protocol = string, description = string, cidr_blocks = list(string)}))
  default = {
    22 = { protocol = "tcp", description = "Inbound para SSH", cidr_blocks = [ "0.0.0.0/0" ] }
  }
}

variable default_private_ingress {
  description = "Ingress rules related to the Private SG"
  type = map(object({protocol = string, description = string, cidr_blocks = list(string)}))
  default = {
    22 = { protocol = "tcp", description = "Inbound para SSH", cidr_blocks = [ "0.0.0.0/0" ] }
  }
}

variable "default_public_egress" {
  description = "Egress rules related to the Public SG"
  type = map(object({protocol = string, description = string, cidr_blocks = list(string)}))
  default = {
    0 = { protocol = "-1", description = "All Outbound traffic allow", cidr_blocks = [ "0.0.0.0/0" ] }
  }
}

variable "default_private_egress" {
  description = "Egress rules related to the Private SG"
  type = map(object({protocol = string, description = string, cidr_blocks = list(string)}))
  default = {
    0 = { protocol = "-1", description = "All Outbound traffic allow", cidr_blocks = [ "0.0.0.0/0" ] }
  }
}
