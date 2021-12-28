terraform {
  required_version = ">= 0.12.26"

  required_providers {
    aws = ">= 3.15.0"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "NETWORK"
}