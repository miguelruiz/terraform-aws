terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = "sa-east-1"
  access_key = "AKIAXYKJXQP6OZ7UJGS3"
}
