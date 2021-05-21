data "aws_canonical_user_id" "admin" {}

resource "aws_s3_bucket" "main" {
  bucket        = local.name
  force_destroy = true
  acl           = "private"
  tags          = merge(local.tags, { Name = local.name })
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.main_origin.json
}

#Generates an IAM policy document from AWS Managed policies (Allow Cloudfront to Access S3)
data "aws_iam_policy_document" "main_origin" {
  #override_json = var.additional_bucket_policy

  statement {
    sid = "S3GetObjectForCloudFront"

    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.main.bucket}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }

  statement {
    sid = "S3ListBucketForCloudFront"

    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.main.bucket}"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
}