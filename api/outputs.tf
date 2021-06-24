output "api_gateway_curl_event" {
  value = "curl -X GET https://${local.dns_api}/${local.agw_stage}/api/event"
}