module "python_aws_lambda1" {
    source = "./modules/pythonawslambda"
    lambda_root = "../lambda_functions"
    lambda_handler = "function.main"

}
