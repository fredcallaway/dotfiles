# ---------- aliases ---------- #

alias ipy='ipython'
alias grep='grep --color=auto'
alias cp='cp -r'
alias u='cd .. && ls'
alias xee='open -a "Xee³"'
alias r='radian'
alias lg='lazygit'
# alias tca='tmux -CC attach -t'
alias tnew='tmux -CC new-session -s'

alias gwd='git diff --word-diff'
alias gco='git checkout'
alias gcm='git checkout main'
alias gd='git diff'

alias x='xplr'

# ---------- configuration tracking ---------- #

alias confgit='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias confshow='lazygit --git-dir=$HOME/.cfg/ --work-tree=$HOME'

function confadd {
    confgit add $1
    confgit commit -m "add `basename $1`"
}

function conflist {
    confgit ls-tree --full-tree --name-only -r HEAD
}

function confpush {
    conflist | rsync -a --files-from=- ~/ $1:~/
}

function confedit {
    selection="`conflist | fzf --query=$1 -1`"
    [ -z "$selection" ] && return
    subl -nw "$HOME/$selection"
    confshow
    [[ $selection == ".zshrc" ]] && source $HOME/.zshrc
}


# ---------- key bindings ---------- #

# Keybindings for substring search plugin. Maps up and down arrows.
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
# bindkey -M main '^[[A' history-substring-search-up
# bindkey -M main '^[[B' history-substring-search-down

bindkey '^ ' autosuggest-accept
bindkey '^f' fzf-file-widget

# ---------- misc ---------- #

export LS_COLORS='di=34:or=31:ln=36:ex=32'

setopt histignorealldups sharehistory
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

export TERM=xterm-256color  # not good practice but it's easy


zstyle :prompt:pure:path color cyan
zstyle :prompt:pure:git:branch color black
zstyle :prompt:pure:git:dirty color black
zstyle :prompt:pure:user color yellow
zstyle :prompt:pure:host color yellow

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='micro'
else
  export EDITOR='/Users/fred/bin/subl -nw'
fi

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=247'
# export ZSHZ_CASE=smart

export PATH=$HOME/bin:$HOME/opt/miniconda3/bin:$HOME/homebrew/bin:$HOME/homebrew/sbin:$PATH
export JULIA_SSL_CA_ROOTS_PATH=""
export WORDCHARS=${WORDCHARS//[\/]}  # treat / as word boundary

ls_command=ls
if command -v gls &> /dev/null; then
    ls_command=gls
fi
alias ls="$ls_command --color=auto -hX --group-directories-first"

# ---------- zinit ---------- #

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust
### End of Zinit's installer chunk

zinit wait lucid from"gh-r" as"null" for \
    sbin"fzf" @junegunn/fzf \
    sbin"**/fd" @sharkdp/fd \
    sbin'**/lazygit' jesseduffield/lazygit


zi for \
    https://github.com/junegunn/fzf/raw/master/shell/{'completion','key-bindings'}.zsh \
    pick"async.zsh" src"pure.zsh" fredcallaway/pure

zinit ice as"command" from"gh-r" lucid \
  mv"zoxide*/zoxide -> zoxide" \
  atclone"./zoxide init --cmd j zsh > init.zsh" \
  atpull"%atclone" src"init.zsh" nocompile'!'
zinit light ajeetdsouza/zoxide

zi light Aloxaf/fzf-tab
zi light zsh-users/zsh-completions
zi light zsh-users/zsh-autosuggestions
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#5C658D"
# zi light zsh-users/zsh-history-substring-search
# zi light agkozak/zsh-z
zi light zdharma-continuum/fast-syntax-highlighting

zinit ice as"command" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat
export BAT_THEME="Dracula"

# ---------- completion ---------- #


if [ -f "$HOME/.ssh/config" ]; then
    users=()
    zstyle ':completion:*:ssh:*' users $users
    hosts=($(egrep '^Host.*' $HOME/.ssh/config | awk '{print $2}' | grep -v '^*' | sed -e 's/\.*\*$//'))
    zstyle ':completion:*:ssh:*' hosts $hosts
fi
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

function fssh {
    host=`egrep '^Host.*' $HOME/.ssh/config | awk '{print $2}' | grep -v '^*' | fzf --reverse --prompt 'ssh: ' --query=$1 -1`
    ssh $host
}



# ---------- FUZZY FIND (fzf) ---------- #
# export FZF_COMPLETION_TRIGGER='|'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
export FZF_CTRL_T_OPTS="--preview 'head -n 200 {}' --select-1 --exit-0"

alias fd='fd --exclude .git --exclude .cache --no-ignore-vcs'

export FZF_CTRL_T_COMMAND='fd --no-ignore-vcs --type f'
export FZF_ALT_C_COMMAND='fd --no-ignore-vcs --type d'

export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--color=gutter:-1,bg+:-1
--color=hl+:#88f397,hl:#76D384
--color=fg+:#eaeaea,fg:#CACACC
--color=info:#7485ba,prompt:#f297cd,pointer:#f297cd
--color=marker:#f297cd,spinner:#c4a9f4,header:#88f397
'

# export FZF_DEFAULT_OPTS='--bind shift-up:preview-half-page-up,shift-down:preview-half-page-down'
# bindkey '^r' fzf-history-widget # r for reverse history search
# bindkey '^f' fzf-file-widget # f for file

# ---------- FUNCTIONS ---------- #

function pv {
    # file=$1
    # ext="${file#*.}"
    fullpath=`realpath $1`
    mime=`file --mime-type -b $fullpath`
    if echo $mime | grep 'text' -q ; then
        subl -b --command "preview_file {\"file\": \"$fullpath\"}"
    elif echo $mime | grep 'image' -q ; then
        xee -g $fullpath
    else
        qlmanage -p $fullpath &> /dev/null
    fi
}

function iterm {
    printf "\033]1337;Custom=id=zebra:%s\a" "$*"
}

function launch_project {
    while [ true ]; do
        project=`\ls -t /Users/fred/sublime-projects/*.sublime-workspace | sed 's/.*\/\(.*\)\.sublime-workspace/\1/' | fzf`
        [ $status -ne 0 ] && return
        iterm project $project
        subl "/Users/fred/sublime-projects/$project.sublime-workspace"
        osascript -e 'tell application "System Events" to keystroke "7"'
    done
}

function notify {
    osascript -e "display notification \"$1\" with title \"Terminal Notification\""
}

function s {
    if [ -z $1 ]; then
        subl .
    else
        subl $1
    fi
}

function n {
    if [ -z $1 ]; then
        `__fzf_cd__`
        ls
    else
        result="`ls --color=no -d */ | fzf --query=$1 -1`"
        if [[ -d $result && $result != '' ]]; then
            echo cd "$result"
            cd "$result"
            ls
        fi
    fi
}

function o {
    if [ -z $1 ]; then
        file=`fzf`
    else
        file=`fzf --query=$1 -1`
        # open `ls */ --color=auto | fzf --query=$1 -1`
    fi
    if [[ $file == *.ipynb ]]; then
        jupyter notebook $file
    elif [[ -e $file ]]; then
        open "$file"
    fi
}

function mvdl() {
    result="`\ls --color=no -t ~/Downloads | fzf --query=$1 -1 -m`"
    [ -z "$result" ] && return
    echo $result | while read -r f; do
        mv "$HOME/Downloads/$f" .
    done
}

# Smart cd function. cd to parent dir if file is given.
function cd() {
    if (( ${#argv} == 1 )) && [[ -f ${1} ]]; then
        [[ ! -e ${1:h} ]] && return 1
        print "Correcting ${1} to ${1:h}"
        builtin cd ${1:h}
    else
        builtin cd "$@"
    fi
}

function tca() {
    if [[ -n $(pgrep tmux) ]]; then
        session=`tmux list-sessions -F '#{session_name}' | fzf --reverse --prompt 'switch session: ' --query=$1 -1`
        echo "connecting to $session"
        tmux -CC attach -t $session -d
    else
        echo "creating main session"
        tmux -CC new-session -s main
    fi
}

if [ -f ".localrc" ]; then
    source .localrc
fi

autoload -U compinit && compinit -u
compdef __zoxide_z_complete j

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# ---------- lf ---------- #

_zlf() {
    emulate -L zsh
    local d=$(mktemp -d) || return 1
    {
        mkfifo -m 600 $d/fifo || return 1
        tmux split -f zsh -c "exec {ZLE_FIFO}>$d/fifo; export ZLE_FIFO; exec lf" || return 1
        local fd
        exec {fd}<$d/fifo
        zle -Fw $fd _zlf_handler
    } always {
        rm -rf $d
    }
}
zle -N _zlf
bindkey '^f' _zlf

_zlf_handler() {
    emulate -L zsh
    local line
    if ! read -r line <&$1; then
        zle -F $1
        exec {1}<&-
        return 1
    fi
    eval $line
    zle -R
}
zle -N _zlf_handler

LFCD="$HOME/.config/lf/lfcd.sh"
if [ -f "$LFCD" ]; then
    source "$LFCD"
fi

alias lf="lfcd"