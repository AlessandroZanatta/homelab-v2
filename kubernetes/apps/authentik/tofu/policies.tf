resource "authentik_policy_expression" "check_inactive_user" {
  name       = "check-inactive-user"
  expression = "return not request.context.get('pending_user').is_active"
}

# Passes when the client IP's reputation is at or below the threshold, i.e. for
# a bad IP. Each failed login costs one point, each success gives one back.
resource "authentik_policy_reputation" "bad_reputation" {
  name           = "bad-reputation"
  check_ip       = true
  check_username = false
  threshold      = -5
}

# Applied to every newly chosen password (recovery link and password change).
resource "authentik_policy_password" "password_strength" {
  name           = "password-strength"
  password_field = "password"
  error_message  = "Password must be at least 10 characters long and hard to guess."

  check_static_rules = true
  length_min         = 10
  amount_digits      = 0
  amount_lowercase   = 0
  amount_uppercase   = 0
  amount_symbols     = 0

  # Avoid sending user password to external services :)
  check_have_i_been_pwned = false

  check_zxcvbn           = true
  zxcvbn_score_threshold = 3
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
