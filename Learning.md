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
  terraform init -backend-config=backend-dev.tfvars
  terraform apply -auto-approve -var-file="main-dev.tfvars"