data "archive_file" "lambda_metrics_zip" {
  type        = "zip"
  output_path = ".tmp/lambda-metrics.zip"
  source {
    content  = file("./lambda-metrics.js")
    filename = "index.js"
  }
}

resource "aws_lambda_function" "metrics" {
  function_name    = "${local.name}-metrics"
  filename         = data.archive_file.lambda_metrics_zip.output_path
  source_code_hash = data.archive_file.lambda_metrics_zip.output_base64sha256
  role             = aws_iam_role.lambda_metrics.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  memory_size      = 128
  layers = [
    "${data.aws_lambda_layer_version.nodejs.layer_arn}:${data.aws_lambda_layer_version.nodejs.version}"
  ]
  timeout = 5

  environment {
    variables = {
      REGION      = var.region
      TABLE       = aws_dynamodb_table.classroom.name
      NAMESPACE   = var.cloudwatch_namespace
    }
  }
}
resource "aws_lambda_permission" "metrics" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metrics.function_name
  principal     = "apigateway.amazonaws.com"
  #source_arn    = "arn:aws:execute-api:${var.region}:${local.account}:${aws_api_gateway_rest_api.main.id}/*/${aws_api_gateway_method.metrics.http_method}${aws_api_gateway_resource.metrics.path}"
  source_arn = "arn:aws:execute-api:${var.region}:${local.account}:${aws_api_gateway_rest_api.main.id}/*/*"
}

# resource "aws_lambda_permission" "metrics_from_cloud_watch" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.metrics.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = "arn:aws:events:${var.region}:${local.account}:rule/*"
# }

# IAM
resource "aws_iam_role" "lambda_metrics" {
  name               = "${local.name}-lambda-metrics"
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "lambda_metrics" {
  name   = "${local.name}-lambda-metrics"
  path   = "/"
  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:GetItem"
      ],
      "Resource": [
          "${aws_cloudwatch_log_group.lambda_metrics.arn}",
          "${aws_cloudwatch_log_group.lambda_metrics.arn}:*",
          "${aws_dynamodb_table.classroom.arn}",
          "${aws_dynamodb_table.classroom.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:GetMetricData",
        "cloudwatch:getMetricStatistics"
      ],
      "Resource": [
          "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_metrics" {
  role       = aws_iam_role.lambda_metrics.name
  policy_arn = aws_iam_policy.lambda_metrics.arn
}

resource "aws_cloudwatch_log_group" "lambda_metrics" {
  name              = "/aws/lambda/${aws_lambda_function.metrics.function_name}"
  tags              = local.tags
  retention_in_days = 30
}
