"=========================
" Vim + tmux (Ubuntu 22.04)
"=========================

" --- Núcleo
set nocompatible
syntax on
filetype plugin indent on

set encoding=utf-8
set fileencoding=utf-8
set fileformats=unix,dos

" --- Leader
let mapleader=" "

" --- Funciones de Backspace
set backspace=indent,eol,start

" --- Shell (tu preferencia: zsh)
set shell=/usr/bin/zsh

" --- Interfaz
set number
set relativenumber
set numberwidth=1
set mouse=a
set cursorline
set signcolumn=yes
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
set updatetime=300
set belloff=all
" --- Carácteres especiales Visibles
set list
set listchars=tab:>-,trail:·,extends:>,precedes:<

" --- Búsqueda
set ignorecase smartcase
set incsearch hlsearch
nnoremap <silent> <leader>/ :noh<CR>

" --- Indentación
" Ajuste explícito global:
"set sw=2 comun en java
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set smartindent

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
"Comando,       Acción
"   za,        Alternar (abrir/cerrar) el pliegue actual.
"   zc,        Cerrar (close) el pliegue actual.
"   zo,        Abrir (open) el pliegue actual.
"   zM,        Cerrar todo (proviene de Maximize folding).
"   zR,        Abrir todo (proviene de Reduce folding).

" --- Ortografía
set spelllang=es,en

" --- Clipboard (modo headless)
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

nnoremap <leader>w :w<CR>
nmap <Leader>q :q<CR>

" --- Guardar como root |cmap w!! w !sudo tee % > /dev/null | cmap w!! w !sudo tee > /dev/null %
" Guardar con sudo fácilmente
command! W execute 'w !sudo tee % >/dev/null' | edit!

" --- Abreviaturas de Comandos
cnoreabbrev W w
cnoreabbrev Wq wq
cnoreabbrev WQ wq
cnoreabbrev Q q
cnoreabbrev Qa qa
cnoreabbrev Wa wa

" -------------------------
" Configuración de VIM-TASK
" -------------------------
" Configuración para vim-tasks (debe ir antes de cargar el plugin o al inicio)
let g:TasksMarkerBase = '☐'
let g:TasksMarkerDone = '✔'
let g:TasksMarkerCancelled = '✘'
let g:TasksAttributeMarker = '@'
let g:TasksDateFormat = '%Y-%m-%d %H:%M'
let g:TasksArchiveSeparator = '＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿'

" =========================
" Plugins (vim-plug)
" =========================
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-surround'               " Change Surround cs, Delete Surround ds, ysiw( You Surroud hola -> (hola)
Plug 'tpope/vim-commentary'             " Comentarios gcc: comenta o descomenta lina actual, gc (Visual mode): Comenta bloque, gcap: Comenta párrafo
Plug 'ojroques/vim-oscyank'             " Copia por OSC52 (tmux/SSH)
Plug 'morhetz/gruvbox'                  " Tema Gruvbox
Plug 'easymotion/vim-easymotion'        " Busqueda y ubucación de palabras por letras
Plug 'preservim/nerdtree'               " Explorador de archivos
Plug 'christoomey/vim-tmux-navigator'   " utiliza tmux junto con Vim Ctrl + h (Izquierda), Ctrl + j (Abajo), Ctrl + k (Arriba), Ctrl + l (Derecha)
Plug 'neoclide/coc.nvim', {'branch': 'release'} " motor de autocompletado y servicios de lenguaje (LSP)
Plug 'Yggdroot/indentLine'              " dibuja líneas verticales finas en cada nivel de indentación.
Plug 'luochen1990/rainbow'              " Rainbow Parentheses (Paréntesis Arcoíris).
Plug 'irrationalistic/vim-tasks'        " Creación de Tareas
Plug 'itchyny/lightline.vim'            " Barra inferior 
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } " Busqueda por avanzada pra abrir archivos
Plug 'junegunn/fzf.vim'                 " Integración con VIM

call plug#end()


" =========================
" Configuración Tasks
" =========================
" Al presionar Enter en modo insertar dentro de un archivo .todo, 
" inserta automáticamente el prefijo de tarea.
autocmd FileType todo inoremap <buffer> <CR> <CR>☐ 
autocmd FileType tasks inoremap <buffer> <CR> <CR>☐ 


" =========================
" Config. Barra inferior
" =========================
set noshowmode

let g:lightline = {
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'filename': 'LightlineFilename',
      \ },
      \ }

function! LightlineFilename()
  let fullpath = expand('%:F') " Esto obtiene la ruta completa
  return fullpath !=# '' ? fullpath : '[No Name]'
endfunction


" =========================
" Tema Gruvbox + Colores
" =========================
colorscheme gruvbox
set background=dark

" Fuerza modo oscuro dentro de tmux y al cargar colores
if exists('$TMUX')
  set background=dark
endif
augroup force_dark_bg
  autocmd!
  autocmd VimEnter * set background=dark
  autocmd ColorScheme * set background=dark
augroup END

" Ajustes opcionales de Gruvbox
let g:gruvbox_contrast_dark = 'medium'
let g:gruvbox_invert_selection = 0
" let g:gruvbox_transparent_bg = 1 " (activa si quieres usar el fondo de tu terminal)


" =========================
" IndentLine
" =========================
let g:indentLine_char = '▏'
let g:indentLine_defaultGroup = 'SpecialKey'
let g:indentLine_fileTypeExclude = ['text', 'help', 'terminal', 'nerdtree']
let g:indentLine_bufNameExclude = ['_.*', 'NERD_tree.*']
let g:indentLine_setConceal = 0

" =========================
" Rainbow parentheses
" =========================
let g:rainbow_active = 1
let g:rainbow_conf = {
\   'guifgs': ['#fabd2f', '#fe8019', '#fb4934', '#b8bb26', '#83a598', '#d3869b'],
\   'ctermfgs': ['yellow', 'lightred', 'magenta', 'cyan', 'green', 'white'],
\   'operators': '_,_',
\   'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/'],
\   'separately': {
\       '*': {},
\       'nerdtree': 0,
\   }
\}


"=========================
" EasyMotionSearch
"========================
nmap <Leader>s <Plug>(easymotion-s2)

"=========================
" NERDTree
" =========================
"let NERDTreeQuitOnOpen=1
"nmap <Leader>nt :NERDTreeFind<CR>
let NERDTreeQuitOnOpen = 0
let NERDTreeShowHidden = 1
let NERDTreeMinimalUI = 1
let NERDTreeIgnore = ['^__pycache__$']
let g:NERDTreeWinSize = 30

nnoremap <leader>nt :NERDTreeToggle<CR>
nnoremap <leader>nf :NERDTreeFind<CR>

augroup nerdtree_start
    autocmd!
    autocmd VimEnter * if argc() == 0 | NERDTree | wincmd l | endif
    autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
augroup END


" =========================
" Comentarios rápidos
" =========================
nmap gc <Plug>Commentary
vmap gc <Plug>Commentary

" =========================
" FZF / Finder / Search
" =========================
if executable('rg')
    let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --glob !.git'
endif

nnoremap <leader>ff :Files<CR>
nnoremap <leader>fg :Rg<CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fh :History<CR>
nnoremap <leader>fl :Lines<CR>
nnoremap <leader>fc :Commands<CR>
nnoremap <leader>fw :Rg <C-r><C-w><CR>


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
iabbrev TODO <C-R>=substitute(printf(&commentstring, "TODO(" . strftime("%Y-%m-%d") . "):"), '\S\zs\s\+$', '', '')<CR>


" =========================
" CoC Extensions
" =========================
let g:coc_global_extensions = [
\ 'coc-pyright',
\ 'coc-tsserver',
\ 'coc-html',
\ 'coc-css',
\ 'coc-json',
\ 'coc-sh',
\ 'coc-snippets'
\ ]

" =========================
" CoC + LSP
" =========================
inoremap <silent><expr> <C-k> coc#refresh()

function! ShowDocumentation()
    if CocAction('hasProvider', 'hover')
        call CocActionAsync('doHover')
    else
        call feedkeys('K', 'in')
    endif
endfunction

nnoremap <silent> K :call ShowDocumentation()<CR>
nnoremap <silent> <leader>ee :CocList diagnostics<CR>
nmap <leader>rn <Plug>(coc-rename)


"==============================
"Auto formato al guardar Python
"==============================
"autocmd BufWritePre *.py silent! call CocAction('formatDocument')
autocmd CursorHold * silent call CocActionAsync('highlight')

inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()

inoremap <expr> <S-TAB>
      \ coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

inoremap <silent><expr> <CR>
      \ coc#pum#visible() ? coc#pum#confirm()
      \ : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1] =~# '\s'
endfunction

"=============================================
"Integración Vim y Coc (Conquer of completion)
"=============================================
nmap <silent> gd <Plug>(coc-definition) 
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

nnoremap <leader>ca <Plug>(coc-codeaction-cursor)
nnoremap <leader>ac <Plug>(coc-codeaction)
nnoremap <leader>cl :CocList commands<CR>
nnoremap <leader>o  :CocOutline<CR>
nnoremap <leader>cs :CocList -I symbols<CR>
nnoremap <leader>ce :CocList extensions<CR>



"==================================
"Desabilitar tempolmente 
"el análisis del proyecto en Python
"==================================
command! CocLow  :call coc#config('python.analysis.diagnosticMode', 'openFilesOnly') | CocRestart
command! CocFull :call coc#config('python.analysis.diagnosticMode', 'workspace') | CocRestart


"==============================================
"Configuraciones de color de Ligthing en Python
"==============================================
"hi CocUnusedHighlight ctermfg=208 guifg=#fe8019 gui=underline
"hi CocUnusedHighlight ctermfg=200 gui=underline
"hi CocFloating ctermbg=0 guibg=#32302f
"hi CocErrorFloat guifg=#fb4934
"hi CocHintFloat guifg=#83a598

" =========================
" Configuraciones Rust
" =========================
" Auto formato al guardar
let g:rustfmt_autosave = 1

" =========================
" Layout opcional
" =========================
function! StartMyLayout()
    only
    NERDTree
    wincmd l
    belowright terminal
    resize 8
    wincmd k
endfunction
