
resource "authentik_provider_oauth2" "security_dependencytrack" {
  name               = "Dependency Track"
  client_id          = "security-dependencytrack"
  client_type        = "public"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://dtrack.kalexlab.xyz/static/oidc-callback.html",
      redirect_uri_type = "authorization",
    }
  ]
  property_mappings = [
    data.authentik_property_mapping_provider_scope.oidc_scopes["openid"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["email"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["profile"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["offline_access"].id,
    authentik_property_mapping_provider_scope.dependencytrack_role.id
  ]
  grant_types = [
    "authorization_code",
    "refresh_token"
  ]
}

resource "authentik_property_mapping_provider_scope" "dependencytrack_role" {
  name       = "dependencytrack-role"
  scope_name = "dependencytrack_role"
  expression = <<-EOT
    if ak_is_group_member(user, name="${authentik_group.infra.name}"):
        return {"dt_roles": ["admin"]}
    return {"dt_roles": []}
  EOT
}

resource "authentik_application" "security_dependencytrack" {
  name              = "Dependency Track"
  slug              = "security-dependencytrack"
  group             = var.application_groups["apps"]
  meta_launch_url   = "https://dtrack.kalexlab.xyz"
  meta_icon         = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dependency-track.svg"
  protocol_provider = authentik_provider_oauth2.security_dependencytrack.id
}

resource "authentik_policy_binding" "security_dependencytrack" {
  target = authentik_application.security_dependencytrack.uuid
  group  = authentik_group.infra.id
  order  = 0
}
