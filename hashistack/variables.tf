variable "company" {
  type        = string
  description = "Company name to concat with resource's name."
}

variable "environment" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "ssh_key_name" {
  type    = string
  default = null
}

variable "amis" {
  type = map(string)
}
