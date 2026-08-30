# The login flow, and the brand's authentication flow, so it covers authentik's
# own interfaces as well as any application that does not pin its own.
#
# Every user validates a second factor here, enrolling one on the spot if they
# have none. Because a session can only be minted by passing this flow, no
# session anywhere is ever single factor - which is what lets the admin interface
# be safe without a flow of its own, and why applications need no per-app 2FA
# gate.
#
#   0    identification           username and password, on one screen
#   10   deny inactive            disabled accounts
#   11   deny non-users           accounts outside the `user` group tree
#   30   MFA validation           everyone
#   35   backup code explanation  users without backup codes
#   40   backup code setup        users without backup codes
#   100  login
resource "authentik_flow" "authentication" {
  name           = "KalexLab IdP Authentication"
  slug           = "login"
  title          = "Welcome to KalexLab IdP"
  designation    = "authentication"
  authentication = "none"
}

resource "authentik_flow_stage_binding" "auth_0_identification" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_identification.identification_stage.id
  order  = 0
}

resource "authentik_flow_stage_binding" "auth_10_deny_inactive" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_deny.deny_inactive_stage.id
  order  = 10

  evaluate_on_plan     = false
  re_evaluate_policies = true
}

resource "authentik_policy_binding" "auth_10_deny_inactive" {
  target = authentik_flow_stage_binding.auth_10_deny_inactive.id
  policy = authentik_policy_expression.check_inactive_user.id
  order  = 0

  negate         = false
  failure_result = false
}

resource "authentik_flow_stage_binding" "auth_11_deny_externals" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_deny.deny_externals_stage.id
  order  = 11

  evaluate_on_plan     = false
  re_evaluate_policies = true
}

resource "authentik_policy_binding" "auth_11_deny_externals" {
  target = authentik_flow_stage_binding.auth_11_deny_externals.id
  group  = authentik_group.user.id
  order  = 0

  negate         = true
  failure_result = false
}

resource "authentik_flow_stage_binding" "auth_30_mfa_validate" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_authenticator_validate.mfa_validate_stage.id
  order  = 30

  evaluate_on_plan     = false
  re_evaluate_policies = true
}

resource "authentik_flow_stage_binding" "auth_35_static_explanation" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_prompt.static_explanation_stage.id
  order  = 35

  evaluate_on_plan     = false
  re_evaluate_policies = true
}

resource "authentik_policy_binding" "auth_35_static_explanation" {
  target = authentik_flow_stage_binding.auth_35_static_explanation.id
  policy = authentik_policy_expression.missing_static_codes.id
  order  = 0

  negate         = false
  failure_result = false
}

resource "authentik_flow_stage_binding" "auth_40_static_setup" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_authenticator_static.static_setup_stage.id
  order  = 40

  evaluate_on_plan     = false
  re_evaluate_policies = true
}

resource "authentik_policy_binding" "auth_40_static_setup" {
  target = authentik_flow_stage_binding.auth_40_static_setup.id
  policy = authentik_policy_expression.missing_static_codes.id
  order  = 0

  negate         = false
  failure_result = false
}

resource "authentik_flow_stage_binding" "auth_100_login" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_user_login.execute_session_stage.id
  order  = 100
}
