
# Output the API Gateway url
output "api-base-url" {
  value = aws_api_gateway_deployment.example.invoke_url
}
