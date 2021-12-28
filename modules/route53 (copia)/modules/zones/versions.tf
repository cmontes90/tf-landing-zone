terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = ">= 2.49"
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
