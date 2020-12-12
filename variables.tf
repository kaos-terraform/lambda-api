variable "domain" {
  type        = string
  description = "The domain that this service resides within. Resources will also be tagged with this name."
}

variable "environment" {
  type        = string
  description = "The app environment. This will be used to define the API Gateway stage and will be used for tagging."
}

variable "lambda-handler-name" {
  type        = string
  default     = "index.handler"
  description = "The file name, followed by a dot, followed by the main function name."
}

variable "lambda-source" {
  type        = string
  description = "The source directory containing the lambda code."
}

variable "public" {
  type        = boolean
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

variable "zip-destination" {
  type        = string
  description = "The destination directory to output zipped lambda directories to."
}

