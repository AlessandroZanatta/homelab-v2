variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "application_groups" {
  type = map(string)
}
