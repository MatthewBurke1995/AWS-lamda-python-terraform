variable "lambda_root" {
  type        = string
  description = "The relative path to the source of the lambda"
  default     = "../lambda_functions"
}

variable "lambda_handler" {
    type        = string
    description = "file.function_name of lambda"
    default     = "function.main"
}

variable "lambda_runtime" {
    type        = string
    description = "https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html"
    default     = "python3.10"
    }

variable "lambda_log_level" {
    type        = string
    description = "log level to output"
    default     = "INFO"
    }

variable "lambda_concurrent_executions" {
    type        = number
    default     = 2
}

