terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create Private Subnet
resource "aws_subnet" "main" {
  vpc_id     = "vpc-0de2bfe0f5fc540e0"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}
# Creating NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = "nat-07863fc48f5b99110"
  subnet_id     = aws_subnet.main.id

  tags = {
    Name = "gw NAT"
  }
}

#Creating Routing Table
data "aws_route_table" "route_table" {
  subnet_id = aws_subnet.main.id
}

# Creating Lambda Role with IAM Lambda Policy
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "DevOps-Candidate-Lambda-Role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.js"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.lambda.assume_role_policy
  handler       = "index.test"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs16.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}
