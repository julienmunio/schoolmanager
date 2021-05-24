resource "aws_lambda_layer_version" "main" {
  layer_name          = "nodejs_axios"
  filename            = data.archive_file.main.output_path
  source_code_hash    = data.archive_file.main.output_base64sha256
  compatible_runtimes = ["nodejs14.x"]
}

data "archive_file" "main" {
  type        = "zip"
  output_path = ".tmp/lambda-nodejs_axios.zip"
  source_dir  = "./layer"
  depends_on  = [null_resource.main]
}

resource "null_resource" "main" {
  provisioner "local-exec" {
    working_dir = "./layer/nodejs"
    command     = <<EOF
        npm install;
    EOF
  }

  triggers = {
    rerun_every_time = uuid()
  }
}
output "layer_arn" {
  value = aws_lambda_layer_version.main.arn
}
