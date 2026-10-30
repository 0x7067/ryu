# Build the UI first and pass its dist directory as the named "web" context.
ARG RYU_RUNTIME_IMAGE=ghcr.io/0x7067/ryu@sha256:986a47e77191cb09f041a907f3b624a808ebfffe8c63ecfd4d2b1ee0c7a26c69
FROM caddy:2@sha256:36c24ad91a7ff7bc4c87fe22bfa8df3c4b18da0773d73fc12ee2c52b98c0bb7e AS webserver
FROM ${RYU_RUNTIME_IMAGE}
USER 0:0
COPY --from=webserver /usr/bin/caddy /usr/local/bin/caddy
COPY --from=web / /usr/share/ryu/web/
COPY --chmod=0644 deploy/web/Caddyfile /etc/ryu/Caddyfile
COPY --chmod=0755 deploy/web/start.sh /usr/local/bin/ryu-web-start
RUN chmod 0755 /etc/ryu /usr/share/ryu \
 && find /usr/share/ryu/web -type d -exec chmod 0755 {} + \
 && find /usr/share/ryu/web -type f -exec chmod 0644 {} +
USER 10001:10001
ENTRYPOINT ["/usr/local/bin/ryu-web-start"]
