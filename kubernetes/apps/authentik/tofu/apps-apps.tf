# Anime
resource "authentik_provider_oauth2" "apps_anime" {
  name               = "Anime"
  client_id          = "apps-anime"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://anime.kalexlab.xyz/api/auth/callback/oidc",
      redirect_uri_type = "authorization",
    },
    {
      matching_mode     = "strict",
      url               = "xyz.kalexlab.anime://oauth",
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

resource "authentik_application" "apps_anime" {
  name              = "Anime"
  slug              = "apps-anime"
  group             = var.application_groups["media"]
  meta_launch_url   = "https://anime.kalexlab.xyz/library"
  meta_icon         = "https://anime.kalexlab.xyz/favicon.ico"
  protocol_provider = authentik_provider_oauth2.apps_anime.id
}

resource "authentik_policy_binding" "apps_anime" {
  target = authentik_application.apps_anime.uuid
  group  = authentik_group.home.id
  order  = 0
}

# Shelfmark
resource "authentik_provider_oauth2" "apps_shelfmark" {
  name               = "Shelfmark"
  client_id          = "apps-shelfmark"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://get.books.kalexlab.xyz/api/auth/oidc/callback",
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

resource "authentik_application" "apps_shelfmark" {
  name              = "Shelfmark"
  slug              = "apps-shelfmark"
  group             = var.application_groups["apps"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/shelfmark.svg"
  protocol_provider = authentik_provider_oauth2.apps_shelfmark.id
}

resource "authentik_policy_binding" "apps_shelfmark" {
  target = authentik_application.apps_shelfmark.uuid
  group  = authentik_group.home.id
  order  = 0
}

# Home Assistant
resource "authentik_provider_oauth2" "apps_homeassistant" {
  name               = "Home Assistant"
  client_id          = "apps-homeassistant"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://home.kalexlab.xyz/auth/oidc/callback",
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

resource "authentik_application" "apps_homeassistant" {
  name              = "Home Assistant"
  slug              = "apps-homeassistant"
  group             = var.application_groups["apps"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/home-assistant.svg"
  protocol_provider = authentik_provider_oauth2.apps_homeassistant.id
}

resource "authentik_policy_binding" "apps_homeassistant" {
  target = authentik_application.apps_homeassistant.uuid
  group  = authentik_group.home.id
  order  = 0
}

# Immich
resource "authentik_provider_oauth2" "apps_immich" {
  name               = "Immich"
  client_id          = "apps-immich"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://photos.kalexlab.xyz/auth/login",
      redirect_uri_type = "authorization",
    },
    {
      matching_mode     = "strict",
      url               = "https://photos.kalexlab.xyz/user-settings",
      redirect_uri_type = "authorization",
    },
    {
      matching_mode     = "strict",
      url               = "app.immich:///oauth-callback",
      redirect_uri_type = "authorization",
    }
  ]
  property_mappings = [
    data.authentik_property_mapping_provider_scope.oidc_scopes["openid"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["email"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["profile"].id,
    authentik_property_mapping_provider_scope.immich_role.id,
    authentik_property_mapping_provider_scope.immich_quota.id,
  ]
  grant_types = [
    "authorization_code"
  ]
}

resource "authentik_property_mapping_provider_scope" "immich_role" {
  name       = "immich-role"
  scope_name = "immich_role"
  expression = <<-EOT
    return {"immich_role": "admin" if ak_is_group_member(user, name="${authentik_group.infra.name}") else "user"}
  EOT
}

resource "authentik_property_mapping_provider_scope" "immich_quota" {
  name       = "immich-quota"
  scope_name = "immich_quota"
  expression = <<-EOT
    # 0 = unlimited in Immich
    return {"immich_quota": 0}
  EOT
}

resource "authentik_application" "apps_immich" {
  name              = "Immich"
  slug              = "apps-immich"
  group             = var.application_groups["apps"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/immich.svg"
  protocol_provider = authentik_provider_oauth2.apps_immich.id
}

resource "authentik_policy_binding" "apps_immich" {
  target = authentik_application.apps_immich.uuid
  group  = authentik_group.home.id
  order  = 0
}

# Jellyfin
resource "authentik_provider_oauth2" "apps_jellyfin" {
  name               = "Jellyfin"
  client_id          = "apps-jellyfin"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://jellyfin.kalexlab.xyz/sso/OID/redirect/Authentik",
      redirect_uri_type = "authorization",
    }
  ]
  property_mappings = [
    data.authentik_property_mapping_provider_scope.oidc_scopes["openid"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["email"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["profile"].id,
    authentik_property_mapping_provider_scope.jellyfin_role.id
  ]
  grant_types = [
    "authorization_code"
  ]
}

resource "authentik_property_mapping_provider_scope" "jellyfin_role" {
  name       = "jellyfin-role"
  scope_name = "jellyfin_role"
  expression = <<-EOT
    roles = ["jellyfin_admin" if ak_is_group_member(user, name="${authentik_group.infra.name}") else "jellyfin_user"]

    return {"jellyfin_role": roles}
  EOT
}

resource "authentik_application" "apps_jellyfin" {
  name              = "Jellyfin"
  slug              = "apps-jellyfin"
  group             = var.application_groups["media"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyfin.svg"
  protocol_provider = authentik_provider_oauth2.apps_jellyfin.id
}

resource "authentik_policy_binding" "apps_jellyfin" {
  target = authentik_application.apps_jellyfin.uuid
  group  = authentik_group.home.id
  order  = 0
}

# Nextcloud
resource "authentik_provider_oauth2" "apps_nextcloud" {
  name               = "Nextcloud"
  client_id          = "apps-nextcloud"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://cloud.kalexlab.xyz/apps/oidc_login/oidc",
      redirect_uri_type = "authorization",
    },
    {
      matching_mode     = "strict",
      url               = "https://cloud.kalexlab.xyz/index.php/apps/oidc_login/oidc",
      redirect_uri_type = "authorization",
    }
  ]
  property_mappings = [
    data.authentik_property_mapping_provider_scope.oidc_scopes["openid"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["email"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["profile"].id,
    authentik_property_mapping_provider_scope.nextcloud_role.id
  ]
  grant_types = [
    "authorization_code"
  ]
}

resource "authentik_property_mapping_provider_scope" "nextcloud_role" {
  name       = "nextcloud-role"
  scope_name = "nextcloud_role"
  expression = <<-EOT
    return {
        "nextcloud_admin": ak_is_group_member(
            user,
            name="${authentik_group.infra.name}"
        ),
    }
  EOT
}

resource "authentik_application" "apps_nextcloud" {
  name              = "Nextcloud"
  slug              = "apps-nextcloud"
  group             = var.application_groups["apps"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/nextcloud.svg"
  protocol_provider = authentik_provider_oauth2.apps_nextcloud.id
}

resource "authentik_policy_binding" "apps_nextcloud" {
  target = authentik_application.apps_nextcloud.uuid
  group  = authentik_group.home.id
  order  = 0
}

# Kaneo
resource "authentik_provider_oauth2" "apps_kaneo" {
  name               = "Kaneo"
  client_id          = "apps-kaneo"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://tasks.kalexlab.xyz/api/auth/oauth2/callback/custom",
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

resource "authentik_application" "apps_kaneo" {
  name              = "Kaneo"
  slug              = "apps-kaneo"
  group             = var.application_groups["apps"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/kaneo.svg"
  protocol_provider = authentik_provider_oauth2.apps_kaneo.id
}

resource "authentik_policy_binding" "apps_kaneo" {
  target = authentik_application.apps_kaneo.uuid
  group  = authentik_group.home.id
  order  = 0
}

# Outline
resource "authentik_provider_oauth2" "apps_outline" {
  name               = "Outline"
  client_id          = "apps-outline"
  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid

  signing_key = authentik_certificate_key_pair.jwt_signing.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://wiki.kalexlab.xyz/auth/oidc.callback",
      redirect_uri_type = "authorization",
    }
  ]
  property_mappings = [
    data.authentik_property_mapping_provider_scope.oidc_scopes["openid"].id,
    # Outline requires the email_verified claim to be True, can't override that currently
    authentik_property_mapping_provider_scope.outline_email_verified.id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["profile"].id,
    data.authentik_property_mapping_provider_scope.oidc_scopes["offline_access"].id
  ]
  grant_types = [
    "authorization_code"
  ]
}

resource "authentik_property_mapping_provider_scope" "outline_email_verified" {
  name       = "outline-email-verified"
  scope_name = "email"
  expression = <<-EOT
    return {
        "email": user.email,
        "email_verified": True
    }
  EOT
}

resource "authentik_application" "apps_outline" {
  name              = "Outline"
  slug              = "apps-outline"
  group             = var.application_groups["apps"]
  meta_icon         = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/outline.svg"
  protocol_provider = authentik_provider_oauth2.apps_outline.id
}

resource "authentik_policy_binding" "apps_outline" {
  target = authentik_application.apps_outline.uuid
  group  = authentik_group.home.id
  order  = 0
}
