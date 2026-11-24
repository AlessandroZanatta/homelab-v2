resource "dependencytrack_oidc_group" "admin" {
  name = "admin"
}

resource "dependencytrack_oidc_group_mapping" "example" {
  group = dependencytrack_oidc_group.admin.id
  team  = data.dependencytrack_team.administrators.id
}
