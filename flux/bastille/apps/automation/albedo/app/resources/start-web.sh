#!/bin/sh
set -eu
umask 077

key_file=/albedo-home/.albedo/web-key
until [ -s "$key_file" ]; do sleep 1; done
key=$(cat "$key_file")
case "$key" in *[!0-9a-f]*|'') exit 1 ;; esac
[ "${#key}" -eq 48 ]

cat > /run/albedo-web/upstream.conf <<EOF
proxy_pass http://127.0.0.1:4317;
proxy_http_version 1.1;
proxy_set_header Host 127.0.0.1:4317;
proxy_set_header Cookie "albedo_web=$key";
proxy_set_header Connection "";
proxy_hide_header Set-Cookie;
proxy_buffering off;
proxy_request_buffering off;
proxy_read_timeout 1h;
EOF
unset key

exec nginx -c /config/nginx.conf -g 'daemon off;'
