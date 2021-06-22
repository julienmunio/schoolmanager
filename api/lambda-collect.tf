data "archive_file" "lambda_collect_zip" {
  type        = "zip"
  output_path = ".tmp/lambda-collect.zip"
  source {
    content  = file("./lambda-collect.js")
    filename = "index.js"
  }
}

resource "aws_lambda_function" "collect" {
  function_name    = "${local.name}-collect"
  filename         = data.archive_file.lambda_collect_zip.output_path
  source_code_hash = data.archive_file.lambda_collect_zip.output_base64sha256
  role             = aws_iam_role.lambda_collect.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  memory_size      = 128
  layers = [
    "${data.aws_lambda_layer_version.nodejs.layer_arn}:${data.aws_lambda_layer_version.nodejs.version}",
    "${data.aws_lambda_layer_version.mongodb.layer_arn}:${data.aws_lambda_layer_version.mongodb.version}"
  ]
  timeout = 300
  environment {
    variables = {
      REGION      = var.region
      TABLE       = aws_dynamodb_table.classroom.name
      # MONGODB_URI = var.mongo_uri
      NAMESPACE   = var.cloudwatch_namespace
    }
  }
}
resource "aws_lambda_permission" "collect" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.collect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${local.account}:${aws_api_gateway_rest_api.main.id}/*/*"
}


# IAM
resource "aws_iam_role" "lambda_collect" {
  name               = "${local.name}-lambda-collect"
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

resource "aws_iam_policy" "lambda_collect" {
  name   = "${local.name}-lambda-collect"
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
        "dynamodb:GetItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": [
          "${aws_cloudwatch_log_group.lambda_collect.arn}",
          "${aws_cloudwatch_log_group.lambda_collect.arn}:*",
          "${aws_dynamodb_table.classroom.arn}",
          "${aws_dynamodb_table.classroom.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": [
          "*"
      ],
      "Condition": {
        "StringEquals": {
            "cloudwatch:namespace": "${var.cloudwatch_namespace}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_collect" {
  role       = aws_iam_role.lambda_collect.name
  policy_arn = aws_iam_policy.lambda_collect.arn
}

resource "aws_cloudwatch_log_group" "lambda_collect" {
  name              = "/aws/lambda/${aws_lambda_function.collect.function_name}"
  tags              = local.tags
  retention_in_days = 30
}