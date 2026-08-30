# Grafana
resource "authentik_provider_oauth2" "monitoring_grafana" {
  name               = "Grafana"
  client_id          = "monitoring-grafana"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://grafana.kalexlab.xyz/login/generic_oauth",
      redirect_uri_type = "authorization",
    }
  ]
  logout_uri    = "https://grafana.kalexlab.xyz/logout"
  logout_method = "frontchannel"
  property_mappings = [
    data.authentik_property_mapping_provider_scope.oidc_scopes["openid"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["email"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["profile"].id,
    authentik_property_mapping_provider_scope.grafana_role.id
  ]
  grant_types = [
    "authorization_code"
  ]
}

resource "authentik_property_mapping_provider_scope" "grafana_role" {
  name       = "grafana-role"
  scope_name = "grafana_role"
  expression = <<-EOT
    if ak_is_group_member(user, name="${authentik_group.infra.name}"):
        return {"grafana_role": ["admin"]}
    return {"grafana_role": []}
  EOT
}

resource "authentik_application" "monitoring_grafana" {
  name              = "Grafana"
  slug              = "monitoring-grafana"
  group             = var.application_groups["monitoring"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/grafana.svg"
  protocol_provider = authentik_provider_oauth2.monitoring_grafana.id
}

resource "authentik_policy_binding" "monitoring_grafana" {
  target = authentik_application.monitoring_grafana.uuid
  group  = authentik_group.infra.id
  order  = 0
}

# Gatus
resource "authentik_provider_oauth2" "monitoring_gatus" {
  name               = "Gatus"
  client_id          = "monitoring-gatus"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://status.kalexlab.xyz/authorization-code/callback",
      redirect_uri_type = "authorization",
    }
  ]
  property_mappings = [
    data.authentik_property_mapping_provider_scope.oidc_scopes["openid"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["email"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["profile"].id
  ]
  grant_types = [
    "authorization_code"
  ]
}

resource "authentik_application" "monitoring_gatus" {
  name              = "Gatus"
  slug              = "monitoring-gatus"
  group             = var.application_groups["monitoring"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/gatus.svg"
  protocol_provider = authentik_provider_oauth2.monitoring_gatus.id
}

resource "authentik_policy_binding" "monitoring_gatus" {
  target = authentik_application.monitoring_gatus.uuid
  group  = authentik_group.infra.id
  order  = 0
}

# Glitchtip
resource "authentik_provider_oauth2" "monitoring_glitchtip" {
  name               = "Glitchtip"
  client_id          = "monitoring-glitchtip"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://glitchtip.kalexlab.xyz/accounts/oidc/authelia/login/callback/",
      redirect_uri_type = "authorization",
    }
  ]
  property_mappings = [
    data.authentik_property_mapping_provider_scope.oidc_scopes["openid"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["email"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["profile"].id
  ]
  grant_types = [
    "authorization_code"
  ]
}

resource "authentik_application" "monitoring_glitchtip" {
  name              = "Glitchtip"
  slug              = "monitoring-glitchtip"
  group             = var.application_groups["monitoring"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/glitchtip.svg"
  protocol_provider = authentik_provider_oauth2.monitoring_glitchtip.id

  policy_engine_mode = "any"
}

resource "authentik_policy_binding" "monitoring_glitchtip_infra" {
  target = authentik_application.monitoring_glitchtip.uuid
  group  = authentik_group.infra.id
  order  = 0
}

resource "authentik_policy_binding" "monitoring_glitchtip_dev" {
  target = authentik_application.monitoring_glitchtip.uuid
  group  = authentik_group.dev.id
  order  = 1
}
