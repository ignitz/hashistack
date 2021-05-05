provider "aws" {
  alias = "hashistack"

  access_key = var.access_key
  secret_key = var.secret_key
  region     = "us-east-1" # Seem reasonable to be hardcoded
}
