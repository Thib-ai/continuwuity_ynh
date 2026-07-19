# AGENTS.md — maintaining the continuwuity YunoHost app package

This file documents **how to update this YunoHost app package** when a new
version of Continuwuity is released upstream, and what to watch out for. It
is meant for human maintainers and AI agents alike.

## Reference material (vendored, gitignored)

The following directories are vendored into this repo **only** for local
reference while developing the package. They are listed in `.gitignore` and
must never be committed:

- `continuwuity/` — a checkout of the upstream Continuwuity source code.
  Pin it to the tag you're packaging (see the update workflow below).
- `yunohost-doc-reference/` — the YunoHost documentation repo (packaging
  guides, helpers).
- `conduit_ynh/`, `synapse_ynh/`, `tuwunel_ynh/` — reference YunoHost app
  packages for other Matrix homeservers. Useful for cross-checking nginx,
  systemd, and well-known patterns.

When in doubt about a Yunohost packaging question, consult
`doc/docs/dev/50.packaging/` first.

## High-level design

This package installs a **prebuilt static binary** of continuwuity (musl
build, no glibc dependency) from the upstream Forgejo release. It does
**not** compile anything. Sources are declared in `manifest.toml` under
`[resources.sources.main]`, with per-arch `amd64.url`/`sha256` and
`arm64.url`/`sha256`. The `autoupdate` block lets the YunoHost infra
auto-bump the manifest when a new Forgejo release is published.

Run layout (on the installed server):

| What                 | Path                                              |
| -------------------- | ------------------------------------------------- |
| Binary               | `/var/www/$app/continuwuity` (executable)         |
| Config (TOML)        | `/var/www/$app/continuwuity.toml`                  |
| Database + media     | `/home/yunohost.app/$app/` (the `data_dir`)        |
| Systemd unit         | `/etc/systemd/system/$app.service`                 |
| nginx (app)          | `/etc/nginx/conf.d/$domain.d/$app.conf`            |
| nginx (.well-known)  | `/etc/nginx/conf.d/$server_name.d/${app}_server_name.conf` |
| Listen port          | `127.0.0.1:6167` (booked via `resources.ports.main`) |

The homeserver listens only on localhost; nginx proxies `/_matrix` and
`/_continuwuity` to it. Federation runs over the standard HTTPS port 443 —
**no need to open port 8448** because this package publishes
`.well-known/matrix/server` pointing to `$domain:443`.

## Update workflow — bumping the upstream version

When a new Continuwuity release comes out (e.g. `v27.0.0`):

1. **Update the vendored upstream checkout** so you can diff the example
   config and the systemd unit:
   ```bash
   cd continuwuity
   git fetch --tags
   git checkout v27.0.0      # the tag you're packaging
   ```
   Don't commit this — it's gitignored.

2. **Find the release on Forgejo** and note the new static binary asset URLs.
   They follow the pattern:
   ```
   https://forgejo.ellis.link/continuwuation/continuwuity/releases/download/vX.Y.Z/conduwuit-linux-static-amd64
   https://forgejo.ellis.link/continuwuation/continuwuity/releases/download/vX.Y.Z/conduwuit-linux-static-arm64
   ```
   Yes, the binary is named `conduwuit-*` even though the project is
   continuwuity — this is upstream's choice, see `Cargo.toml`
   `[workspace.metadata.crane] name = "conduwuit"`. Do **not** "fix" this.

3. **Compute the sha256** for each arch:
   ```bash
   for arch in amd64 arm64; do
     curl -sL "https://forgejo.ellis.link/continuwuation/continuwuity/releases/download/vX.Y.Z/conduwuit-linux-static-$arch" | sha256sum
   done
   ```

4. **Bump `manifest.toml`**:
   - `version = "X.Y.Z~ynh1"` (or `~ynh2`, `~ynh3`, ... if you re-package
     the same upstream version).
   - Update `amd64.url`, `amd64.sha256`, `arm64.url`, `arm64.sha256` under
     `[resources.sources.main]`. The `autoupdate.asset.*` regexes should
     keep working as-is (they match `^conduwuit-linux-static-(amd64|arm64)$`).

5. **Diff `conduwuit-example.toml`** (the generated example config in the
   upstream repo) against the previous version, and propagate any
   relevant new/changed/removed options into `conf/continuwuity.toml`. In
   particular watch for:
   - new security-relevant defaults (registration, federation, URL previews)
   - renamed config keys (continuwuity occasionally renames things — check
     `CHANGELOG.md` for `BREAKING`/`rename` entries)
   - sections like `[global.well_known]`, `[global.smtp]`, `[global.oauth]`
     that this package intentionally leaves disabled — make sure they are
     still disabled the same way.
   - Also bump the literal version string in the comment header of
     `conf/continuwuity.toml` (the line starting with
     `# Generated from conduwuit-example.toml of continuwuity vX.Y.Z`).
     It's a comment, not a template token — do NOT use a `__UPSTREAM_VERSION__`
     placeholder, that breaks `ynh_config_add` (see commit history for the
     bug where it aborted installs with "Variable $upstream_version wasn't
     initialized").

6. **Diff `pkg/conduwuit.service`** (the upstream systemd unit) against
   `conf/systemd.service`. Upstream sometimes adds new sandboxing options
   or changes the `ExecStart=` / `Environment=` lines. This package uses a
   simpler unit than upstream (we don't use `LoadCredential=` /
   `DynamicUser=` because YunoHost creates the system user for us via the
   `system_user` resource) — don't blindly copy upstream's unit, just merge
   the meaningful sandboxing additions.

7. **Check `CHANGELOG.md`** in the upstream repo for breaking changes that
   need a `doc/PRE_UPGRADE.md` note. If there's a database migration, a
   config key rename, or an incompatible default, add a
   `doc/PRE_UPGRADE.d/X.Y.Z~ynh1.md` file explaining what to expect.

8. **Test locally before pushing**:
   ```bash
   # Lint the manifest + scripts
   python3 -m pip install --user git+https://github.com/YunoHost/package_linter
   yunohost-linter .

   # Install on a test YunoHost (or LXC via package_check)
   sudo yunohost app install ./path/to/continuwuity-yunohost --debug
   # Verify:
   #   - service starts: systemctl status continuwuity
   #   - .well-known resolves: curl https://$server_name/.well-known/matrix/server
   #   - client API answers:  curl https://$domain/_matrix/client/versions
   #   - register a user with the token from the end-of-install output
   #   - upgrade test: sudo yunohost app upgrade continuwuity -F .
   ```

9. **Commit and push**. Use a commit message like
   `Upgrade to upstream v27.0.0`. The YunoHost infra's autoupdate bot may
   have already opened a PR — if so, review and merge it after doing the
   steps above.

## Things to watch out for

### `server_name` is immutable

The Matrix `server_name` (chosen at install time via the `server_name`
question) is baked into every user-id and room-id on the server. Changing
it requires wiping the database. The package **does not** support changing
it after install. If a user asks for this, the only answer is: backup,
remove, reinstall with the new server_name, restore (the data won't be
directly compatible if the server_name changed — you're effectively
starting over).

Do not add `server_name` to `config_panel.toml`.

### `.well-known` delegation only works if YunoHost manages the server_name domain

The package installs `conf/server_name.conf` to
`/etc/nginx/conf.d/$server_name.d/${app}_server_name.conf` **only if**
`$server_name` appears in `yunohost domain list`. If the user picks a
`server_name` that YunoHost doesn't manage (e.g. a domain they own but
host elsewhere), the install/upgrade scripts silently skip the
`.well-known` config — the user has to publish delegation themselves on
the `server_name` domain. `doc/ADMIN.md` documents this.

When adding any code that touches this conf, **always guard it with**:
```bash
if yunohost --output-as plain domain list | grep -q "^$server_name$"; then
    ...
fi
```
Otherwise the install will fail when `server_name` != `domain` and
`server_name` isn't managed by YunoHost.

### Boolean settings: TOML wants `true`/`false`, YunoHost stores `0`/`1`

YunoHost `boolean` install questions arrive in scripts as the strings
`"0"` or `"1"`. The config panel `bind = "key:file"` mechanism writes the
panel's `yes`/`no` values (we set those to `true`/`false`). So the same
setting can be `0`/`1` or `true`/`false` depending on where it came from.

`scripts/_common.sh` defines `normalise_bool` for this. The TOML file
must always end up with literal `true`/`false` (without quotes) — the
`conf/continuwuity.toml` template uses `__ALLOW_REGISTRATION__` and
`__ALLOW_FEDERATION__` which get substituted with the normalised value.
If you add new boolean settings, follow the same pattern.

### Config file edits on upgrade

`ynh_config_add` computes a checksum of the destination file at install
time. On upgrade, if the admin has edited `continuwuity.toml` by hand
(checksum mismatch), `ynh_config_add` backs up their version before
overwriting — but then the admin **misses** new upstream defaults from
the updated template. This is the standard YunoHost tradeoff. There's
nothing to "fix" here; just be aware of it when reading issue reports
like "my config didn't update after the upgrade".

### The data dir is large and excluded from safety backups

YunoHost core excludes `data_dir` from the automatic pre-upgrade safety
backup (and from backups when `do_not_backup_data=1`). The full data dir
is included in manual backups. This is standard for database-backed apps
but worth knowing: if an upgrade fails badly enough that the package is
removed, the data dir is **not** deleted (unless `--purge` is used), so
the admin can retry the upgrade without data loss.

### Static binary, no apt dependencies

The binary is statically linked (musl). The package declares **no**
`[resources.apt]` block. Do not add one unless a future upstream release
introduces a dynamic dependency — that would be a packaging regression
worth raising with upstream.

### Architecture support

Only `amd64` and `arm64` are in `manifest.toml`'s `architectures` list,
matching the two static binary assets upstream publishes. If upstream
adds `armhf`/`i386` static binaries, you can add them; otherwise leave it.

Upstream also publishes `-haswell` (amd64 with AVX2) and `-maxperf`
(LTO-optimized) variants. We intentionally ship the plain
`-static-` variants for maximum compatibility. Don't switch to
`-haswell` without a way to detect the CPU at install time.

### Autoupdate

`[resources.sources.main].autoupdate` is configured with
`strategy = "latest_forgejo_release"` (the upstream code repo is on
Forgejo at `forgejo.ellis.link/continuwuation/continuwuity`, matching the
`[upstream].code` URL). The asset regexes
(`^conduwuit-linux-static-amd64$` / `arm64`) match the plain static
binaries. The bot will open PRs to bump `version`, `*.url`, and `*.sha256`
automatically; you still need to do the manual diff/test steps above
before merging.

To test the autoupdate config locally:
```bash
git clone https://github.com/YunoHost/apps_tools
cd apps_tools
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
./autoupdate_app_sources/autoupdate_app_sources.py /path/to/continuwuity-yunohost
```

### Nginx subpath is unsupported

Matrix requires a root domain. `tests.toml` excludes `install.subdir` and
`install.private`. If someone tries to install on a subpath via the CLI,
YunoHost will let them but the homeserver will be broken — this is a
known limitation, not a bug.

### `main.url = "/"` and `show_tile = false`

The `main` permission has `show_tile = false` because the root URL just
returns "This is where Continuwuity is installed." (a plain-text landing
page). There's nothing useful to put in the SSO portal. The actual
client-facing entry points are the `/_matrix` API (covered by the
`server_api` permission) and `/_continuwuity` (account management UI).

### Don't proxy `/` blindly to continuwuity

The nginx conf proxies `/_matrix` and `/_continuwuity` to the homeserver,
but **not** `/`. Proxying `/` would conflict with other apps if this
domain ever hosts other things, and would also expose continuwuity's
landing page to anyone hitting the domain root. Keep the current pattern.

### Post-install message with the registration token

`scripts/install` prints the registration token with `ynh_print_info` at
the end of the install. This is the only place the user sees it in clear
(they can also find it later in the config panel). If you change the
install flow, make sure this still works — users will rely on it.

### `conduwuit` vs `continuwuity` naming

The project was renamed from `conduwuit` to `continuwuity`, but:

- The binary file is still called `conduwuit` (see
  `Cargo.toml` `[workspace.metadata.crane]`).
- The systemd unit shipped by upstream is `conduwuit.service`.
- The release assets are `conduwuit-linux-static-*`.
- The config env var prefix is `CONTINUWUITY_` (this changed in a recent
  release — older versions used `CONDUWUIT_`).

This package uses the **new** `CONTINUWUITY_` env var prefix and the
`continuwuity` app id / binary name on the YunoHost side, but the
**downloaded binary** is still named `conduwuit-linux-static-*` from the
Forgejo release — that's why `rename = "continuwuity"` is set in the
sources resource, so the binary lands at `$install_dir/continuwuity`.

If upstream renames the binary in a future release, update:
- the `autoupdate.asset.*` regexes in `manifest.toml`
- the `amd64.url` / `arm64.url` URLs
- the `rename` value (probably remove it)

## Common mistakes to avoid

- **Don't add a `path` install question.** Matrix needs a root domain.
- **Don't open port 8448 on the firewall.** Federation runs over 443 via
  `.well-known` delegation. Adding a `resources.ports` entry with
  `exposed = "TCP"` for 8448 would be wrong.
- **Don't use upstream's `DynamicUser=yes` / `LoadCredential=` in the
  systemd unit.** YunoHost creates the system user for us via the
  `system_user` resource, and we ship the config as a plain file in
  `$install_dir` rather than as a credential.
- **Don't enable `admin_console_automatic` in the config.** It requires
  a TTY and crashes the service on a headless server (upstream fixed
  this in 26.6.2 but it's still off by default for a reason).
- **Don't forget to regenerate `conf/continuwuity.toml` on upgrade.**
  The upgrade script calls `ynh_config_add` for it — keep that line.

## Useful upstream references

- Release page: <https://forgejo.ellis.link/continuwuation/continuwuity/releases>
- Source: <https://forgejo.ellis.link/continuwuation/continuwuity>
- Docs: <https://continuwuity.org/>
- Config reference: <https://continuwuity.org/configuration.html>
- Delegation guide: <https://continuwuity.org/guides/delegation>
- Example config (in source repo): `conduwuit-example.toml`
- Upstream systemd unit (in source repo): `pkg/conduwuit.service`
- Changelog (in source repo): `CHANGELOG.md`

## Useful YunoHost references

- Packaging docs: <https://yunohost.org/dev/packaging>
- Manifest v2 schema: <https://github.com/YunoHost/apps/blob/master/schemas/manifest.v2.schema.json>
- Helpers v2.1: <https://yunohost.org/dev/packaging/scripts/helpers_v2.1>
- Package linter: <https://github.com/YunoHost/package_linter>
- Package check (CI): <https://github.com/YunoHost/package_check>
- App catalog policy: <https://yunohost.org/dev/packaging/policy>
- Autoupdate tool: <https://github.com/YunoHost/apps_tools>
