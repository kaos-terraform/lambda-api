variable "domain" {
  type        = string
  description = "The domain that this service resides within. Resources will also be tagged with this name."
}

variable "environment" {
  type        = string
  description = "The app environment. This will be used to define the API Gateway stage and will be used for tagging."
}

variable "lambda_handler_name" {
  type        = string
  default     = "index.handler"
  description = "The file name, followed by a dot, followed by the main function name."
}

variable "lambda_source" {
  type        = string
  description = "The source directory containing the lambda code."
}

variable "node_runtime" {
  type        = string
  default     = "12.x"
  description = "The runtime version number."
}

variable "public" {
  type        = bool
  description = "Whether to create a public endpoint for the API gateway"
  default     = false
}

variable "region" {
  type        = string
  description = "The AWS region to deploy to."
}

variable "service" {
  type        = string
  description = "The service or application name. Resources will also be tagged with this name."
}

variable "zip_destination" {
  type        = string
  description = "The destination directory to output zipped lambda directories to."
}

