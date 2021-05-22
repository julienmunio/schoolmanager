terraform {
  backend "s3" {
    bucket  = "tf-julien-munio"
    key     = "dev/schoolmanager.tfstate"
    region  = "eu-west-1"
    profile = "schoolmanager-tf-dev"
  }
  required_version = "~>0.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.29.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
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

provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "use1"
  region  = "us-east-1"
  profile = var.profile
}
