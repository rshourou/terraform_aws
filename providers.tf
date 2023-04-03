terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "roya"

    workspaces {
      name = "getting-started"
    }
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "Credentials"
}