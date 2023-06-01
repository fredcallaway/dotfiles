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
alias chrome='open -a "Google Chrome"'

alias gwd='git diff --word-diff'
alias gco='git checkout'
alias gcm='git checkout main'
alias gd='git diff'

alias ambs='ambs --row --column'
alias rg='rg --max-columns 2000'


command -v duf &> /dev/null && \
    alias df='duf --hide-mp "*.timemachine*","*ystem*","*private*" -only local'

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
export KALEIDOSCOPE_DIR=${HOME}/lib/Kaleidoscope

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
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# export ZSHZ_CASE=smart

export PATH=$HOME/bin:$HOME/opt/miniconda3/bin:$HOME/homebrew/bin:$HOME/homebrew/sbin:/usr/local/lib/ruby/gems/3.0.0/bin/:$PATH
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

export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-v:change-preview-window(down|hidden|)'
  --select-1 --exit-0
"
# export FZF_CTRL_T_OPTS="--preview 'head -n 200 {}' --select-1 --exit-0"

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

# function
# xargs -n1 -I{} zsh -ic 'sdo "cd {}"'


rga-fzf() {
    RG_PREFIX="rga --files-with-matches"
    local file
    file="$(
        FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
            fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
                --phony -q "$1" \
                --bind "change:reload:$RG_PREFIX {q}" \
                --preview-window="70%:wrap"
    )" &&
    echo "opening $file" &&
    open "$file"
}

split-run () {
    if [[ $# -eq 0 ]]; then
        # read from stdin
        local commands=()
        while IFS= read -r line; do
            commands+=( "$line" )
        done
        [ $#commands -gt 0 ] && split-run $commands
    else
        tmux new-window
        sleep 0.01
        if [[ $#@ -gt 1 ]]; then
            for i in {2..$#@}; do tmux split; done
        fi
        tmux select-layout tiled
        sleep 0.5
        for i in {1..$#@}; do
            cmd=$@[i]
            let "pane = i - 1"
            tmux send-keys -t $pane "$cmd" Enter
        done
    fi
}

sdo () {
    echo $@ | tr ' ' '\n' | perl -pe 'chomp if eof' | subl -nw | cat - <(echo) | split-run
}

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

function notify {
    osascript -e "display notification \"$1\" with title \"Terminal Notification\""
}

function s {
    if [ -z $1 ]; then
        subl .
    else
        subl -n $1
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


# ---------- bibliography ---------- #

BIBFILE=~/lib/zotero.bib
function zot {
    citekey=$(
        bibtex-ls --cache=/tmp $BIBFILE |
        fzf --ansi --height=20% --query=$1 |
        bibtex-cite
    )
    open "zotero://select/items/$citekey"
}

# function cite {
#     citekey=$(
#         bibtex-ls --cache=/tmp $BIBFILE |
#         fzf --ansi --height=20% --query=$1 |
#         bibtex-cite |
#         tr -d '@'
#     )
#     bibtool --print.align.key=0 --print.line.length=100 -X $citekey $BIBFILE | pbcopy
# }

# ---------- lf ---------- #

function tag {
    echo `realpath $1`":*" >> ~/.local/share/lf/tags
}

LFCD="$HOME/.config/lf/lfcd.sh"
if [ -f "$LFCD" ]; then
    source "$LFCD"
fi

alias lf="lfcd"

# ---------- selection widgets ---------- #

insert-setup () {
  echoti rmkx
  zle autosuggest-clear
  zle autosuggest-disable
}

insert-do () {
  BUFFER+=$1
  (( CURSOR+=$#1 ))
  zle autosuggest-enable
  .zle_redraw-prompt
}
.zle_insert-path-broot () {
  # insert-setup
  local result=${(q-)$(<$TTY broot --color yes --conf "${HOME}/.config/broot/select.hjson;${HOME}/.config/broot/conf.hjson")}
  if [[ $result != "''" ]]; then
      insert-do $result
  fi
}
zle -N .zle_insert-path-broot
bindkey '^b' .zle_insert-path-broot  # ctrl+alt+down

.zle_insert-path-lf () {
  insert-setup
  echo > /tmp/lf_insert
  command lf -command inserter
  local result=`cat /tmp/lf_insert`
  if [[ $result != "''" ]]; then
      insert-do "'$result'"
  fi
}
zle -N .zle_insert-path-lf
bindkey '^f' .zle_insert-path-lf

.zle_insert-path-zoxide () {
  insert-setup
  local result="$(zoxide query -i)"
  if [[ $result != "''" ]]; then
      insert-do "'$result'"
  fi
}
zle -N .zle_insert-path-zoxide
bindkey '^p' .zle_insert-path-zoxide

.zle_redraw-prompt () {
  # Credit: romkatv/z4h
  emulate -L zsh
  for 1 ( chpwd $chpwd_functions precmd $precmd_functions ) {
    if (( $+functions[$1] ))  $1 &>/dev/null
  }
  zle .reset-prompt
  zle -R
}
# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

path=('/Users/fred/.juliaup/bin' $path)
export PATH

# <<< juliaup initialize <<<
