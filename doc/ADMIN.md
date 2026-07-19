# Continuwuity — admin notes

## Service

```bash
sudo systemctl {start,stop,restart,status} continuwuity.service
sudo journalctl -u continuwuity.service -f
```

## Database location

- Config file: `/var/www/continuwuity/continuwuity.toml`
- Database + media: `/home/yunohost.app/continuwuity/`

The database backend is RocksDB. To take a consistent backup, stop the
service first:

```bash
sudo systemctl stop continuwuity.service
sudo rsync -a /home/yunohost.app/continuwuity/ /path/to/backup/
sudo systemctl start continuwuity.service
```

Continuwuity also supports RocksDB online backups via the
`database_backup_path` config option — see the upstream maintenance docs.

## Upstream documentation

- Configuration reference: <https://continuwuity.org/configuration.html>
- Admin commands: <https://continuwuity.org/>
- Maintenance / backups: <https://continuwuity.org/maintenance.html>
- Delegation guide: <https://continuwuity.org/guides/delegation>

## Updating server_name

You can't. The `server_name` is written into every user-id and room-id. The
only way to "change" it is to wipe the database and start over. Choose
carefully at install time.

## Reconfiguring .well-known delegation

If you picked a `server_name` that is **not** managed by this YunoHost
instance, this package cannot publish `.well-known/matrix/server` and
`.well-known/matrix/client` for you. You must publish them yourself on the
`server_name` domain, e.g. via DNS + another web server, or via a static
hosting provider. See the upstream delegation guide linked above.

The expected contents are:

- `/.well-known/matrix/server` → `{"m.server": "__DOMAIN__:443"}`
- `/.well-known/matrix/client` → `{"m.homeserver": {"base_url": "https://__DOMAIN__"}}`

(replace `__DOMAIN__` with the install domain of this app.)
