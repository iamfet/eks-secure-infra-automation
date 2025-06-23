terraform {
  backend "s3" {
    bucket       = "state-eks-secure-infra-automation"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true                              # Enable S3 native state locking, remove if using DynamoDB for state locking
    /*dynamodb_table = "terraform-eks-state-locks"*/ # Uncomment if using DynamoDB for state locking
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.99"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}