terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"

    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket       = "20251028-terraform-state-bucket"
    key          = "envs/aws/terraform.tfstate" # path in bucket
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true

  }
}
