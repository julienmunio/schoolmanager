locals {
  agw_stage = lower(var.environment)
  #dns_api       = "admin.${var.dns_zone}"
  dns_api = "${aws_api_gateway_rest_api.main.id}.execute-api.${var.region}.amazonaws.com"
}

resource "aws_api_gateway_rest_api" "main" {
  name = local.name
  tags = local.tags
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  # api_key_source = "HEADER"
  # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api
}

#module "acm_api" {
#  source = "./acm"
#  dns    = "api.${local.dns_api}"
#  tags   = local.tags
#  providers = {
#    aws.default = aws
#    aws.use1    = aws.use1
#  }
#  name        = local.name
#  environment = local.agw_stage
#  zone_id     = aws_route53_zone.main.zone_id
#}

#resource "aws_route53_record" "api" {
#  name    = aws_api_gateway_domain_name.main.domain_name
#  type    = "A"
#  zone_id = aws_route53_zone.main.zone_id
#  alias {
#    evaluate_target_health = true
#    name                   = aws_api_gateway_domain_name.main.cloudfront_domain_name
#    zone_id                = aws_api_gateway_domain_name.main.cloudfront_zone_id
#  }
#}
#
#resource "aws_api_gateway_domain_name" "main" {
#  certificate_arn = module.acm_api.certificate_arn
#  domain_name     = module.acm_api.dns
#}

resource "aws_cloudwatch_log_group" "main" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.main.id}/${local.agw_stage}"
  retention_in_days = 14
}

resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = local.agw_stage
  method_path = "${aws_api_gateway_resource.events.path_part}/${aws_api_gateway_method.events.http_method}"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
  depends_on = [aws_cloudwatch_log_group.main, aws_iam_role_policy.api, aws_api_gateway_account.main]
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = local.agw_stage
  lifecycle {
    create_before_destroy = true
  }
  triggers = {
    redeployment = sha1(join(",", tolist(
      [jsonencode(aws_api_gateway_integration.events), ]
    )))
  }
}

#resource "aws_api_gateway_base_path_mapping" "main" {
#  api_id      = aws_api_gateway_rest_api.main.id
#  stage_name  = local.agw_stage
#  domain_name = aws_api_gateway_domain_name.main.domain_name
#}

# API KEY

# resource "aws_api_gateway_usage_plan" "main" {
#   name = local.name
#   tags = local.tags

#   api_stages {
#     api_id = aws_api_gateway_rest_api.main.id
#     stage  = local.agw_stage
#   }
# }

# resource "aws_api_gateway_usage_plan_key" "main" {
#   key_id        = aws_api_gateway_api_key.main.id
#   key_type      = "API_KEY"
#   usage_plan_id = aws_api_gateway_usage_plan.main.id
# }

# resource "aws_api_gateway_api_key" "main" {
#   name = local.name
#   tags = local.tags
# }

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

// Events
resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.root.id
  path_part   = "event"
}

resource "aws_api_gateway_method" "events" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.events.id
  http_method      = "GET"
  authorization    = "NONE"
  # api_key_required = true
}

resource "aws_api_gateway_integration" "events" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.events.id
  http_method             = aws_api_gateway_method.events.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.collect.invoke_arn
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api.arn
}

resource "aws_iam_role" "api" {
  name               = "${local.name}-api_gateway_cloudwatch_global"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "api" {
  name   = "${local.name}-api_gateway_cloudwatch_global"
  role   = aws_iam_role.api.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
