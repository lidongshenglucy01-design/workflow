# Vi 模式
fish_vi_key_bindings

# Insert 模式下保留 Emacs 风格快捷键
bind -M insert \ca beginning-of-line
bind -M insert \ce end-of-line
bind -M insert \cu kill-whole-line
bind -M insert \cf forward-char
bind -M insert \cb backward-char
bind -M insert \cw backward-kill-word
bind -M insert \cc cancel
bind -M insert \cp up-or-search
bind -M insert \cn down-or-search

# Homebrew
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin

# obsidian
set -gx OBSIDIAN_VAULT "/Users/lidongsheng/Library/Mobile Documents/iCloud~md~obsidian/Documents/lds-note"

# 代理
set -x http_proxy http://127.0.0.1:10792
set -x https_proxy http://127.0.0.1:10792
starship init fish | source

# 现代工具替代
alias ls='lsd'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias du='dust'
alias top='btop'
alias help='tldr'

# zoxide 替代 cd
zoxide init fish | source
export PATH="$HOME/.local/bin:$PATH"
