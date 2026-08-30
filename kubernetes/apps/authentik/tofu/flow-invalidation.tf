resource "authentik_flow" "app_invalidation" {
  name           = "KalexLab IdP App Logout"
  slug           = "app-invalidation"
  title          = "You've logged out of %(app)s."
  designation    = "invalidation"
  authentication = "none"
}

resource "authentik_flow" "invalidation" {
  name           = "KalexLab IdP Logout"
  slug           = "invalidation"
  title          = "KalexLab IdP Logout"
  designation    = "invalidation"
  authentication = "none"
}

resource "authentik_stage_user_logout" "logout_stage" {
  name = "user-logout-stage"
}

resource "authentik_flow_stage_binding" "invalidation_0_logout" {
  target = authentik_flow.invalidation.uuid
  stage  = authentik_stage_user_logout.logout_stage.id
  order  = 0
}
