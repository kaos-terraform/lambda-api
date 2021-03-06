provider "aws" {
  region = var.region
}

provider "archive" {
  version = "~> 1.3"
}

# Convert source directory to a zip file and upload to S3 bucket
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source
  output_path = "${var.zip_destination}/${var.domain}.${var.service}.${var.environment}.zip"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.domain}-${var.service}-${var.environment}-lambda-api"
  acl    = "private"

  tags = {
    Domain      = var.domain
    Environment = var.environment
    Service     = var.service
  }
}

resource "aws_s3_bucket_object" "lambda" {
  bucket  = aws_s3_bucket.bucket.bucket
  key     = "lambda-source-zip"
  source  = data.archive_file.lambda_zip.output_path
  etag    = filemd5(data.archive_file.lambda_zip.output_path)

  depends_on  = [data.archive_file.lambda_zip]

  tags = {
    Domain      = var.domain
    Environment = var.environment
    Service     = var.service
  }
}



# Define up API Gateway Resource
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.domain}-${var.service}-${var.environment}-rest-api"

  tags = {
    Domain      = var.domain
    Environment = var.environment
    Service     = var.service
  }
}

resource "aws_lambda_function" "lambda" {
  function_name = "${var.domain}-${var.service}-${var.environment}"
  s3_bucket = aws_s3_bucket_object.lambda.bucket
  s3_key    = aws_s3_bucket_object.lambda.key
  handler = var.lambda_handler_name
  runtime = "nodejs${var.node_runtime}"
  role = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  tags = {
    Domain      = var.domain
    Environment = var.environment
    Service     = var.service
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "${var.domain}-${var.service}-${var.environment}-iam"

  tags = {
    Domain      = var.domain
    Environment = var.environment
    Service     = var.service
  }

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        Action: "sts:AssumeRole",
        Principal: {
          Service: "lambda.amazonaws.com"
        },
        Effect: "Allow",
        Sid: ""
      }
    ]
  })
}

# Give access to write logs to cloudwatch
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda-logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "arn:aws:logs:*:*:*",
        Effect: "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# Handle requests to non-root path. Handles /*
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# Handle request to root path: /
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# Expose API publicly
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.environment

  count       = var.public ? 1 : 0
}

# Give API gateway access to run this lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# To use custom domain name the following resources must be configured
# resource "aws_api_gateway_domain_name"
# resource "aws_api_gateway_base_path_mapping"
# resource "aws_route53_record"
