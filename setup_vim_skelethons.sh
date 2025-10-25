#!/usr/bin/env bash
set -Eeuo pipefail

timestamp() { date +"%Y%m%d-%H%M%S"; }
backup_if_exists() {
  local f="$1"
  if [[ -e "$f" ]]; then
    mv -f "$f" "$f.bak.$(timestamp)"
  fi
}
write_file() {
  local path="$1"
  backup_if_exists "$path"
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  echo "✓ Escrito: $path"
}

FTDIR="$HOME/.vim/ftplugin"
TPLDIR="$HOME/.vim/templates"

mkdir -p "$FTDIR" "$TPLDIR"

# =========================
# ftplugin files
# =========================

# sh.vim
write_file "$FTDIR/sh.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=#\ %s
" Ejecuta con :Run (bash %)
EOF

# python.vim
write_file "$FTDIR/python.vim" <<'EOF'
setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
setlocal colorcolumn=88
setlocal commentstring=#\ %s
" :Run => python3 %
" :Fmt => black (si está)
EOF

# cpp.vim
write_file "$FTDIR/cpp.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal makeprg=make
setlocal commentstring=//\ %s
" :Run compila a /tmp/%< y ejecuta
EOF

# javascript.vim
write_file "$FTDIR/javascript.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=//\ %s
" :Run => node %
" :Fmt => prettier (si está)
EOF

# typescript.vim
write_file "$FTDIR/typescript.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=//\ %s
" :Run => node --loader ts-node/esm %
EOF

# html.vim
write_file "$FTDIR/html.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=<!--\ %s\ -->
" :Fmt => prettier o tidy
EOF

# css.vim
write_file "$FTDIR/css.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=/*\ %s\ */
EOF

# xml.vim
write_file "$FTDIR/xml.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal foldmethod=syntax
setlocal commentstring=<!--\ %s\ -->
" :Run valida con xmllint (si está)
" :Fmt => xmllint --format
EOF

# nginx.vim
write_file "$FTDIR/nginx.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 noexpandtab
setlocal commentstring=#\ %s
nnoremap <buffer> <leader>t :NginxTest<CR>
nnoremap <buffer> <leader>r :NginxReload<CR>
" :Fmt => nginxfmt/nginxbeautifier (si está)
EOF

# dosini.vim (systemd)
write_file "$FTDIR/dosini.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=;\ %s
" Ejemplos:
" :SysReload nombre.service
" :SysRestart nombre.service
" :SysLogs nombre.service
EOF

# dockerfile.vim
write_file "$FTDIR/dockerfile.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=#\ %s
EOF

# yaml.vim
write_file "$FTDIR/yaml.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=#\ %s
setlocal colorcolumn=120
EOF

# =========================
# templates (skeletons)
# =========================

# skeleton.sh
write_file "$TPLDIR/skeleton.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
# Autor: Vinicio Altamirano
# Fecha: {{FECHA}}
# Uso: ./script.sh

main() {
  echo "OK"
}

main "$@"
EOF

# skeleton.py
write_file "$TPLDIR/skeleton.py" <<'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Autor: Vinicio Altamirano
Fecha: {{FECHA}}
Uso: python3 script.py
"""
import sys

def main():
    print("OK")

if __name__ == "__main__":
    sys.exit(main())
EOF

# skeleton.cpp
write_file "$TPLDIR/skeleton.cpp" <<'EOF'
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    cout << "OK\n";
    return 0;
}
EOF

# skeleton.html
write_file "$TPLDIR/skeleton.html" <<'EOF'
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Nuevo documento</title>
</head>
<body>
  <h1>Hola</h1>
</body>
</html>
EOF

# skeleton.service (systemd)
write_file "$TPLDIR/skeleton.service" <<'EOF'
[Unit]
Description=Servicio ejemplo
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/bin/bash -lc "/usr/local/bin/mi-script.sh"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# skeleton.nginx
write_file "$TPLDIR/skeleton.nginx" <<'EOF'
server {
    listen 80;
    server_name ejemplo.local;
    access_log /var/log/nginx/ejemplo.access.log;
    error_log  /var/log/nginx/ejemplo.error.log;

    location / {
        root /var/www/ejemplo;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
EOF

# skeleton.Dockerfile
write_file "$TPLDIR/skeleton.Dockerfile" <<'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl bash && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
CMD ["bash", "-lc", "echo OK && sleep infinity"]
EOF

# Permisos ejecutables para scripts
chmod +x "$TPLDIR/skeleton.sh" "$TPLDIR/skeleton.py" || true

echo
echo "========================================"
echo "Listo. ftplugins y templates creados en:"
echo "  $FTDIR"
echo "  $TPLDIR"
echo
echo "Recuerda el mapeo para fecha (si no lo tienes ya):"
echo "  nnoremap <leader>df :%s/{{FECHA}}/\\=strftime(\"%Y-%m-%d\")/g<CR>"
echo "========================================"

