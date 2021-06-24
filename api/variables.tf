# Variables
variable "region" {
  default = "eu-west-1"
}
variable "profile" {
  type = string
}
variable "ip_address" {
  type        = string
  sensitive   = true
}
variable "project" {
  type = string
}
variable "environment" {
  type = string
}
variable "client" {
  type = string
}

variable "collect_schedule_cron" {
  description = "The scheduling expression for collection of all events. For example, 'cron(0 8 ? * MON-FRI *)' or 'rate(5 minutes)'. Disabled when null"
  type        = string
  default     = null
}
variable "track_events_schedule_cron" {
  description = "The scheduling expression for updating the live events. For example, 'cron(0 8 ? * MON-FRI *)' or 'rate(5 minutes)'. Disabled when null"
  type        = string
  default     = null
}

variable "mongo_uri" {
  description = "MonDB URI used to fetch metrics. Ex: 'mongodb+srv://user:pwd@host/path'"
  type        = string
}

variable "waf_limit_5min" {
  default = 100
}

variable "allowed_ips" {
  default = {
    "everybody" : "0.0.0.0/0"
  }
}
variable "dns_zone" {
  type = string
}
variable "cloudwatch_namespace" {
  type = string
}