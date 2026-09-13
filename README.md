# cache-parity

Interop canary: **[`cache-backend-redis`](https://github.com/egao1980/cache-backend-redis)** vs dockerized **Valkey** (Redis-compatible). Exercises `cache-get` / `cache-put` / `cache-incr` / `cache-cas`.

In-memory TTL and fake-RESP tests stay in `cache-protocol` / `cache-backend-redis`. This repo is **live interop** only.

## Run

Default `asdf:test-system` is green **without Docker** — live cases `skip` when the daemon is unreachable.

```bash
ros -e '(asdf:test-system "cache-parity")' -q
```

Live:

```bash
docker compose up -d
ros -e '(asdf:test-system "cache-parity")' -q
```

```bash
PARITY=0 ros -e '(asdf:test-system "cache-parity")' -q
```

## Env

| Variable | Default | Meaning |
|----------|---------|---------|
| `PARITY` | probe | `0`/`false`/`off` skips live cases |
| `CACHE_PARITY` | probe | same, Valkey-only |
| `CACHE_PARITY_HOST` | `127.0.0.1` | Valkey/Redis host |
| `CACHE_PARITY_PORT` | `6379` | RESP port |

## Compose pins

| Service | Image |
|---------|--------|
| Valkey | `valkey/valkey:8.0.2-alpine` |

## License

MIT
