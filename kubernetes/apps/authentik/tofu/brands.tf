resource "authentik_brand" "kalexlab" {
  domain         = "auth.kalexlab.xyz"
  default        = false
  branding_title = "KalexLab IdP"

  branding_favicon = "/static/dist/assets/icons/icon.png"
  branding_logo    = "/static/dist/assets/icons/icon_left_brand.svg"

  flow_authentication = authentik_flow.authentication.uuid
  flow_device_code    = null
  flow_invalidation   = authentik_flow.invalidation.uuid
  # Needed for admin-generated recovery links. The flow itself refuses any entry
  # that did not come from such a link, so this does NOT enable self-service
  # password reset. See flow-recovery.tf.
  flow_recovery      = authentik_flow.recovery.uuid
  flow_unenrollment  = null
  flow_user_settings = authentik_flow.user_settings.uuid
}
