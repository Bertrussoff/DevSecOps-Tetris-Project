terraform {
  backend "s3" {
    bucket       = "dev-bert-tf-bucket"
    region       = "us-east-1"
    key          = "DevSecOps-Tetris-Project/Jenkins-Server-TF/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
  required_version = ">=1.13.3"
  required_providers {
    aws = {
      version = ">= 6.23.0"
      source  = "hashicorp/aws"
    }
  }
}