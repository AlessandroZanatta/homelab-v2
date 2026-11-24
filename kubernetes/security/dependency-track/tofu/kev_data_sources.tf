resource "dependencytrack_extension_config" "kev_cisa" {
  provider        = dependencytrackv5
  extension_point = "kev-data-source"
  extension       = "cisa"

  config = jsonencode({
    enabled = true
    feedUrl = "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json"
  })
}

resource "dependencytrack_extension_config" "kev_enisa" {
  provider        = dependencytrackv5
  extension_point = "kev-data-source"
  extension       = "enisa"

  config = jsonencode({
    enabled = true
    feedUrl = "https://raw.githubusercontent.com/enisaeu/CNW/main/eukev/eukev.json"
  })
}

resource "dependencytrack_extension_config" "kev_vulncheck" {
  provider        = dependencytrackv5
  extension_point = "kev-data-source"
  extension       = "vulncheck"

  config = jsonencode({
    enabled = true
    apiUrl  = "https://api.vulncheck.com"
    # Secret name = env var DT_SECRET_VULNCHECK_TOKEN minus the prefix (case preserved)
    apiToken = "VULNCHECK_TOKEN"
  })
}
