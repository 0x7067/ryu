# Ryu web UI on the existing Render service

This packages the mirrored Desktop React UI in its existing playground and web
surface modes alongside the verified Core/Gateway runtime. Upstream's v0.5.0
release does not publish the documented `ryu-webapp-playground.tar.gz`, and the
public mirror omits `apps/webapp`; this is a local packaging adaptation, not an
official upstream web release.

## Build

From the repository root:

```sh
bun install --frozen-lockfile --ignore-scripts --filter desktop
VITE_PLAYGROUND=1 VITE_RYU_SURFACE=webapp VITE_APP_VERSION=0.5.0 \
  VITE_SENTRY_DSN= VITE_POSTHOG_KEY= \
  bun run --cwd apps/desktop build:vite
docker build --build-context web=./apps/desktop/dist \
  -f deploy/web/Dockerfile -t ryu:web-ui .
```

The Dockerfile pins both the previously verified Core image and the standard
Caddy image by digest. The named `web` context contains only the built static
assets. No credentials belong in the build context or image.

## Runtime

Keep the existing `/data` disk and `RYU_SKIP_LOCAL_STACK_INSTALL=1` setting.
Set `RYU_WEB_ORIGIN` to the exact public HTTPS origin, without a trailing slash.
Set `RYU_WEB_PASSWORD_HASH` to a Caddy bcrypt hash; the browser login user is
`ryu`. Store that hash as a Render secret environment variable. `PORT` is
provided by Render. The startup script refuses to serve without both settings.

Core listens only on loopback port 7980. Caddy serves static assets and proxies
Core APIs, WebSockets and event streams through the public port. All routes
except the read-only `/api/health` readiness endpoint require browser HTTP Basic
authentication over Render's HTTPS connection. Cross-site requests and foreign
Origin headers are rejected before the proxy attaches the persistent Core node
token. The token stays server-side and is not embedded in the frontend.

Open the node's Gateway dialog, then **AI providers**, to add model provider
credentials and choose a model. Model/provider data is stored by Core on `/data`.
Keep local inference uninstalled on the current 2 GiB plan.

The existing Render health check remains `/api/health`. The startup wrapper
forwards shutdown signals to Core and Caddy. Do not use this image without a TLS
terminating platform, or expose the private Core port separately.
