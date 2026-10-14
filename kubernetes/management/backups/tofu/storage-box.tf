data "sops_file" "backups" {
  source_file = "${path.module}/../manifests/secrets.sops.yaml"
}

locals {
  templates = {
    for t in yamldecode(data.sops_file.backups.raw).spec.secretTemplates :
    t.name => t.stringData
  }

  storage_box_password = local.templates["hetzner-backup"].storage_box_password
  subaccount_password  = local.templates["hetzner-backup"].subaccount_password
}

resource "hcloud_storage_box" "homelab_backup" {
  name             = "homelab-backup"
  storage_box_type = "bx11"
  location         = "fsn1"
  password         = local.storage_box_password

  access_settings = {
    ssh_enabled          = true
    reachable_externally = true
    zfs_enabled          = true
    samba_enabled        = false
    webdav_enabled       = false
  }

  snapshot_plan = {
    max_snapshots = 10 # 10 is the most snapshots given for bx11
    hour          = 3
    minute        = 0
    day_of_week   = 1
  }

  delete_protection = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_storage_box_subaccount" "rclone" {
  storage_box_id = hcloud_storage_box.homelab_backup.id
  name           = "rclone"
  home_directory = "backups"
  password       = local.subaccount_password

  access_settings = {
    ssh_enabled          = true
    reachable_externally = true
    readonly             = false
  }
}

output "rclone_host" { value = hcloud_storage_box_subaccount.rclone.server }
output "rclone_user" { value = hcloud_storage_box_subaccount.rclone.username }
