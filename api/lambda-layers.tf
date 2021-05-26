
data "aws_lambda_layer_version" "nodejs" {
  layer_name = "nodejs"
}

data "aws_lambda_layer_version" "nodejs_axios" {
  layer_name = "nodejs_axios"
}

data "aws_lambda_layer_version" "mongodb" {
  layer_name = "mongodb"
}
