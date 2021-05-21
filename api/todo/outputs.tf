output "website" {
  value = "https://${aws_cloudfront_distribution.main.domain_name}/"
}

output "api_gateway" {
  value = "https://${local.dns_api}/${local.agw_stage}/"
}

output "api_gateway_key" {
  value = aws_api_gateway_api_key.main.value
}

output "api_gateway_curl_metrics" {
  value = "curl -X GET https://${local.dns_api}/${local.agw_stage}/api/metric -H \"x-api-key:${aws_api_gateway_api_key.main.value}\""
}