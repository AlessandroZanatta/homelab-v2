data "authentik_property_mapping_provider_scope" "oidc_scopes" {
  for_each = toset(["openid", "email", "profile", "offline_access"])
  managed  = "goauthentik.io/providers/oauth2/scope-${each.key}"
}
