resource "authentik_user" "kalex" {
  username = "kalex"
  name     = "Alessandro Zanatta"
  email    = "alessandro.zanatta.lav@gmail.com"
  path     = "users/home"

  groups = [
    authentik_group.authentik_admin.id,
    authentik_group.infra.id,
    authentik_group.dev.id,
    authentik_group.home.id,
  ]

  attributes = jsonencode({
    avatar = "https://cdn.discordapp.com/avatars/260044372811186176/c83538847142e8018a9c0d6d9a8bc265.webp"
  })
}

resource "authentik_user" "laetitia" {
  username = "laetitia"
  name     = "Letizia Polla"
  email    = "letiziapolla@gmail.com"
  path     = "users/home"

  groups = [
    authentik_group.home.id
  ]
}
