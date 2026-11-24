resource "dependencytrack_config_property" "base_url" {
  group = "general"
  name  = "base.url"
  type  = "URL"
  value = "https://dtrack.kalexlab.xyz"
}

resource "dependencytrack_config_property" "telemetry" {
  group = "telemetry"
  name  = "submission.enabled"
  type  = "BOOLEAN"
  value = "false"
}
