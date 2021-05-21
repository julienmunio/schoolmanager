resource "aws_s3_bucket" "datalake" {
  bucket        = "${local.name}-datalake"
  force_destroy = true
  acl           = "private"
  tags          = merge(local.tags, { Name = "${local.name}-datalake" })

  lifecycle_rule {
    id      = "athena"
    enabled = true
    prefix  = "athena/output/"
    expiration {
      days = 90 // 3 months
    }
  }

  lifecycle_rule {
    id      = "firehoseerror"
    enabled = true
    prefix  = "error/"
    expiration {
      days = 60 // 2 months
    }
  }

  lifecycle_rule {
    id      = "firehosemessages"
    enabled = true
    prefix  = "messages/"
    expiration {
      days = 730 // 2 years
    }
  }
}


resource "aws_s3_bucket_policy" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  policy = data.aws_iam_policy_document.datalake_origin.json
}

#Generates an IAM policy document from AWS Managed policies (Allow Cloudfront to Access S3)
data "aws_iam_policy_document" "datalake_origin" {
  #override_json = var.additional_bucket_policy

  statement {
    sid = "S3GetObjectForCloudFront"

    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.datalake.bucket}/exports/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }

  statement {
    sid = "S3ListBucketForCloudFront"

    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.datalake.bucket}"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
}

resource "aws_s3_bucket_notification" "datalake" {
  bucket     = aws_s3_bucket.datalake.id
  depends_on = [aws_lambda_permission.notify_export]

  lambda_function {
    lambda_function_arn = aws_lambda_function.notify_export.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "exports/"
    filter_suffix       = ".csv"
  }
}
