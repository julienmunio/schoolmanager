data "archive_file" "lambda_students-list_zip" {
  type        = "zip"
  output_path = ".tmp/lambda-students-list.zip"
  source {
    content  = file("./lambda-students-list.js")
    filename = "index.js"
  }
}
resource "aws_lambda_function" "students-list" {
  function_name    = "${lower(var.project)}-${lower(var.environment)}-students-list"
  filename         = data.archive_file.lambda_students-list_zip.output_path
  source_code_hash = data.archive_file.lambda_students-list_zip.output_base64sha256
  role             = aws_iam_role.lambda_students-list.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  layers = [
    "${data.aws_lambda_layer_version.nodejs_axios.layer_arn}:${data.aws_lambda_layer_version.nodejs_axios.version}"
  ]
  timeout = 5

  environment {
    variables = {
      REGION    = var.region
      NAMESPACE = var.cloudwatch_namespace
    }
  }
}

# # Lambda call from API Gateway
# resource "aws_lambda_permission" "students-list" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.students-list.function_name
#   principal     = "apigateway.amazonaws.com"
#   #source_arn    = "arn:aws:execute-api:${var.region}:${local.account}:${aws_api_gateway_rest_api.main.id}/*/${aws_api_gateway_method.metrics.http_method}${aws_api_gateway_resource.metrics.path}"
#   source_arn = "arn:aws:execute-api:${var.region}:${local.account}:${aws_api_gateway_rest_api.main.id}/*/*"
# }

# IAM
resource "aws_iam_role" "lambda_students-list" {
  name               = "${local.name}-lambda-students-list"
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

resource "aws_iam_policy" "lambda_students-list" {
  name   = "${local.name}-lambda-students-list"
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
          "${aws_cloudwatch_log_group.lambda_students-list.arn}",
          "${aws_cloudwatch_log_group.lambda_students-list.arn}:*"
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

          # "${aws_dynamodb_table.profiles.arn}",
          # "${aws_dynamodb_table.profiles.arn}/*"

resource "aws_iam_role_policy_attachment" "lambda_students-list" {
  role       = aws_iam_role.lambda_students-list.name
  policy_arn = aws_iam_policy.lambda_students-list.arn
}

resource "aws_cloudwatch_log_group" "lambda_students-list" {
  name              = "/aws/lambda/${aws_lambda_function.students-list.function_name}"
  tags              = local.tags
  retention_in_days = 30
}

# # Lambda event source permissions from EventBridge and CloudWatchEvent
# resource "aws_lambda_permission" "metrics_from_cloud_watch" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.metrics.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = "arn:aws:events:${var.region}:${local.account}:rule/*"
# }