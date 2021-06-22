resource "aws_api_gateway_resource" "metrics" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.root.id
  path_part   = "metric"
}

resource "aws_api_gateway_method" "metrics" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.metrics.id
  http_method      = "GET"
  authorization    = "NONE"
  # api_key_required = true
}

resource "aws_api_gateway_integration" "metrics" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.metrics.id
  http_method             = aws_api_gateway_method.metrics.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.metrics.invoke_arn
}