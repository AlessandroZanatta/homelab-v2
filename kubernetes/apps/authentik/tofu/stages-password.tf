# Everything password: the stage that checks one at login, and the prompt and
# write pair used to set a new one.
#
# The login stage is not bound into any flow directly - identification-stage
# names it as its `password_stage` and validates inline, so the credentials are
# collected on a single screen. Its `configure_flow` is what backs the "change
# password" button on the user settings page.
#
# The prompt and write pair is shared by the recovery flow (flow-recovery.tf) and
# the password-change flow (flow-stage-configuration.tf).

resource "authentik_stage_password" "password_validator_stage" {
  name     = "password-stage"
  backends = ["authentik.core.auth.InbuiltBackend"]

  allow_show_password = true
  configure_flow      = authentik_flow.password_change.uuid
}

resource "authentik_stage_prompt_field" "password" {
  name      = "field-password"
  field_key = "password"
  label     = "Password"
  type      = "password"
  required  = true
  order     = 0
}

resource "authentik_stage_prompt_field" "password_repeat" {
  name      = "field-password-repeat"
  field_key = "password_repeat"
  label     = "Confirm password"
  type      = "password"
  required  = true
  order     = 1
}

resource "authentik_stage_prompt" "set_password_prompt" {
  name = "set-password-prompt"
  fields = [
    authentik_stage_prompt_field.password.id,
    authentik_stage_prompt_field.password_repeat.id,
  ]
}

resource "authentik_stage_user_write" "password_write" {
  name               = "password-write"
  user_creation_mode = "never_create"
}
