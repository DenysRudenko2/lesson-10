terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    bucket       = "mlops-tfstate-rudenko-152128592418"
    key          = "lesson-10/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "mlops-train-automation"
      ManagedBy = "terraform"
      Lesson    = "10"
    }
  }
}

data "aws_caller_identity" "current" {}

# ───────────────────────── Lambda packaging ─────────────────────────
# Terraform сам пакує .py у .zip (output_path збігається зі структурою репо).
data "archive_file" "validate" {
  type        = "zip"
  source_file = "${path.module}/lambda/validate.py"
  output_path = "${path.module}/lambda/validate.zip"
}

data "archive_file" "log_metrics" {
  type        = "zip"
  source_file = "${path.module}/lambda/log_metrics.py"
  output_path = "${path.module}/lambda/log_metrics.zip"
}

# ───────────────────────── IAM: Lambda ─────────────────────────
resource "aws_iam_role" "lambda" {
  name = "${var.project}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ───────────────────────── Lambda functions ─────────────────────────
resource "aws_lambda_function" "validate" {
  function_name    = "${var.project}-validate"
  filename         = data.archive_file.validate.output_path
  source_code_hash = data.archive_file.validate.output_base64sha256
  handler          = "validate.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda.arn
  timeout          = 30
}

resource "aws_lambda_function" "log_metrics" {
  function_name    = "${var.project}-log-metrics"
  filename         = data.archive_file.log_metrics.output_path
  source_code_hash = data.archive_file.log_metrics.output_base64sha256
  handler          = "log_metrics.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda.arn
  timeout          = 30
}

# ───────────────────────── IAM: Step Function ─────────────────────────
resource "aws_iam_role" "sfn" {
  name = "${var.project}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sfn_invoke_lambda" {
  name = "${var.project}-sfn-invoke-lambda"
  role = aws_iam_role.sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["lambda:InvokeFunction"]
      Resource = [
        aws_lambda_function.validate.arn,
        aws_lambda_function.log_metrics.arn,
      ]
    }]
  })
}

# ───────────────────────── Step Function ─────────────────────────
resource "aws_sfn_state_machine" "train_pipeline" {
  name     = "${var.project}-pipeline"
  role_arn = aws_iam_role.sfn.arn

  definition = jsonencode({
    Comment = "ML training pipeline: validate data, then log metrics"
    StartAt = "ValidateData"
    States = {
      ValidateData = {
        Type     = "Task"
        Resource = aws_lambda_function.validate.arn
        Next     = "LogMetrics"
      }
      LogMetrics = {
        Type     = "Task"
        Resource = aws_lambda_function.log_metrics.arn
        End      = true
      }
    }
  })
}

# ───────────────────────── Outputs ─────────────────────────
output "state_machine_arn" {
  description = "ARN of the Step Function (для GitLab CI / start-execution)"
  value       = aws_sfn_state_machine.train_pipeline.arn
}

output "validate_lambda_arn" {
  value = aws_lambda_function.validate.arn
}

output "log_metrics_lambda_arn" {
  value = aws_lambda_function.log_metrics.arn
}
