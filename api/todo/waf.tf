resource "aws_wafv2_web_acl" "main" {
  name        = local.name
  description = "Cloudfront WAF"
  scope       = "CLOUDFRONT"
  provider    = aws.use1
  tags        = local.tags

  default_action {
    allow {}
  }

  rule {
    name     = "rule-rate"
    priority = 1

    action {
      count {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_limit_5min
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "rule-group-ref"
    priority = 2

    override_action {
      none {}
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.main.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "rule-group"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-config2"
    sampled_requests_enabled   = true
  }
}


resource "aws_wafv2_rule_group" "main" {
  capacity = 500
  name     = "${local.name}-group"
  scope    = "CLOUDFRONT"
  provider = aws.use1

  dynamic "rule" {
    for_each = contains(flatten(values(var.allowed_ips)), "0.0.0.0/0") ? [] : ["-"]
    content {
      name     = "rule-allowed-ips"
      priority = 2

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            ip_set_reference_statement {
              arn = aws_wafv2_ip_set.main.arn
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = false
        metric_name                = "rule-geo"
        sampled_requests_enabled   = false
      }
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_ip_set" "main" {
  name               = local.name
  scope              = "CLOUDFRONT"
  description        = "AllowedIPs"
  ip_address_version = "IPV4"
  addresses          = contains(flatten(values(var.allowed_ips)), "0.0.0.0/0") ? [] : flatten(values(var.allowed_ips))
  tags               = local.tags
  provider           = aws.use1
}
