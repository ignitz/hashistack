variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "region" {
  type = string
}

#################################################################
# Hashistack's environment variables
#################################################################

variable "hashistack" {
  type = object({
    vpc_name = string
    amis     = map(string)

    ssh_key_name = string
  })
}
