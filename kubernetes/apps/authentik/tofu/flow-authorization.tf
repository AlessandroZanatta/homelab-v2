resource "authentik_flow" "authorization_implicit" {
  name           = "KalexLab IdP Implicit Authorization"
  slug           = "authorization-implicit"
  title          = "Redirecting to %(app)s"
  designation    = "authorization"
  authentication = "require_authenticated"
}

resource "authentik_flow" "authorization_explicit" {
  name           = "KalexLab IdP Explicit Authorization"
  slug           = "authorization-explicit"
  title          = "Redirecting to %(app)s"
  designation    = "authorization"
  authentication = "require_authenticated"
}

resource "authentik_stage_consent" "authorization" {
  name              = "authorization-consent-stage"
  mode              = "expiring"
  consent_expire_in = "days=365"
}

resource "authentik_flow_stage_binding" "authorization_explicit_0_consent" {
  target = authentik_flow.authorization_explicit.uuid
  stage  = authentik_stage_consent.authorization.id
  order  = 0
}
