# DT v5 vulnerability data sources. PUT replaces the whole config: list every field.
# Schemas: GET /api/v2/extension-points/vuln-data-source/extensions/{name}/config-schema

resource "dependencytrack_extension_config" "osv" {
  provider        = dependencytrackv5
  extension_point = "vuln-data-source"
  extension       = "osv"

  config = jsonencode({
    enabled                     = true
    aliasSyncEnabled            = true
    incrementalMirroringEnabled = true
    dataUrl                     = "https://storage.googleapis.com/osv-vulnerabilities"
    # Full list: https://storage.googleapis.com/osv-vulnerabilities/ecosystems.txt
    ecosystems = [
      # Container base OS packages
      "Alpine",
      "Debian",
      "Ubuntu",
      "Red Hat",
      "AlmaLinux",
      "Rocky Linux",
      "SUSE",
      "openSUSE",
      "Wolfi",
      "Chainguard",
      # Language ecosystems
      "Go",
      "npm",
      "PyPI",
      "Maven",
      "crates.io",
      "NuGet",
      "Packagist",
      "RubyGems",
      "Hex",
      "Pub",
      "Hackage",
      "GHC",
      "CRAN",
      "Julia",
      "SwiftURL",
      "opam",
    ]
  })
}

resource "dependencytrack_extension_config" "github" {
  provider        = dependencytrackv5
  extension_point = "vuln-data-source"
  extension       = "github"

  config = jsonencode({
    enabled          = true
    aliasSyncEnabled = true
    apiUrl           = "https://api.github.com/graphql"
    # Secret name = env var DT_SECRET_GITHUB_TOKEN minus the prefix (case preserved)
    apiToken = "GITHUB_TOKEN"
  })
}

resource "dependencytrack_extension_config" "nvd" {
  provider        = dependencytrackv5
  extension_point = "vuln-data-source"
  extension       = "nvd"

  config = jsonencode({
    enabled     = true
    cveFeedsUrl = "https://nvd.nist.gov/feeds"
  })
}
