
# Output the API Gateway url
output "base_url" {
  value = var.public ? aws_api_gateway_deployment.deployment[0].invoke_url : "API not public."
}
