#!/usr/bin/env bash
set -Eeuo pipefail

# =============== utilidades ===============
trap 's=$?; echo "❌ Error (exit $s) en línea $LINENO: \"${BASH_COMMAND}\"" >&2' ERR
umask 022
timestamp() { date +"%Y%m%d-%H%M%S"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

# Función crítica para escribir archivos y crear directorios automáticamente
write_file() {
    local file="$1"
    mkdir -p "$(dirname "$file")"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
    fi
    cat > "$file"
}

# =============== 1) paquetes base ===============
echo "[1/6] Detectando versión de Ubuntu e instalando paquetes..."
if need_cmd sudo; then SUDO="sudo"; else SUDO=""; fi
$SUDO apt-get update -y
$SUDO apt-get install -y --no-install-recommends bc software-properties-common

# Obtener versión de Ubuntu
UBUNTU_VER=$(lsb_release -rs 2>/dev/null || grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release)

# Solo agregar PPA si es menor a 24.04
if [[ $(echo "$UBUNTU_VER < 24.04" | bc -l) -eq 1 ]]; then
    echo "-> Ubuntu < 24.04 detectado. Agregando PPA de Vim..."
    $SUDO add-apt-repository -y ppa:jonathonf/vim
fi

$SUDO apt-get update -y
$SUDO apt-get install -y --no-install-recommends \
  vim git curl ca-certificates \
  ripgrep shfmt npm clang-format python3-pip python3-venv

# =============== 1.1) Instalar ruff (Linter/Formatter veloz) ===============
echo "-> Instalando ruff..."
python3 -m pip install --user ruff --break-system-packages 2>/dev/null || python3 -m pip install --user ruff

# Configurar PATH
if ! grep -q ".local/bin" ~/.zshrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
fi
export PATH="$HOME/.local/bin:$PATH"

# Configurar npm para instalaciones locales
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"

# =============== 1.2) Node via NVM ===============
echo "-> Instalando NVM y Node LTS..."
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Cargar NVM
source "$NVM_DIR/nvm.sh" 2>/dev/null || true
nvm install --lts
nvm use --lts

# Instalar Prettier
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
" --- Núcleo
set nocompatible
syntax on
filetype plugin indent on
set encoding=utf-8
let mapleader=" "
set shell=/usr/bin/zsh

" --- Interfaz
set number relativenumber
set mouse=a
set cursorline
if has("termguicolors") && $COLORTERM ==# "truecolor"
  set termguicolors
endif
set scrolloff=3
set laststatus=2
set signcolumn=yes

" --- Búsqueda e Indentación
set ignorecase smartcase incsearch hlsearch
set expandtab tabstop=4 shiftwidth=4 softtabstop=4
nnoremap <silent> <leader>/ :noh<CR>

" --- Persistencia
set undofile
set undodir=~/.vim/undo//
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//

" --- Plugins
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'ojroques/vim-oscyank'
Plug 'morhetz/gruvbox'
Plug 'preservim/nerdtree'
Plug 'christoomey/vim-tmux-navigator'
call plug#end()

" --- Tema
colorscheme gruvbox
set background=dark
let g:gruvbox_contrast_dark = 'medium'

" --- Atajos Personalizados
nmap <Leader>nt :NERDTreeFind<CR>
xnoremap <silent> <leader>y :OSCYankVisual<CR>
nnoremap <silent> <leader>y :OSCYank<CR>
nmap <Leader>q :q<CR>

" --- Funciones Run y Fmt
function! s:RunCurrent()
  if &filetype ==# 'sh' | execute '!bash %'
  elseif &filetype ==# 'python' | execute '!python3 %'
  elseif &filetype ==# 'javascript' | execute '!node %'
  elseif &filetype ==# 'cpp'
    let l:bin='/tmp/'.expand('%:t:r')
    execute '!g++ -std=c++20 -O2 -o ' . l:bin . ' % && ' . l:bin
  else | echo "Sin handler :Run"
  endif
endfunction
command! Run call s:RunCurrent()
nnoremap <leader>r :Run<CR>

function! s:Fmt()
  if &filetype ==# 'sh' && executable('shfmt') | execute '%!shfmt -i 4 -ci -sr'
  elseif &filetype ==# 'python' && executable('ruff') | execute '!ruff format %' | edit
  elseif (&filetype ==# 'javascript' || &filetype ==# 'typescript') && executable('prettier') | execute '!prettier --write %' | edit
  elseif &filetype ==# 'cpp' && executable('clang-format') | execute '%!clang-format -i %' | edit
  else | echo "No hay formatter para " . &filetype
  endif
endfunction
command! Fmt call s:Fmt()
nnoremap <leader>f :Fmt<CR>

" --- Skeletons
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
# Fecha: {{FECHA}}

main() {
    echo "Iniciando script..."
}
main "$@"
EOF

write_file "$HOME/.vim/templates/skeleton.py" <<'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Autor: Vinicio Altamirano

def main():
    print("OK")

if __name__ == "__main__":
    main()
EOF

# =============== 5) PlugInstall ===============
echo "[5/6] Instalando plugins de Vim..."
vim +':silent! PlugInstall --sync' +':qa' >/dev/null 2>&1 || true

# =============== 6) Resumen ===============
echo "========================================"
echo "✅ ENTORNO CONFIGURADO CON ÉXITO"
echo "Formatters: shfmt, ruff (python), prettier (js)"
echo "Comandos clave: <leader>r (Run), <leader>f (Format), <leader>nt (Explorer)"
echo "========================================"
