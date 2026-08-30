# ArgoCD
resource "authentik_provider_oauth2" "management_argocd" {
  name               = "ArgoCD"
  client_id          = "management-argocd"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://argocd.kalexlab.xyz/api/dex/callback",
      redirect_uri_type = "authorization",
    },
    {
      matching_mode     = "strict",
      url               = "http://localhost:8085/auth/callback",
      redirect_uri_type = "authorization",
    }
  ]
  logout_uri    = "https://argocd.kalexlab.xyz/auth/logout"
  logout_method = "frontchannel"
  property_mappings = [
    data.authentik_property_mapping_provider_scope.oidc_scopes["openid"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["email"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["profile"].id
  ]
  grant_types = [
    "authorization_code"
  ]
}

resource "authentik_application" "management_argocd" {
  name              = "ArgoCD"
  slug              = "management-argocd"
  group             = var.application_groups["infra"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/argo-cd.svg"
  protocol_provider = authentik_provider_oauth2.management_argocd.id
}

resource "authentik_policy_binding" "management_argocd" {
  target = authentik_application.management_argocd.uuid
  group  = authentik_group.infra.id
  order  = 0
}
