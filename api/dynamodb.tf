resource "aws_dynamodb_table" "user" {
  name             = "${lower(var.project)}-${lower(var.environment)}-user"
  hash_key         = "email"
  tags             = local.tags
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
  billing_mode     = "PAY_PER_REQUEST"

  attribute {
    name = "email"
    type = "S"
  }
}
resource "aws_dynamodb_table" "assignment" {
  name             = "${lower(var.project)}-${lower(var.environment)}-assignment"
  hash_key         = "email"
  range_key        = "classroom-role"
  tags             = local.tags
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
  billing_mode     = "PAY_PER_REQUEST"

  attribute {
    name = "email"
    type = "S"
  }
    attribute {
    name = "classroom-role"
    type = "S"
  }
}
resource "aws_dynamodb_table" "school" {
  name             = "${lower(var.project)}-${lower(var.environment)}-school"
  hash_key         = "academy"
  range_key         = "id"
  tags             = local.tags
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
  billing_mode     = "PAY_PER_REQUEST"

  attribute {
    name = "academy"
    type = "S"
  }
  attribute {
    name = "id"
    type = "S"
  }
}
resource "aws_dynamodb_table" "classroom" {
  name             = "${lower(var.project)}-${lower(var.environment)}-classroom"
  hash_key         = "school"
  range_key         = "classroom"
  tags             = local.tags
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
  billing_mode     = "PAY_PER_REQUEST"

  attribute {
    name = "school"
    type = "S"
  }
  attribute {
    name = "classroom"
    type = "S"
  }
}
resource "aws_dynamodb_table" "skills" {
  name             = "${lower(var.project)}-${lower(var.environment)}-skills"
  hash_key         = "classroom"
  range_key        = "level"
  tags             = local.tags
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
  billing_mode     = "PAY_PER_REQUEST"

  attribute {
    name = "classroom"
    type = "S"
  }
  attribute {
    name = "level"
    type = "S"
  }
}
resource "aws_dynamodb_table" "assessment" {
  name             = "${lower(var.project)}-${lower(var.environment)}-assessment"
  hash_key         = "id"
  range_key        = "name_firstname"
  tags             = local.tags
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
  billing_mode     = "PAY_PER_REQUEST"
  attribute {
    name = "id" #classroom, level
    type = "S"
  }
  attribute {
    name = "name_firstname" #name, firstname
    type = "S"
  }
}