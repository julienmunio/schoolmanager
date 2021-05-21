
resource aws_route53_record main {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  provider          =aws.default
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource aws_acm_certificate main {
  domain_name       = local.dns
  validation_method = "DNS"
  provider          = aws.use1
  tags              = merge(var.tags, {Name = var.name})

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_acm_certificate_validation main {
  certificate_arn         = aws_acm_certificate.main.arn
  provider                = aws.use1
  validation_record_fqdns = [for record in aws_route53_record.main : record.fqdn]
}

locals {
    dns = var.dns
}
output certificate_arn {
    value = aws_acm_certificate_validation.main.certificate_arn
}
output dns {
    value = local.dns
}
provider aws {
  alias = "default"
}

provider aws {
  alias = "use1"
}

variable dns {
    type = string
}
variable environment {
    type = string
}
variable name {
    type = string
}
variable zone_id {
    type = string
}
variable tags {
    default = {}
}