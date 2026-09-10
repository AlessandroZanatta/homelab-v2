data "authentik_outpost" "embedded" {
  name = "authentik Embedded Outpost"
}

import {
  to = authentik_outpost.embedded
  id = data.authentik_outpost.embedded.id
}

resource "authentik_outpost" "embedded" {
  name = data.authentik_outpost.embedded.name

  // Collected from the forward-auth applications in apps-proxy-auth.tf
  protocol_providers = [for p in authentik_provider_proxy.app : p.id]

  config = jsonencode({
    authentik_host                   = "https://auth.kalexlab.xyz"
    authentik_host_browser           = ""
    authentik_host_insecure          = false
    container_image                  = null
    docker_labels                    = null
    docker_map_ports                 = true
    docker_network                   = null
    kubernetes_disable_x509_strict   = false
    kubernetes_disabled_components   = ["traefik middleware"]
    kubernetes_httproute_annotations = {}
    kubernetes_httproute_parent_refs = []
    kubernetes_image_pull_secrets    = []
    kubernetes_ingress_annotations   = {}
    kubernetes_ingress_class_name    = null
    kubernetes_ingress_path_type     = null
    kubernetes_ingress_secret_name   = "authentik-outpost-tls"
    kubernetes_namespace             = "authentik"
    kubernetes_replicas              = 2
    kubernetes_service_type          = "ClusterIP"
    log_level                        = "info"
    object_naming_template           = "ak-outpost-%(name)s"
    refresh_interval                 = "minutes=5"

    # Make the outpost highly-available too (not needed for embedded outpost!)
    # kubernetes_json_patches = {
    #   service = [
    #     {
    #       op    = "add"
    #       path  = "/metadata/annotations"
    #       value = {}
    #     },
    #     {
    #       op    = "add"
    #       path  = "/metadata/annotations/gatus.kalexlab.xyz~1enabled"
    #       value = "true"
    #     },
    #     {
    #       op    = "add"
    #       path  = "/metadata/annotations/gatus.kalexlab.xyz~1port"
    #       value = "http"
    #     },
    #     {
    #       op    = "add"
    #       path  = "/metadata/annotations/gatus.kalexlab.xyz~1endpoint"
    #       value = <<-EOT
    #         conditions:
    #           - "[STATUS] == 400"
    #       EOT
    #     },
    #   ]
    #   deployment = [
    #     {
    #       op   = "add"
    #       path = "/spec/template/spec/topologySpreadConstraints"
    #       value = [{
    #         maxSkew           = 1
    #         topologyKey       = "kubernetes.io/hostname"
    #         whenUnsatisfiable = "DoNotSchedule"
    #         labelSelector = {
    #           matchLabels = {
    #             "app.kubernetes.io/name" = "authentik-outpost-proxy"
    #             # Must match this resource name
    #             "goauthentik.io/outpost-name" = "proxy"
    #           }
    #         }
    #       }]
    #     },
    #   ]
    # }
  })
}
