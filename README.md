# About

This module will facilitate creating an AWS Lambda API that is accessible through AWS API Gateway.

It will:

- Set up an S3 bucket
- Upload your source code to the S3 bucket so a Lambda can use it
- Set up a Lambda function that uses your code as it's source
- Set up an API gateway that will route to your Lambda

# Usage

1. Add this to your terraform file.

    ```tf
    module "lambda_api" {
      source = "github.com/kaos-terraform/lambda-api"

      domain = "my-domain"
      environment = "test"
      lambda_handler_name = "index.handler"
      lambda_source = "./src"
      public = false
      region = "us-west-1"
      service = "my-service"
      zip_destination = "./"
    }

    # output the URL to access the lambda via the gateway
    output "base_url" {
      value = module.lambda_api.base_url
    }
    ```

2. Run this command to fetch the module: `terraform get`

## Variables

| Variable | Type | Default | Description | 
| -------- | ---- | ------- | ----------- |
| domain | string | | The domain that this service resides within. Resources will also be tagged with this name. |
| environment | string | | The app environment. This will be used to define the API Gateway stage and will be used for tagging. |
| lambda_handler_name | string | index.handler | The file name, followed by a dot, followed by the main function name. |
| lambda_source | string | | The source directory containing the lambda code. |
| service | string | | The service or application name. Resources will also be tagged with this name. |
| public | bool | false | Whether to create a public endpoint for the API gateway. |
| region | string | | The AWS region to deploy to. |
| zip_destination | string | | The destination directory to output zipped lambda directories to on your local machine. |

# Maintenance

Once changes are made you'll want to specify a new tag with the following commands:

