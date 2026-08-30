// Forward auth list of applications
//
// Grouped here and defined like this to have them automatically added to the outpost
locals {
  proxy_auth = [
    {
      groups = ["home"]
      apps = {
        "apps-qbittorrent" = {
          name  = "QBitTorrent"
          host  = "https://torrent.kalexlab.xyz"
          group = "media"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/qbittorrent.svg"
        }
        "apps-sonarr" = {
          name  = "Sonarr"
          host  = "https://sonarr.kalexlab.xyz"
          group = "media"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sonarr.svg"
        }
        "apps-radarr" = {
          name  = "Radarr"
          host  = "https://radarr.kalexlab.xyz"
          group = "media"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg"
        }
        "apps-prowlarr" = {
          name  = "Prowlarr"
          host  = "https://prowlarr.kalexlab.xyz"
          group = "media"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg"
        }
        "apps-navidrome" = {
          name  = "Navidrome"
          host  = "https://music.kalexlab.xyz"
          group = "media"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/navidrome.svg"
        }
        "apps-get-music" = {
          name  = "Music Downloader"
          host  = "https://get.music.kalexlab.xyz"
          group = "media"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/youtube-music.svg"
        }
        "apps-plants" = {
          name  = "Plants"
          host  = "https://plants.kalexlab.xyz"
          group = "apps"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/hortusfox.webp"
        }
      }
    },

    {
      groups = ["infra"]
      apps = {
        "infra-hubble" = {
          name  = "Hubble"
          host  = "https://hubble.kalexlab.xyz"
          group = "infra"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/cilium.svg"
        }
        "infra-traefik" = {
          name  = "Traefik"
          host  = "https://traefik.kalexlab.xyz"
          group = "infra"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/traefik.svg"
        }
        "infra-longhorn" = {
          name  = "Longhorn"
          host  = "https://longhorn.kalexlab.xyz"
          group = "infra"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/longhorn.svg"
        }
        "infra-adguard" = {
          name  = "AdGuard Home"
          host  = "https://adguard.dns.kalexlab.xyz"
          group = "infra"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/adguard-home.svg"
        }
        "infra-ddns" = {
          name  = "DDNS Updater"
          host  = "https://ddns.kalexlab.xyz"
          group = "infra"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ddns-updater.svg"
        }
        "infra-cabling" = {
          name  = "Cabling"
          host  = "https://cabling.kalexlab.xyz"
          group = "infra"
          icon  = "https://img.icons8.com/stickers/256/ethernet-on.png"
        }
        "infra-backups" = {
          name  = "Backups"
          host  = "https://ui.backups.kalexlab.xyz"
          group = "infra"
          icon  = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/seaweedfs.svg"
        }
        "monitoring-prometheus" = {
          name  = "Prometheus"
          host  = "https://prometheus.kalexlab.xyz"
          group = "monitoring"
          icon  = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prometheus.svg"
        }
      }
    },
  ]

  // Flattened views of the rules above.
  //
  // `proxy_apps` is every application, keyed by slug - the outpost reads its
  // provider list straight off the resulting resource collection, so a new entry
  // wires itself up with no further edits.
  proxy_apps = merge([for rule in local.proxy_auth : rule.apps]...)

  // One entry per (application, group) pair. Several bindings on one application
  // are OR'd, so listing a group in more than one rule simply grants access.
  proxy_access = merge([
    for rule in local.proxy_auth : {
      for pair in setproduct(keys(rule.apps), rule.groups) :
      "${pair[0]}--${pair[1]}" => { app = pair[0], group = pair[1] }
    }
  ]...)

  group_ids = {
    home  = authentik_group.home.id
    infra = authentik_group.infra.id
    dev   = authentik_group.dev.id
  }
}

resource "authentik_provider_proxy" "app" {
  for_each = local.proxy_apps

  name          = each.value.name
  mode          = "forward_single"
  external_host = each.value.host

  authorization_flow = authentik_flow.authorization_implicit.uuid
  invalidation_flow  = authentik_flow.app_invalidation.uuid
}

resource "authentik_application" "proxy" {
  for_each = local.proxy_apps

  name              = each.value.name
  slug              = each.key
  group             = var.application_groups[each.value.group]
  meta_icon         = each.value.icon
  meta_launch_url   = each.value.host
  protocol_provider = authentik_provider_proxy.app[each.key].id
}

resource "authentik_policy_binding" "proxy_access" {
  for_each = local.proxy_access

  target = authentik_application.proxy[each.value.app].uuid
  group  = local.group_ids[each.value.group]
  order  = 0
}
