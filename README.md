# Terraform deploy AWS lambda with python

Each time the python script is edited terraform will create a new zip file with the name reflecting the hash of the zip. The script is deployed to aws lambda with minimal permissions.

The necessary components have been organized into a terraform module. An example of the module being called is in the parent folder's main.tg
