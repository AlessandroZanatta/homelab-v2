resource "authentik_policy_expression" "check_inactive_user" {
  name       = "check-inactive-user"
  expression = "return not request.context.get('pending_user').is_active"
}

resource "authentik_policy_expression" "missing_static_codes" {
  name = "missing-static-codes"
  expression = trimspace(<<-EOT
user = request.context.get("pending_user")

if not user or not user.pk:
    return False

has_totp = ak_user_has_authenticator(user, "totp")
has_webauthn = ak_user_has_authenticator(user, "webauthn")

if not (has_totp or has_webauthn):
    return False

return not ak_user_has_authenticator(user, "static")
EOT
  )
}
