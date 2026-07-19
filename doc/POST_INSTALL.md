# Continuwuity — post-install notes

## Your registration token — important, read this first

If you enabled registration, **the token printed in the install output is
NOT the one you need for the first user.** On a fresh database, continuwuity
ignores the `registration_token` from the config file and generates a
fresh **ephemeral token** on every service start, printed in the journald
startup banner. That ephemeral token is the only one that works to create
the very first user (who becomes the admin). Once that first user exists,
the config-file token becomes active again.

The banner says it like this:

> The registration token you set in your configuration will not function
> until you create an account using the token above.

To get the current ephemeral token:

```bash
sudo journalctl -u continuwuity.service -n 30 --no-pager | grep "registration token"
```

You'll see a line like:

```
Open your Matrix client of choice and register an account on __SERVER_NAME__ using the registration token Q7zi5UM3rhc7fFdQ . Pick your own username and password!
```

The token is the string between "registration token" and the period —
`Q7zi5UM3rhc7fFdQ` in this example.

**The ephemeral token rotates on every service restart** while the
database has no users. If `systemctl restart continuwuity` runs (manually
or via an upgrade), grab the new one from journald.

## Registering the first user

1. Open a Matrix client (Element, FluffyChat, SchildiChat, Cinny, …).
2. Start creating a new account / sign up.
3. Set the homeserver to `__SERVER_NAME__` (just the server_name, not the
   full URL). The client will follow `.well-known` delegation and connect
   to `https://__DOMAIN__` automatically. (If your client doesn't support
   `.well-known`, use `https://__DOMAIN__` directly.)
4. Pick a username and password.
5. When asked for a registration token, paste the **ephemeral** token from
   journald above — not the one printed in the install output.
6. Complete registration. You are now `@yourusername:__SERVER_NAME__` and
   the instance's first admin.

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

