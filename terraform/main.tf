#https://callaway.dev/deploy-python-lambdas-with-terraform/

locals {
    tags = {
      service_name = "lambdas"
      owner        = "Team"
  }
}


resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r ${var.lambda_root}/requirements.txt -t ${var.lambda_root}/"
  }
  
  triggers = {
    dependencies_versions = filemd5("${var.lambda_root}/requirements.txt")
    source_versions = filemd5("${var.lambda_root}/function.py")
  }
}


resource "random_uuid" "lambda_src_hash" {
  keepers = {
    for filename in setunion(
      fileset(var.lambda_root, "function.py"),
      fileset(var.lambda_root, "requirements.txt")
    ):
        filename => filemd5("${var.lambda_root}/${filename}")
  }
}



data "archive_file" "lambda_source" {
  depends_on = [null_resource.install_dependencies]
  excludes   = [
    "__pycache__",
    "venv",
  ]

  source_dir  = var.lambda_root
  output_path = "${random_uuid.lambda_src_hash.result}.zip"
  type        = "zip"
}


resource "aws_cloudwatch_log_group" "task-creation" {
  name              = "/aws/lambda/${var.lambda_handler}"
  retention_in_days = 1
  lifecycle {
    prevent_destroy = false
  }
}


resource "aws_lambda_function" "lambda" {
  function_name    = "main"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = data.archive_file.lambda_source.output_base64sha256

  handler          = var.lambda_handler
  runtime          = var.lambda_runtime

  environment {
    variables = {
      LOG_LEVEL = var.lambda_log_level
    }
  }

  depends_on    = [
    aws_iam_role_policy_attachment.lambda_execution,
    aws_cloudwatch_log_group.task-creation,
  ]

  reserved_concurrent_executions = var.lambda_concurrent_executions
  tags = local.tags
}

resource "aws_lambda_function_url" "lambda_url" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"
  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}


resource "aws_iam_role" "lambda_role" {
    assume_role_policy = <<EOF
    {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Action": "sts:AssumeRole",
         "Principal": {
           "Service": "lambda.amazonaws.com"
         },
         "Effect": "Allow",
         "Sid": ""
       }
     ]
    }
    EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
 name         = "aws_iam_policy_for_terraform_aws_lambda_role"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
    role        = aws_iam_role.lambda_role.name
    policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}



