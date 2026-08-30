// Generic group: authentication is gated on having this role,
// users without this (e.g. akadmin, ...) are not allowed.
resource "authentik_group" "user" {
  name = "user"
}

// Authentik super admin: the only group that can use the admin interface.
// Membership is granted explicitly rather than implied by `infra`, so
// administering authentik stays a deliberate grant.
resource "authentik_group" "authentik_admin" {
  name         = "authentik-admin"
  is_superuser = true

  parents = [authentik_group.user.id]
}

resource "authentik_group" "infra" {
  name = "infra"

  parents = [authentik_group.user.id]
}

resource "authentik_group" "home" {
  name = "home"

  parents = [authentik_group.user.id]
}

resource "authentik_group" "dev" {
  name = "dev"

  parents = [authentik_group.user.id]
}
