# utility func
file_exists() {
    [ -f $1 ]
}
command_exists() { type "$1" > /dev/null 2>&1; }

# emacsのtrampがタイムアウトするのに対応
[[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ '

bindkey -e

# 自作関数の読み込み
autoload -Uz precmd tinify estart

# 補完
autoload -U compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:default' menu select=1
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache true
zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh/cache
setopt auto_list
setopt IGNOREEOF
setopt auto_menu
setopt menu_complete

PROMPT="%F{074}[%n@%m]%f# "
RPROMPT='%F{048}[%~]%f'

setopt no_beep # ビープ音を消す
setopt globdots # 明確なドットの指定なしで.から始まるファイルをマッチ


setopt auto_cd
function chpwd() { ls --color=always }

# コマンド履歴関連
setopt hist_ignore_dups
setopt share_history
SAVEHIST=100
HISTFILE=$HOME/.zsh_history

alias mv='mv -i'
alias cp='cp -i'
alias cdb='cd-bookmark'
alias ekill="emacsclient -e '(kill-emacs)'"
alias erestart="ekill && estart"
alias copy='xsel --clipboard --input'
alias cl='clear'
alias cle='clear'
alias clea='clear'
alias tmux="tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf"

alias g='git'
alias ga='git add'
alias gd='git diff'
alias gdc='git diff --cached'
alias gs='git status'
alias gp='git push'
alias gc='git commit'

alias -g A='| awk'
alias -g C='| copy' # copy
alias -g G='| grep --color=auto' # 鉄板
alias -g H='| head' # 当然tailもね
alias -g L='| less -R'
alias -g S='| sort'
alias -g T='| tail' # 当然tailもね
alias -g U='| uniq'
alias -g X='| xargs'
alias -g bgh=">/dev/null"
alias -g .zshrc="$ZDOTDIR/.zshrc"
alias -g .zsh="$ZDOTDIR/.zshrc"
alias -g .zprofile="$ZDOTDIR/.zprofile"
alias -g .zp="$ZDOTDIR/.zprofile"
alias -g .zpr="$ZDOTDIR/.zprofile"
alias -g .zpro="$ZDOTDIR/.zprofile"

expand-alias() {
    zle _expand_alias
    zle expand-word
}

zle -N expand-alias
bindkey '^O'    expand-alias

fancy-ctrl-z () {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER="fg"
        zle accept-line
    else
        zle push-input
        zle clear-screen
    fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

# vim_version=`vim --version | head -1 | sed 's/^.*\ \([0-9]\)\.\([0-9]\)\ .*$/\1\2/'`
alias less=$VIM'/runtime/macros/less.sh'
alias emacs='emacs -nw'
alias e='emacsclient -nw -a "" 2>/dev/null'

alias vi="env -u VIM env VIMINIT=':source $XDG_CONFIG_HOME'/vim/vimrc vim"
alias vim="env -u VIM env VIMINIT=':source $XDG_CONFIG_HOME'/vim/vimrc vim"
if command_exists nvim; then
    alias vim="nvim"
fi
if command_exists exa; then
    alias ls="exa"
    alias ll='exa -algh --git'
    function chpwd() { exa }
fi
if command_exists bat; then alias cat='bat'; fi


# zplug
source $ZPLUG_HOME/init.zsh
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zaw"
zplug "mollifier/cd-bookmark"
zplug "mollifier/zload"
zplug "momo-lab/zsh-replace-multiple-dots"

autoload -Uz chpwd_recent_dirs cdr add-zsh-hook is-at-least
if is-at-least 4.3.10; then
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':chpwd:*' recent-dirs-max 5000
    zstyle ':chpwd:*' recent-dirs-default yes
    zstyle ':filter-select' case-insensitive yes
fi

if [[ $ZPLUG_LOADFILE -nt $ZPLUG_CACHE_DIR/interface || ! -f $ZPLUG_CACHE_DIR/interface ]]; then
    if ! zplug check --verbose; then
        printf 'Install? [y/N]: '
        if read -q; then
            echo; zplug install
        fi
    fi
fi
zplug load

function _double_space_to_fzf() {
    if [[ "${LBUFFER}" =~ " $" ]]; then
        LBUFFER="${LBUFFER}$(__fsel)"
        local ret=$?
        zle redisplay
        return $ret
    else
        zle self-insert
    fi
}
zle -N _double_space_to_fzf
bindkey ' ' _double_space_to_fzf
bindkey '^ ' magic-space


ZSH_AUTOSUGGEST_STRATEGY=match_prev_cmd

# ローカルファイルの読み込み
if file_exists ~/.fzf.zsh; then
    source ~/.fzf.zsh;
fi
if file_exists "$ZDOTDIR/.zshrc.local"; then
    source $ZDOTDIR/.zshrc.local;
fi


# 挙動:
# 1. 何もセッションが存在しない -> new-session
# 1. SSH先にすでにattachしたセッションが存在する -> detach済みセッションがあればattach、なければnew-session
# 1. ローカルで新しく端末を立ち上げる(=すでにattachしたセッションが存在する) -> tmuxを起動したくない
# -> ローカルとSSH先を区別する必要がある
if [ `whoami` != 'root' -a -z "$TMUX" -a -z "$STY" ]; then
    if type tmuxx >/dev/null 2>&1; then
        tmuxx
    elif type tmux >/dev/null 2>&1; then
        if tmux has-session; then
            if [[ -n `tmux list-sessions | grep '(attached)'` ]]; then
                # アタッチ済み
                if [ ! -v NOT_NEW_SESSION_TMUX ]; then
                    if [[ -n `tmux list-sessions | grep -v '(attached)'` ]]; then
                        # デタッチ済みセッションがある
                        exec tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf attach && echo "tmux attached session"
                    else
                        exec tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf new-session && echo "tmux created new session"
                    fi
                fi
            else
                exec tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf attach && echo "tmux attached session"
            fi
        else
            exec tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf new-session && echo "tmux created new session"
        fi
    elif type screen >/dev/null 2>&1; then
        screen -rx || screen -D -RR
    fi
fi
