# Stage configuration flows.
#
# Every flow here changes something security-sensitive, so each one starts with
# mfa-reauth-stage at order 0: a valid session alone is not enough to change the
# password or add authenticators/backup codes (see stages-mfa.tf).

resource "authentik_flow" "password_change" {
  name           = "Change your password"
  slug           = "password-change"
  title          = "Change your password"
  designation    = "stage_configuration"
  authentication = "require_authenticated"
}

resource "authentik_flow_stage_binding" "password_change_0_reauth" {
  target = authentik_flow.password_change.uuid
  stage  = authentik_stage_authenticator_validate.mfa_reauth_stage.id
  order  = 0
}

resource "authentik_flow_stage_binding" "password_change_10_prompt" {
  target = authentik_flow.password_change.uuid
  stage  = authentik_stage_prompt.set_password_prompt.id
  order  = 10
}

resource "authentik_flow_stage_binding" "password_change_20_write" {
  target = authentik_flow.password_change.uuid
  stage  = authentik_stage_user_write.password_write.id
  order  = 20
}

resource "authentik_flow" "totp_setup" {
  name           = "TOTP Setup"
  slug           = "totp-setup"
  title          = "Set up your authenticator app"
  designation    = "stage_configuration"
  authentication = "require_authenticated"
}

resource "authentik_flow_stage_binding" "totp_setup_0_reauth" {
  target = authentik_flow.totp_setup.uuid
  stage  = authentik_stage_authenticator_validate.mfa_reauth_stage.id
  order  = 0
}

resource "authentik_flow_stage_binding" "totp_setup_10" {
  target = authentik_flow.totp_setup.uuid
  stage  = authentik_stage_authenticator_totp.totp_setup_stage.id
  order  = 10
}

resource "authentik_flow" "webauthn_setup" {
  name           = "WebAuthn Setup"
  slug           = "webauthn-setup"
  title          = "Set up your security key or passkey"
  designation    = "stage_configuration"
  authentication = "require_authenticated"
}

resource "authentik_flow_stage_binding" "webauthn_setup_0_reauth" {
  target = authentik_flow.webauthn_setup.uuid
  stage  = authentik_stage_authenticator_validate.mfa_reauth_stage.id
  order  = 0
}

resource "authentik_flow_stage_binding" "webauthn_setup_10" {
  target = authentik_flow.webauthn_setup.uuid
  stage  = authentik_stage_authenticator_webauthn.webauthn_setup_stage.id
  order  = 10
}

resource "authentik_flow" "static_setup" {
  name           = "Recovery Codes Setup"
  slug           = "static-setup"
  title          = "Generate recovery codes"
  designation    = "stage_configuration"
  authentication = "require_authenticated"
}

resource "authentik_flow_stage_binding" "static_setup_0_reauth" {
  target = authentik_flow.static_setup.uuid
  stage  = authentik_stage_authenticator_validate.mfa_reauth_stage.id
  order  = 0
}

resource "authentik_flow_stage_binding" "static_setup_10_explanation" {
  target = authentik_flow.static_setup.uuid
  stage  = authentik_stage_prompt.static_explanation_stage.id
  order  = 10
}

resource "authentik_flow_stage_binding" "static_setup_20" {
  target = authentik_flow.static_setup.uuid
  stage  = authentik_stage_authenticator_static.static_setup_stage.id
  order  = 20
}
