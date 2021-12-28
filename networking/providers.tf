terraform {
  required_version = ">= 0.12.31"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.28"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "NETWORK"
}


provider "aws" {
  region  = "us-east-1"
  profile = "DEV"
  alias   = "dev"
}

provider "aws" {
  region  = "us-east-1"
  profile = "PROD"
  alias   = "prod"
}