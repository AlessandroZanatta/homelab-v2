# Recovery, reachable only through an admin-generated recovery link.
#
# Self-service recovery is deliberately dead until there is an SMTP server to
# verify identity against.
#https://docs.goauthentik.io/blueprints/example/flows-recovery-email-verification.yaml
#   0    deny        unless the plan came from a recovery link
#   20   password prompt
#   100  write
resource "authentik_flow" "recovery" {
  name           = "KalexLab IdP Recovery"
  slug           = "recovery"
  title          = "Choose a password"
  designation    = "recovery"
  authentication = "require_unauthenticated"
}

# `is_restored` is set only when recoverying from an admin-generated recovery link.
#   ref: https://docs.goauthentik.io/blueprints/example/flows-recovery-email-verification.yaml
resource "authentik_policy_expression" "flow_not_restored" {
  name = "flow-not-restored"
  expression = trimspace(<<-EOT
return not request.context.get("is_restored")
EOT
  )
}

resource "authentik_stage_deny" "deny_self_service_recovery_stage" {
  name         = "deny-self-service-recovery-stage"
  deny_message = "Password reset is not self-service. Please ask an administrator to reset your password."
}

# Evaluated when the stage is reached rather than at plan time: `is_restored`
# only exists once the flow is actually being executed.
resource "authentik_flow_stage_binding" "recovery_0_deny_self_service" {
  target = authentik_flow.recovery.uuid
  stage  = authentik_stage_deny.deny_self_service_recovery_stage.id
  order  = 0

  evaluate_on_plan     = false
  re_evaluate_policies = true
}

resource "authentik_policy_binding" "recovery_0_deny_self_service" {
  target = authentik_flow_stage_binding.recovery_0_deny_self_service.id
  policy = authentik_policy_expression.flow_not_restored.id
  order  = 0

  negate         = false
  failure_result = false
}

resource "authentik_flow_stage_binding" "recovery_20_prompt" {
  target = authentik_flow.recovery.uuid
  stage  = authentik_stage_prompt.set_password_prompt.id
  order  = 20
}

resource "authentik_flow_stage_binding" "recovery_100_write" {
  target = authentik_flow.recovery.uuid
  stage  = authentik_stage_user_write.password_write.id
  order  = 100
}
