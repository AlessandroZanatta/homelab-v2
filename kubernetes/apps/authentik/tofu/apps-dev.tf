# Anime
resource "authentik_provider_oauth2" "dev_anime" {
  name               = "Anime (DEV)"
  client_id          = "dev-anime"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "http://192.168.10.51:3000/auth/callback/oidc",
      redirect_uri_type = "authorization",
    },
    {
      matching_mode     = "strict",
      url               = "xyz.kalexlab.anime.dev://oauth",
      redirect_uri_type = "authorization",
    },
    {
      matching_mode     = "strict",
      url               = "app://-"
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

resource "authentik_application" "dev_anime" {
  name              = "Anime (DEV)"
  slug              = "dev-anime"
  group             = var.application_groups["dev"]
  meta_launch_url   = "http://192.168.10.51:8081"
  meta_icon         = "https://anime.kalexlab.xyz/favicon.ico"
  protocol_provider = authentik_provider_oauth2.dev_anime.id
}

resource "authentik_policy_binding" "dev_anime" {
  target = authentik_application.dev_anime.uuid
  group  = authentik_group.dev.id
  order  = 0
}

# Reciept
resource "authentik_provider_oauth2" "dev_reciept" {
  name               = "Reciept (DEV)"
  client_id          = "dev-reciept"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "http://192.168.10.51:3000/auth/callback/oidc",
      redirect_uri_type = "authorization",
    },
    {
      matching_mode     = "strict",
      url               = "xyz.kalexlab.reciept.dev://oauth",
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

resource "authentik_application" "dev_reciept" {
  name            = "Reciept (DEV)"
  slug            = "dev-reciept"
  group           = var.application_groups["dev"]
  meta_launch_url = "http://192.168.10.51:8081"
  # meta_icon         = "https://reciept.kalexlab.xyz/favicon.ico"
  protocol_provider = authentik_provider_oauth2.dev_reciept.id
}

resource "authentik_policy_binding" "dev_reciept" {
  target = authentik_application.dev_reciept.uuid
  group  = authentik_group.dev.id
  order  = 0
}
