# Create an Origin Access Identity to restrict access to Amazon S3 Content
resource "aws_cloudfront_origin_access_identity" "main" {
  comment = local.name
}

locals {
  s3_origin_id          = "S3-${aws_s3_bucket.main.bucket_regional_domain_name}"
  s3_datalake_origin_id = "S3-${aws_s3_bucket.datalake.bucket_regional_domain_name}"
  api_origin_id         = "API-${aws_api_gateway_rest_api.main.id}"
}

module "acm_cloudfront" {
  source = "./acm"
  dns    = local.dns
  tags   = local.tags
  providers = {
    aws.default = aws
    aws.use1    = aws.use1
  }
  name        = local.name
  environment = local.agw_stage
  zone_id     = data.aws_route53_zone.main.zone_id
}

# Define CloudFront distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = local.name
  default_root_object = "index.html"
  aliases             = [local.dns]
  depends_on          = [aws_s3_bucket.main]
  web_acl_id          = aws_wafv2_web_acl.main.arn

  tags = local.tags
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm_cloudfront.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  # S3 Origin
  origin {
    origin_id   = local.s3_origin_id
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  # S3 Athena Datalake Origin
  origin {
    origin_id   = local.s3_datalake_origin_id
    domain_name = aws_s3_bucket.datalake.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  # API Origin
  origin {
    origin_id   = local.api_origin_id
    origin_path = "/${local.agw_stage}"
    domain_name = local.dns_api

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"] # , "TLSv1.3" -> Terraform issue?
    }

    custom_header {
      name  = "x-api-key"
      value = aws_api_gateway_api_key.main.value
    }

  }

  # S3 by default
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    viewer_protocol_policy = "redirect-to-https"
  }

  # Exports
  ordered_cache_behavior {
    path_pattern     = "/exports/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_datalake_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    viewer_protocol_policy = "redirect-to-https"

  }
  # API
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.api_origin_id
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "https-only"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type", "Origin"]

      cookies {
        forward = "none"
      }
    }

  }
}


resource "aws_route53_record" "cloudfront" {
  name    = module.acm_cloudfront.dns
  type    = "A"
  zone_id = data.aws_route53_zone.main.zone_id
  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
  }
}
