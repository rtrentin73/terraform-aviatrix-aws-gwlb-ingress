terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    aviatrix = {
      source = "AviatrixSystems/aviatrix"
      version = "2.21.1-6.6.ga"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}