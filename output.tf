
# Output the API Gateway url
output "api_base_url" {
  value = aws_api_gateway_deployment.deployment ? aws_api_gateway_deployment.deployment.invoke_url : "API not public."
}
