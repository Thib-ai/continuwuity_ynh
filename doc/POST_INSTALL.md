# Continuwuity — post-install notes

## Your registration token

If you enabled registration, your registration token is:

```
__REGISTRATION_TOKEN__
```

Use a Matrix client (Element, FluffyChat, SchildiChat, etc.) to register on
`https://__DOMAIN__` with this token. The first user you create becomes the
instance's first admin.

If you did **not** enable registration, you can temporarily enable it later
from the YunoHost config panel — a token will be generated automatically.

## Your Matrix IDs

User-ids on this server look like `@username:__SERVER_NAME__`.

The homeserver is reachable at `https://__DOMAIN__`. Federation is published
via `.well-known` on `__SERVER_NAME__` (if that domain is managed by this
YunoHost instance).

## Admin commands

Admin commands are issued from the admin room (`#admin:__SERVER_NAME__`),
which the first admin is auto-joined to. Prefix commands with `!admin`, e.g.:

- `!admin users create @bob:__SERVER_NAME__`
- `!admin server notice "hello world"`
- `!admin token` — manage additional registration tokens

Full list: <https://continuwuity.org/>

## Logs

```bash
sudo journalctl -u continuwuity.service -f
```

## Configuration

```bash
sudo yunohost app config continuwuity
```
