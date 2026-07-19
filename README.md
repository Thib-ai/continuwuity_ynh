# Continuwuity

YunoHost app package for the [Continuwuity](https://continuwuity.org/) Matrix
homeserver (v26.6.2).

This repository contains **only the YunoHost app package** (manifest, scripts,
conf, docs). The upstream continuwuity source and reference YunoHost packages
for other Matrix servers are vendored locally (gitignored) for convenience
during development — see `.gitignore`.

## Install

```bash
sudo yunohost app install https://github.com/thibaultmol/continuwuity-yunohost
```

See `doc/DESCRIPTION.md` and `doc/PRE_INSTALL.md` for user-facing
documentation.

## Layout

```
continuwuity-yunohost/
├── manifest.toml          # App manifest (v2 packaging format)
├── config_panel.toml      # YunoHost config panel (registration / federation)
├── tests.toml             # CI test config
├── conf/
│   ├── continuwuity.toml  # Template for the upstream TOML config
│   ├── nginx.conf         # nginx reverse proxy -> 127.0.0.1:$port
│   ├── server_name.conf   # .well-known/matrix/{server,client,support}
│   └── systemd.service    # systemd unit
├── scripts/
│   ├── _common.sh         # Shared helpers (boolean normalisation)
│   ├── install
│   ├── upgrade
│   ├── remove
│   ├── backup
│   ├── restore
│   ├── change_url
│   └── config             # Custom getters/setters for the config panel
├── doc/                   # YunoHost-facing docs (PRE_INSTALL, POST_INSTALL, …)
├── AGENTS.md              # Notes for maintainers / AI agents
└── README.md              # This file
```

## Maintainer notes

Read [`AGENTS.md`](AGENTS.md) before updating the package. It documents the
update workflow, the gotchas around the `server_name` / `.well-known`
delegation, the static-binary download strategy, and what to watch out for
when bumping the upstream version.

## License

The package itself is distributed under the same license as the upstream
project (Apache-2.0). See `LICENSE`.
