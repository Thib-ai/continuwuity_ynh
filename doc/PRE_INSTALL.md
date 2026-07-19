# Continuwuity — pre-install notes

You are about to install **Continuwuity**, a Matrix homeserver.

A few important things to know before you start:

- **Dedicated root domain required.** Matrix needs a full root domain (e.g.
  `matrix.example.tld`). A subpath install like `example.tld/matrix` will
  **not** work — the install form will reject it.

- **server_name cannot be changed later.** The Matrix `server_name` is
  baked into user-ids and room IDs. Changing it requires wiping the
  database. Choose carefully. You can pick the install domain itself
  (`matrix.example.tld`) or a base domain you own (`example.tld`) for
  shorter user-ids — the latter uses `.well-known` delegation, which this
  package configures automatically if the base domain is managed by YunoHost.

- **Port 443 / federation.** Federation runs over port 443 (the standard
  HTTPS port YunoHost already exposes). You do **not** need to open port
  8448 on the firewall with this setup.

- **First admin user.** The first user that registers becomes the
  instance's first admin. If you enable registration at install, a token
  will be generated and printed at the end of the install — copy it, you
  will need it to register.

- **Disk usage.** The database and media are stored under
  `/home/yunohost.app/continuwuity/`. Start with at least 1–2 GB free; the
  manifest declares a 200 MB minimum but real usage grows with your
  federation footprint.

- **Resource use.** Continuwuity is lightweight compared to Synapse, but
  federation with large rooms can spike CPU and RAM. 1 GB RAM is a
  comfortable minimum for a small personal server.
