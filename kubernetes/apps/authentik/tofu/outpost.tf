# Proxy outpost, declared rather than adopting authentik's embedded one.
resource "authentik_service_connection_kubernetes" "local" {
  name  = "local-cluster"
  local = true
}

resource "authentik_outpost" "proxy" {
  name               = "proxy-outpost"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.local.id

  // Collected from the forward-auth applications in apps-proxy-auth.tf. The
  // API rejects an outpost with no providers, so this must stay non-empty.
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
    kubernetes_disabled_components   = []
    kubernetes_httproute_annotations = {}
    kubernetes_httproute_parent_refs = []
    kubernetes_image_pull_secrets    = []
    kubernetes_ingress_annotations   = {}
    kubernetes_ingress_class_name    = null
    kubernetes_ingress_path_type     = null
    kubernetes_ingress_secret_name   = "authentik-outpost-tls"
    kubernetes_json_patches          = null
    kubernetes_namespace             = "authentik"
    kubernetes_replicas              = 1
    kubernetes_service_type          = "ClusterIP"
    log_level                        = "info"
    object_naming_template           = "ak-outpost-%(name)s"
    refresh_interval                 = "minutes=5"
  })
}
