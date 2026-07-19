# Continuwuity

[Continuwuity](https://continuwuity.org/) is a community-driven Matrix homeserver
written in Rust, the official continuation of the
[conduwuit](https://github.com/girlbossceo/conduwuit) homeserver.

This YunoHost package installs a prebuilt static binary (musl) from the
upstream Forgejo release, so it works on any `amd64` or `arm64` YunoHost
instance without needing a Rust toolchain or compiling anything.

## What this package does

- Installs the continuwuity binary in `/var/www/continuwuity/continuwuity`.
- Stores the database and media in `/home/yunohost.app/continuwuity/`.
- Runs continuwuity as a dedicated system user via a systemd service
  (`continuwuity.service`), listening on `127.0.0.1:6167` by default.
- Configures nginx to proxy `/_matrix` and `/_continuwuity` to the homeserver.
- Publishes `.well-known/matrix/server` and `.well-known/matrix/client` on the
  chosen `server_name` domain (if that domain is managed by YunoHost), so that
  Matrix user-ids look like `@user:server_name` and federation works on port
  443 (no need to open port 8448 on the firewall).
- Generates a random registration token at install time if registration is
  enabled. The token is shown at the end of the install and is available
  afterwards in the config panel.

## Installation

Install from the YunoHost web admin or CLI:

```bash
sudo yunohost app install https://github.com/thibaultmol/continuwuity-yunohost
```

You will be asked for:

- **Domain** — the root domain where continuwuity is served (e.g.
  `matrix.example.tld`). Must be a root domain (no subpath).
- **Visibility** — leave to "visitors" if you want federation to work.
- **server_name** — the Matrix server_name. If you pick a base domain like
  `example.tld` (and it's managed by YunoHost), Continuwuity publishes
  `.well-known` delegation so user-ids are `@user:example.tld` while the
  homeserver itself still runs on `matrix.example.tld`. **Cannot be changed
  later without wiping the database.**
- **Allow registration** — if yes, a token is generated and printed at the
  end of the install.
- **Enable federation** — communicate with other Matrix homeservers.

## First user

The first user to register (using the registration token, if registration is
enabled) becomes the instance's first admin. They are added to the
`#admin:server_name` room and can issue admin commands there (prefix with
`!admin`). See [the upstream admin docs](https://continuwuity.org/) for the
full command list.

If registration is disabled, you can create the first user from the admin
room of another Matrix account that you federate in, or — more simply —
temporarily enable registration in the config panel, register, then disable
it again.

## Configuration

Most settings are left at the upstream defaults and can be tweaked from the
YunoHost config panel (`yunohost app config continuwuity`). For anything not
exposed there, you can edit `/var/www/continuwuity/continuwuity.toml` directly.
YunoHost will detect manual changes (via a checksum) and back up your version
before overwriting it on upgrade, but you'll miss out on new upstream
defaults — so prefer the config panel when possible.

The full list of options is documented at
<https://continuwuity.org/configuration.html>.

## Upgrading

Upgrades replace the binary and regenerate the config file from the
template. The database is preserved. Manual edits to
`continuwuity.toml` are backed up if the checksum changed.

## Backups

`yunohost app backup continuwuity` backs up:

- `/var/www/continuwuity/` (binary + config)
- `/home/yunohost.app/continuwuity/` (database + media — can be large)
- nginx and systemd configs

The data dir is **not** backed up during the automatic safety backup before
upgrades (YunoHost core behaviour for `data_dir`), but it is included in
manual backups.

## Known limitations

- **Not on subpaths.** Matrix requires a root domain. Subpath installs are
  excluded from the CI tests and not supported.
- **server_name is immutable.** Changing it requires wiping the database.
  Choose carefully at install time.
- **Architecture.** Only `amd64` and `arm64` are supported, matching the
  upstream prebuilt static binaries.
- **No SSO/LDAP.** Matrix has its own account model; SSOwat/LDAP integration
  is `not_relevant` for this app.
