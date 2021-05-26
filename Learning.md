# Create layer

cd layers
mkdir nodejs_axios
cd nodejs_axios
mkdir layer
cd layer
yarn init
yarn add aws-sdk
yarn add axios
yarn add dayjs


## Structure folder

.terraform
.tmp
  zip file
layer

tf & tfvars files

## backend-dev.tfvars

bucket  = "BUCKET NAME"
key     = "PREFIX/FILE NAME.tfstate"
region  = "REGION"
profile = "AWS CREDENTIAL NAME"

## change name layer

  cd "LAYER NAME"
  terraform init -backend-config="backend-${ENV:-dev}.tfvars"
  terraform apply -auto-approve -var-file="main-${ENV:-dev}.tfvars"

  check folder structure to execute npm install command

# Main structure

  cd ~/PROJECT FOLDER/API
  terraform init -backend-config="backend-${ENV:-dev}.tfvars"
  terraform apply -auto-approve -var-file="main-${ENV:-dev}.tfvars"

### Issues

  layers = [
    "${data.aws_lambda_layer_version.nodejs_axios.layer_arn}:${data.aws_lambda_layer_version.nodejs_axios.version}"
  ]

```bash
╷
│ Error: Reference to undeclared resource
│ 
│   on lambda-students-list.tf line 17, in resource "aws_lambda_function" "students-list":
│   17:     "${data.aws_lambda_layer_version.nodejs_axios.layer_arn}:${data.aws_lambda_layer_version.nodejs_axios.version}"
│ 
│ A data resource "aws_lambda_layer_version" "nodejs_axios" has not been declared in the root module.
╵
╷
│ Error: Reference to undeclared resource
│ 
│   on lambda-students-list.tf line 17, in resource "aws_lambda_function" "students-list":
│   17:     "${data.aws_lambda_layer_version.nodejs_axios.layer_arn}:${data.aws_lambda_layer_version.nodejs_axios.version}"
│ 
│ A data resource "aws_lambda_layer_version" "nodejs_axios" has not been declared in the root module.
```

### Solve by put lambda-layers.tf in api/

### Issues

╷
│ Error: Reference to undeclared resource
│ 
│   on lambda-students-list.tf line 76, in resource "aws_iam_policy" "lambda_students-list":
│   76:           "${aws_dynamodb_table.profiles.arn}",
│ 
│ A managed resource "aws_dynamodb_table" "profiles" has not been declared in the root module.
╵
╷
│ Error: Reference to undeclared resource
│ 
│   on lambda-students-list.tf line 77, in resource "aws_iam_policy" "lambda_students-list":
│   77:           "${aws_dynamodb_table.profiles.arn}/*"
│ 
│ A managed resource "aws_dynamodb_table" "profiles" has not been declared in the root module.
╵