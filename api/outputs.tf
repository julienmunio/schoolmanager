# # output "website" {
# #   value = "https://${aws_cloudfront_distribution.main.domain_name}/"
# # }

# output "api_gateway" {
#   value = "https://${local.dns_api}/${local.agw_stage}/"
# }

# # output "api_gateway_key" {
# #   value = aws_api_gateway_api_key.main.value
# # }

# output "api_gateway_curl_collect" {
#   # value = "curl -X GET https://${local.dns_api}/${local.agw_stage}/api/collect -H \"x-api-key:${aws_api_gateway_api_key.main.value}\""
#   value = "curl -X GET https://${local.dns_api}/${local.agw_stage}/api/collect"
# }


# TODO
output "base_url" {
  value = aws_api_gateway_deployment.main.invoke_url
}
