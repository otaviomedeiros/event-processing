terraform {
  backend "s3" {
    bucket         = "terraform-event-processing-state"
    key            = "stage/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-event-processing-state-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

locals {
  env = "stage"
}

module "sqs" {
  source = "../modules/sqs"
  env = local.env
}

# module "api_gateway" {
#   source = "../modules/api_gateway"
#   env    = local.env
#   region = var.region
#   queue  = module.sqs.queue
# }

# module "lambda_function" {
#   source = "../modules/lambda"
#   env    = local.env
#   queue  = module.sqs.queue 
# }