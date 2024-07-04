# Role Name

Setups a restic backup server via sftp.
Additionally setups clients to back-up specified paths.

## Role Variables

Must define the following variables. These variables do not have a default as they are setup-dependent.

```yaml
# Must be set
restic_retention:
  # Must be set
  policy:
    keep-last:
    keep-hourly:
    keep-daily:
    keep-weekly:
    keep-monthly:
    keep-yearly:
    keep-tag:
  # Must be set
  cron:
    minute:
    hour:
    day:
    month:

# Must be set
restic_backup:
  # Must be set
  cron:
    minute:
    hour:
    day:
    month:

  # Must be set
  # Common paths to include/ignore in the backup
  # Merged with host specific rules, if any
  common:
    paths: []
    exclude_paths: []

  # Must be set
  hosts:
    # Each host can have different folders to include/ignore
    myhost:
      paths: []
      exclude_paths: []
```

## Dependencies

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

## Example Playbook

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

## License

BSD

## Author Information

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
