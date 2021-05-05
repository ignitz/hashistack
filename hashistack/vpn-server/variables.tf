variable "instance_name" {
  description = "Instance Name"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment of the deploy. Ex. DEV, STAGING, TEST"
  type        = string
}

variable "ami_id" {
  description = "The ID of the AMI to run Airflow's stack!"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to attach into the machines"
  type        = map(string)
  default     = {}
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances."
  default     = null
}

variable "instance_type" {
  description = "Instance type of EC2."
  default     = "t2.micro"
}

variable "cluster_tag_key" {
  description = "Add a tag with this key and the value var.cluster_name to each Instance in the ASG."
}

variable "cluster_tag_value" {
  description = "Consul cluster name."
}

variable "subnet_tags" {
  description = "Tags used to find subnets for vault and consul servers"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Tags used to find a vpc for building resources in"
  type        = map(string)
  default     = {}
}

variable "use_default_vpc" {
  description = "Whether to use the default VPC - NOT recommended for production! - should more likely change this to false and use the vpc_tags to find your vpc"
  type        = bool
  default     = false
}
