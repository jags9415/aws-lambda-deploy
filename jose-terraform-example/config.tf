provider "aws" {
  profile    = "development"
  region     = "us-east-1"
}

resource "aws_lambda_function" "hello-world" {
  function_name = "hello-world"
  filename      = "bin/hello-world.zip"
  handler       = "hello-world"
  source_code_hash = filebase64sha256("bin/hello-world.zip")
  runtime = "go1.x"
  role = aws_iam_role.hello-world.arn
}

resource "aws_iam_role" "hello-world" {
  name = "hello-world"

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

resource "aws_lambda_permission" "hello-world" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello-world.arn
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  # source_arn = "${aws_api_gateway_rest_api.hello-world.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "hello-world" {
  name              = "/aws/lambda/${aws_lambda_function.hello-world.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "hello-world" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

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

resource "aws_iam_role_policy_attachment" "hello-world" {
  role       = aws_iam_role.hello-world.name
  policy_arn = aws_iam_policy.hello-world.arn
}

resource "aws_api_gateway_rest_api" "hello-world" {
  name        = "jose_terraform_example_rest_api"
}

resource "aws_api_gateway_resource" "hello-world" {
  rest_api_id = aws_api_gateway_rest_api.hello-world.id
  parent_id   = aws_api_gateway_rest_api.hello-world.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "hello-world" {
  rest_api_id   = aws_api_gateway_rest_api.hello-world.id
  resource_id   = aws_api_gateway_resource.hello-world.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "hello-world" {
  rest_api_id = aws_api_gateway_rest_api.hello-world.id
  resource_id = aws_api_gateway_resource.hello-world.id
  http_method = aws_api_gateway_method.hello-world.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello-world.invoke_arn
}

resource "aws_api_gateway_deployment" "hello-world" {
  depends_on = [
    aws_api_gateway_integration.hello-world
  ]

  rest_api_id = aws_api_gateway_rest_api.hello-world.id
  stage_name  = "v1"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.hello-world.invoke_url}${aws_api_gateway_resource.hello-world.path}"
}

output "lambda_url" {
  value = aws_lambda_function.hello-world.invoke_arn
}
