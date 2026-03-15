#!/usr/bin/env bash
set -Eeuo pipefail

# =============== utilidades ===============
trap 's=$?; echo "❌ Error (exit $s) en línea $LINENO: \"${BASH_COMMAND}\"" >&2' ERR
umask 022

need_cmd() { command -v "$1" >/dev/null 2>&1; }

write_file() {
    local file="$1"
    mkdir -p "$(dirname "$file")"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
    fi
    cat > "$file"
}

# =============== 1) paquetes base ===============
echo "[1/6] Detectando sistema e instalando paquetes..."
if need_cmd sudo; then SUDO="sudo"; else SUDO=""; fi

# --- LIMPIEZA CRÍTICA ---
# Eliminamos el PPA fallido de intentos anteriores que bloquea el apt-get update
echo "-> Limpiando rastros de PPAs incompatibles..."
$SUDO rm -f /etc/apt/sources.list.d/jonathonf-ubuntu-vim-noble.list
$SUDO rm -f /etc/apt/sources.list.d/jonathonf-ubuntu-vim-jammy.list

UBUNTU_VER=$(lsb_release -rs 2>/dev/null || grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release | tr -d '"')

if [[ $(echo "$UBUNTU_VER < 24.04" | bc -l) -eq 1 ]]; then
    echo "-> Ubuntu < 24.04 detectado. Intentando agregar PPA de Vim..."
    $SUDO add-apt-repository -y ppa:jonathonf/vim || true
else
    echo "-> Ubuntu 24.04+ detectado ($UBUNTU_VER). Usando repositorios oficiales."
fi

# Ahora el update no debería fallar por el 404 del PPA
$SUDO apt-get update -y
$SUDO apt-get install -y --no-install-recommends \
  vim git curl ca-certificates ripgrep shfmt clang-format python3-pip python3-venv

# =============== 1.1) Ruff ===============
echo "-> Instalando ruff..."
python3 -m pip install --user ruff --break-system-packages 2>/dev/null || python3 -m pip install --user ruff

if [ ! -f "$HOME/.zshrc" ]; then touch "$HOME/.zshrc"; fi
if ! grep -q ".local/bin" ~/.zshrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
fi
export PATH="$HOME/.local/bin:$PATH"

# =============== 1.2) Node via NVM ===============
echo "-> Configurando NVM y Node..."
[ -f "$HOME/.npmrc" ] && sed -i '/prefix=/d' "$HOME/.npmrc" || true

export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

set +u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts
set -u

npm install -g prettier

# =============== 2) vim-plug ===============
echo "[2/6] Instalando vim-plug..."
PLUG_PATH="${HOME}/.vim/autoload/plug.vim"
if [[ ! -f "$PLUG_PATH" ]]; then
  curl -fsSL --create-dirs -o "$PLUG_PATH" https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# =============== 3) ~/.vimrc ===============
echo "[3/6] Escribiendo ~/.vimrc..."
write_file "$HOME/.vimrc" <<'EOF'
set nocompatible
syntax on
filetype plugin indent on
let mapleader=" "

set number relativenumber
set mouse=a
set cursorline
if has("termguicolors") && $COLORTERM ==# "truecolor"
  set termguicolors
endif

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'ojroques/vim-oscyank'
Plug 'morhetz/gruvbox'
Plug 'preservim/nerdtree'
Plug 'christoomey/vim-tmux-navigator'
call plug#end()

colorscheme gruvbox
set background=dark
let g:gruvbox_contrast_dark = 'medium'

nmap <Leader>nt :NERDTreeFind<CR>
nnoremap <leader>r :Run<CR>
nnoremap <leader>f :Fmt<CR>
nmap <Leader>q :q<CR>

function! s:RunCurrent()
  if &filetype ==# 'sh' | execute '!bash %'
  elseif &filetype ==# 'python' | execute '!python3 %'
  elseif &filetype ==# 'javascript' | execute '!node %'
  else | echo "Sin comando Run" | endif
endfunction
command! Run call s:RunCurrent()

function! s:Fmt()
  if &filetype ==# 'sh' | execute '%!shfmt -i 4 -ci -sr'
  elseif &filetype ==# 'python' | execute '!ruff format %' | edit
  elseif &filetype ==# 'javascript' | execute '!prettier --write %' | edit
  else | echo "Sin formatter" | endif
endfunction
command! Fmt call s:Fmt()

augroup skeletons
  autocmd!
  autocmd BufNewFile *.sh 0r ~/.vim/templates/skeleton.sh
  autocmd BufNewFile *.py 0r ~/.vim/templates/skeleton.py
augroup END
EOF

# =============== 4) Templates ===============
echo "[4/6] Creando templates..."
write_file "$HOME/.vim/templates/skeleton.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
# Autor: Vinicio Altamirano
main() { echo "OK"; }
main "$@"
EOF

write_file "$HOME/.vim/templates/skeleton.py" <<'EOF'
#!/usr/bin/env python3
def main():
    print("OK")
if __name__ == "__main__":
    main()
EOF

# =============== 5) PlugInstall ===============
echo "[5/6] Instalando plugins de Vim..."
export TERM=xterm-256color
vim +':silent! PlugInstall --sync' +':qa' >/dev/null 2>&1 || true

# =============== 6) Resumen ===============
echo "========================================"
echo "✅ CONFIGURACIÓN COMPLETADA EN UBUNTU $UBUNTU_VER"
echo "========================================"
