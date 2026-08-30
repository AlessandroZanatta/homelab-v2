# Second factor stages: the three things a user can enrol, the screen that
# explains backup codes, and the stage that does the validating.

resource "authentik_stage_authenticator_totp" "totp_setup_stage" {
  name           = "totp-setup-stage"
  friendly_name  = "Authenticator app"
  configure_flow = authentik_flow.totp_setup.uuid
}

resource "authentik_stage_authenticator_webauthn" "webauthn_setup_stage" {
  name           = "webauthn-setup-stage"
  friendly_name  = "Security key or passkey"
  configure_flow = authentik_flow.webauthn_setup.uuid

  // TODO: can probably remove this when authentik provider is updated
  lifecycle { ignore_changes = [prevent_duplicate_devices] }
}

resource "authentik_stage_authenticator_static" "static_setup_stage" {
  name           = "static-setup-stage"
  friendly_name  = "Backup codes"
  configure_flow = authentik_flow.static_setup.uuid
}

# Basic and fast explanation of what static backup codes are for, just in case
resource "authentik_stage_prompt_field" "static_explanation_text" {
  name      = "field-static-explanation"
  field_key = "static_explanation"
  label     = "Save your backup codes"
  type      = "static"
  required  = false
  order     = 0

  initial_value = <<EOF
<p>Next you will be shown a list of one-time backup codes.</p>
<br/>
<p>They are the only way back into your account if you lose access to your
   second factor, so store them somewhere safe. Each code works once.</p>
<br/>
<p><small>Lost access anyway? Beg the admin, it can reset your account by
   hand, but bring some beer.</small></p>
EOF
}

resource "authentik_stage_prompt" "static_explanation_stage" {
  name   = "static-explanation-stage"
  fields = [authentik_stage_prompt_field.static_explanation_text.id]
}

resource "authentik_stage_authenticator_validate" "mfa_validate_stage" {
  name = "mfa-validate-stage"

  device_classes        = ["totp", "webauthn"]
  not_configured_action = "configure"

  configuration_stages = [
    authentik_stage_authenticator_totp.totp_setup_stage.id,
    authentik_stage_authenticator_webauthn.webauthn_setup_stage.id,
  ]

  last_auth_threshold        = "seconds=0"
  webauthn_user_verification = "preferred"
}
