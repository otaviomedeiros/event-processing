terraform {
  backend "s3" {
    bucket         = "terraform-event-processing-state"
    key            = "prod/terraform.tfstate"
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
  env = "prod"
}

module "sqs" {
  source = "../../modules/sqs"
  env    = local.env
}

# module "api_gateway" {
#   source = "../modules/api_gateway"
#   env    = local.env
#   region = var.region
#   queue  = module.sqs.queue
# }


# module "lambda_function" {
#   source = "./lambda"

#   queue  = aws_sqs_queue.queue 
# }