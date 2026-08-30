# The "Update your info" flow, reached from the user settings page.
#
# Only the locale is editable here. Name, email and username are governed by
# authentik_system_settings, which keeps email and username read-only, so they
# are deliberately not offered as prompt fields.
#
#   0    prompt
#   10   write
resource "authentik_flow" "user_settings" {
  name           = "User Settings"
  slug           = "user-settings"
  title          = "Update your info"
  designation    = "stage_configuration"
  authentication = "require_authenticated"
}

resource "authentik_stage_prompt_field" "settings_locale" {
  name      = "settings-field-locale"
  field_key = "attributes.settings.locale"
  label     = "Language"
  type      = "ak-locale"
  required  = false
  order     = 0
}

resource "authentik_stage_prompt" "user_settings_prompt" {
  name = "user-settings-prompt"
  fields = [
    authentik_stage_prompt_field.settings_locale.id,
  ]
}

resource "authentik_stage_user_write" "user_settings_write" {
  name               = "user-settings-write"
  user_creation_mode = "never_create"
}

resource "authentik_flow_stage_binding" "user_settings_0_prompt" {
  target = authentik_flow.user_settings.uuid
  stage  = authentik_stage_prompt.user_settings_prompt.id
  order  = 0
}

resource "authentik_flow_stage_binding" "user_settings_10_write" {
  target = authentik_flow.user_settings.uuid
  stage  = authentik_stage_user_write.user_settings_write.id
  order  = 10
}
