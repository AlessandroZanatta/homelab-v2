# Stages that make up a login: identifying the user, refusing the ones that may
# not be here, and creating the session.

resource "authentik_stage_identification" "identification_stage" {
  name           = "identification-stage"
  user_fields    = ["username", "email"]
  password_stage = authentik_stage_password.password_validator_stage.id
}

resource "authentik_stage_deny" "deny_inactive_stage" {
  name         = "deny-inactive-stage"
  deny_message = "Your account is not active. Please contact an administrator for more information."
}

resource "authentik_stage_deny" "deny_externals_stage" {
  name         = "deny-externals-stage"
  deny_message = "You are not allowed to login to this IdP."
}

resource "authentik_stage_user_login" "execute_session_stage" {
  name               = "create-session"
  session_duration   = "hours=24"
  remember_me_offset = "days=30"
}
