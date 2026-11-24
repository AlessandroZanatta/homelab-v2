data "dependencytrack_team" "administrators" {
  name = "Administrators"
}

resource "dependencytrack_team" "sbom_operator" {
  name = "sbom-operator"
}

resource "dependencytrack_team_permissions" "sbom_operator" {
  team = dependencytrack_team.sbom_operator.id
  permissions = [
    "BOM_UPLOAD",
    "PROJECT_CREATION_UPLOAD",
    # Creates, tags, deactivates and deletes projects
    "PORTFOLIO_MANAGEMENT",
    "VIEW_PORTFOLIO",
  ]
}

resource "dependencytrack_team_apikey" "sbom_operator" {
  team    = dependencytrack_team.sbom_operator.id
  comment = "sbom-operator"
}

output "sbom_operator_api_key" {
  value     = dependencytrack_team_apikey.sbom_operator.key
  sensitive = true
}
