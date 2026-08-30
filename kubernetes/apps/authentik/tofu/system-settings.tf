resource "authentik_system_settings" "settings" {
  default_user_change_name     = false
  default_user_change_email    = false
  default_user_change_username = false
}
