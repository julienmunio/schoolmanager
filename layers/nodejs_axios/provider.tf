terraform {
  backend s3 {}
  required_version = "~>0.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.28.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.0.0"
    }
  }
}
provider aws {
  region  = var.region
  profile = var.profile
}
