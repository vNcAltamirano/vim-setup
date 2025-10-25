#!/usr/bin/env bash
set -Eeuo pipefail

# =============== utilidades ===============
trap 's=$?; echo "❌ Error (exit $s) en línea $LINENO: \"${BASH_COMMAND}\"" >&2' ERR
umask 022
timestamp() { date +"%Y%m%d-%H%M%S"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }
backup_if_exists() {
  local f="$1"
  if [[ -e "$f" ]]; then
    mv -f -- "$f" "$f.bak.$(timestamp)"
    echo "↪️  Backup: $f.bak.$(timestamp)"
  fi
}
write_file() {
  local path="$1"
  backup_if_exists "$path"
  mkdir -p -- "$(dirname "$path")"
  cat >"$path"
  chmod 0644 "$path" || true
  echo "✓ Escrito: $path"
}

if need_cmd sudo; then SUDO="sudo"; else SUDO=""; fi

# =============== 1) paquetes base ===============
echo "[1/6] Instalando paquetes base..."
$SUDO apt-get update -y
$SUDO apt-get install -y --no-install-recommends \
  vim git curl ca-certificates \
  ripgrep shfmt python3-pip \
  npm

# Formatters opcionales (no falla si ya está)
python3 -m pip install --user --quiet black || true
npm -g install prettier >/dev/null 2>&1 || true

# =============== 2) vim-plug ===============
echo "[2/6] Instalando vim-plug (si falta)..."
PLUG_PATH="${HOME}/.vim/autoload/plug.vim"
if [[ ! -f "$PLUG_PATH" ]]; then
  curl -fsSL --create-dirs \
    -o "$PLUG_PATH" \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  echo "✓ vim-plug instalado en $PLUG_PATH"
else
  echo "✓ vim-plug ya presente"
fi

# =============== 3) ~/.vimrc ===============
echo "[3/6] Escribiendo ~/.vimrc..."
write_file "$HOME/.vimrc" <<'EOF'
"=========================
" Vim + tmux (Ubuntu 22.04)
"=========================

" --- Núcleo
set nocompatible
syntax on
filetype plugin indent on
set encoding=utf-8

" --- Leader
let mapleader=" "

" --- Shell (tu preferencia: zsh)
set shell=/usr/bin/zsh

" --- Interfaz
set number
set numberwidth=1
set relativenumber
set mouse=a
set cursorline
" Activa termguicolors solo si la terminal lo soporta
if has("termguicolors") && $COLORTERM ==# "truecolor"
  set termguicolors
endif
set scrolloff=3
set list listchars=tab:>-,trail:·,extends:>,precedes:<

" --- Estado / UX
set showcmd
set ruler
set laststatus=2
set showmatch
set signcolumn=yes
set wildmenu
set wildmode=longest:full,full
set updatetime=500
set belloff=all

" --- Búsqueda
set ignorecase smartcase
set incsearch hlsearch
nnoremap <silent> <leader>/ :noh<CR>

" --- Indentación
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
" Ajuste explícito global:
set sw=2

" --- Splits
set splitright
set splitbelow

" --- Persistencia
set undofile
set undodir=~/.vim/undo//
set backup
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
augroup vim_persist_dirs
  autocmd!
  autocmd VimEnter * silent! call mkdir($HOME.'/.vim/undo', 'p')
  autocmd VimEnter * silent! call mkdir($HOME.'/.vim/backup', 'p')
  autocmd VimEnter * silent! call mkdir($HOME.'/.vim/swap', 'p')
augroup END

" --- Plegado
set foldmethod=indent
set foldlevel=99

" --- Ortografía
set spelllang=es,en

" --- Clipboard (modo headless: no vuelca al X11)
set clipboard=

" --- Herramientas externas
if executable('rg')
  set grepprg=rg\ --vimgrep\ --hidden\ --glob\ !.git
  set grepformat=%f:%l:%c:%m
endif

" --- Teclas útiles
nnoremap <leader>qfix :copen<CR>
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
nnoremap <F3> :set invrelativenumber<CR>
nnoremap <leader>df :%s/{{FECHA}}/\=strftime("%Y-%m-%d")/g<CR>
nmap <Leader>q :q<CR>

" --- Guardar como root
cmap w!! w !sudo tee % > /dev/null

" =========================
" Plugins (vim-plug)
" =========================
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'ojroques/vim-oscyank'       " Copia por OSC52 (tmux/SSH)
Plug 'morhetz/gruvbox'            " Tema Gruvbox
Plug 'easymotion/vim-easymotion'
Plug 'preservim/nerdtree'
Plug 'christoomey/vim-tmux-navigator'
call plug#end()

" =========================
" Tema Gruvbox + Colores
" =========================
colorscheme gruvbox
set background=dark
if exists('$TMUX')
  set background=dark
endif
augroup force_dark_bg
  autocmd!
  autocmd VimEnter * set background=dark
  autocmd ColorScheme * set background=dark
augroup END
let g:gruvbox_contrast_dark = 'medium'
let g:gruvbox_invert_selection = 0
" let g:gruvbox_transparent_bg = 1

" =========================
" NERDTree
" =========================
let NERDTreeQuitOnOpen=1
nmap <Leader>nt :NERDTreeFind<CR>

" =========================
" Comentarios rápidos
" =========================
nmap gc <Plug>Commentary
vmap gc <Plug>Commentary

" =========================
" oscyank (clipboard OSC52)
" =========================
let g:oscyank_term = 'tmux'
let g:oscyank_silent = 0
xnoremap <silent> <leader>y :OSCYankVisual<CR>
nnoremap <silent> <leader>y :OSCYank<CR>

" =========================
" Comandos :Run y :Fmt (on-demand)
" =========================
function! s:RunCurrent()
  if &filetype ==# 'sh'
    execute '!bash %'
  elseif &filetype ==# 'python'
    execute '!python3 %'
  elseif &filetype ==# 'javascript'
    execute '!node %'
  elseif &filetype ==# 'typescript'
    execute '!node --loader ts-node/esm %'
  elseif &filetype ==# 'cpp'
    let l:bin='/tmp/'.expand('%:t:r')
    if executable('clang++')
      execute '!clang++ -std=c++20 -O2 -Wall -Wextra -o ' . l:bin . ' % && ' . l:bin
    else
      execute '!g++ -std=c++20 -O2 -Wall -Wextra -o ' . l:bin . ' % && ' . l:bin
    endif
  elseif &filetype ==# 'nginx'
    execute '!sudo nginx -t'
  elseif &filetype ==# 'dosini'
    echo "Usa :SysReload o :SysRestart con el nombre de la unidad"
  elseif &filetype ==# 'xml'
    if executable('xmllint')
      execute '!xmllint --noout %'
    else
      echo "Instala xmllint para validar XML"
    endif
  elseif &filetype ==# 'html'
    echo "Sin validador específico; considera :Fmt si tienes prettier/tidy"
  else
    echo "Sin handler :Run para " . &filetype
  endif
endfunction
command! Run call s:RunCurrent()
nnoremap <leader>r :Run<CR>

function! s:Fmt()
  if &filetype ==# 'sh' && executable('shfmt')
    execute '%!shfmt -i 4 -ci -sr'
  elseif &filetype ==# 'python' && executable('black')
    execute '!black -q %' | edit
  elseif (&filetype ==# 'javascript' || &filetype ==# 'typescript' || &filetype ==# 'css' || &filetype ==# 'html') && executable('prettier')
    execute '!prettier --write %' | edit
  elseif &filetype ==# 'cpp' && executable('clang-format')
    execute '%!clang-format'
  elseif &filetype ==# 'xml' && executable('xmllint')
    execute '%!xmllint --format -'
  elseif &filetype ==# 'nginx' && executable('nginxfmt')
    execute '%!nginxfmt -'
  elseif &filetype ==# 'yaml' && executable('yamlfmt')
    execute '%!yamlfmt -'
  else
    echo "No hay formatter disponible para " . &filetype
  endif
endfunction
command! Fmt call s:Fmt()
nnoremap <leader>f :Fmt<CR>

" =========================
" Helpers Nginx / Systemd / Docker / Media
" =========================
command! NginxTest execute '!sudo nginx -t'
command! NginxReload execute '!sudo systemctl reload nginx'
nnoremap <leader>nginxt :NginxTest<CR>
nnoremap <leader>nginxr :NginxReload<CR>

command! -nargs=1 SysReload execute '!sudo systemctl daemon-reload && sudo systemctl reload ' . <q-args>
command! -nargs=1 SysRestart execute '!sudo systemctl daemon-reload && sudo systemctl restart ' . <q-args>
command! -nargs=1 SysLogs execute '!journalctl -u ' . <q-args> . ' -n 100 --no-pager'

command! -nargs=1 DLogs execute '!docker logs --tail=200 -f ' . <q-args>
command! -nargs=1 DExec execute '!docker exec -it ' . <q-args> . ' /bin/bash'

command! -nargs=1 FFProbe execute '!ffprobe -hide_banner -v error -show_format -show_streams ' . <q-args>

" =========================
" Skeletons para archivos nuevos
" =========================
augroup skeletons
  autocmd!
  autocmd BufNewFile *.sh        0r ~/.vim/templates/skeleton.sh
  autocmd BufNewFile *.py        0r ~/.vim/templates/skeleton.py
  autocmd BufNewFile *.cpp       0r ~/.vim/templates/skeleton.cpp
  autocmd BufNewFile *.html      0r ~/.vim/templates/skeleton.html
  autocmd BufNewFile *.service   0r ~/.vim/templates/skeleton.service
  autocmd BufNewFile nginx.conf,*nginx* 0r ~/.vim/templates/skeleton.nginx
  autocmd BufNewFile Dockerfile  0r ~/.vim/templates/skeleton.Dockerfile
  autocmd BufNewFile *.xml       0r ~/.vim/templates/skeleton.xml
augroup END

" =========================
" Abreviaturas útiles
" =========================
iabbrev TODO TODO(<C-R>=strftime("%Y-%m-%d")<CR>):
iabbrev FFM ffmpeg -hide_banner -y -i input.mp4 -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k output.mp4
EOF

# =============== 4) ftplugins y templates ===============
echo "[4/6] Creando ftplugins y templates..."
FTDIR="$HOME/.vim/ftplugin"
TPLDIR="$HOME/.vim/templates"
mkdir -p "$FTDIR" "$TPLDIR"

# -- ftplugins --
write_file "$FTDIR/sh.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=#\ %s
" Ejecuta con :Run (bash %)
EOF

write_file "$FTDIR/python.vim" <<'EOF'
setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
setlocal colorcolumn=88
setlocal commentstring=#\ %s
" :Run => python3 %
" :Fmt => black (si está)
EOF

write_file "$FTDIR/cpp.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal makeprg=make
setlocal commentstring=//\ %s
" :Run compila a /tmp/%< y ejecuta
EOF

write_file "$FTDIR/javascript.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=//\ %s
" :Run => node %
" :Fmt => prettier (si está)
EOF

write_file "$FTDIR/typescript.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=//\ %s
" :Run => node --loader ts-node/esm %
EOF

write_file "$FTDIR/html.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=<!--\ %s\ -->
" :Fmt => prettier o tidy
EOF

write_file "$FTDIR/css.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=/*\ %s\ */
EOF

write_file "$FTDIR/xml.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal foldmethod=syntax
setlocal commentstring=<!--\ %s\ -->
" :Run valida con xmllint (si está)
" :Fmt => xmllint --format
EOF

write_file "$FTDIR/nginx.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 noexpandtab
setlocal commentstring=#\ %s
nnoremap <buffer> <leader>t :NginxTest<CR>
nnoremap <buffer> <leader>r :NginxReload<CR>
" :Fmt => nginxfmt/nginxbeautifier (si está)
EOF

write_file "$FTDIR/dosini.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=;\ %s
" :SysReload nombre.service | :SysRestart nombre.service | :SysLogs nombre.service
EOF

write_file "$FTDIR/dockerfile.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=#\ %s
EOF

write_file "$FTDIR/yaml.vim" <<'EOF'
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal commentstring=#\ %s
setlocal colorcolumn=120
EOF

# -- templates --
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
chmod 0755 "$TPLDIR/skeleton.sh" || true

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
chmod 0755 "$TPLDIR/skeleton.py" || true

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

write_file "$TPLDIR/skeleton.Dockerfile" <<'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl bash && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
CMD ["bash", "-lc", "echo OK && sleep infinity"]
EOF

# =============== 5) PlugInstall headless ===============
echo "[5/6] Instalando plugins (vim-plug, modo headless)..."
# Evita errores por term no interactivo
export TERM=${TERM:-xterm-256color}
vim +':silent! PlugInstall --sync' +':qa' >/dev/null 2>&1 || true

# =============== 6) resumen ===============
echo
echo "========================================"
echo "✅ Vim configurado."
echo "• ~/.vimrc             (backup si existía)"
echo "• ~/.vim/ftplugin      (ftplugins por lenguaje)"
echo "• ~/.vim/templates     (plantillas)"
echo "• vim-plug instalado   (~/.vim/autoload/plug.vim)"
echo
echo "Extras/formatters:"
echo "• ripgrep (rg), shfmt, black (~/.local/bin), prettier (global npm)"
echo
echo "Tips:"
echo "  - Fecha rápida:  nnoremap <leader>df :%s/{{FECHA}}/\\=strftime(\"%Y-%m-%d\")/g<CR>"
echo "  - Abre Vim y prueba:  :NERDTreeFind , :Run , :Fmt"
echo "========================================"
