terraform {
    required_version = ">= 1.4.5"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.0"
        }
    }

    backend "s3" {
        region  = "ap-northeast-2"
        bucket  = "" # tf state bucket name
        key =    "dev/demo/terraform.tfstate" # s3 key
        profile = "dev"
    }
}

provider "aws" {
  region = "ap-northeast-2"
  
  profile = "dev"
#   assume_role {
#     role_arn     = "arn:aws:iam::123456789012:role/ROLE_NAME"
#     session_name = "SESSION_NAME"
#     external_id  = "EXTERNAL_ID"
#   }

}
