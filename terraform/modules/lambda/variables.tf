variable "name" {
  type = string
}
variable "zip_path" {
  type = string
}
variable "handler" {
  type = string
}
variable "role_arn" {
  type = string
}
variable "env" {
  type    = map(string)
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
