# ˚
CURRENT_BG='NONE'
PRIMARY_FG=black

# Characters
SEGMENT_SEPARATOR="\ue0b0"
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment CURRENT_BG 111 "%(!.%{%F{yellow}%}.)$user@%m "
  fi
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$CONDA_DEFAULT_ENV"
  if [[ -n $virtualenv_path ]]; then
    prompt_segment CURRENT_BG 6 "$(basename $virtualenv_path) "
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment CURRENT_BG 5 '%~ '
}

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    if is_dirty; then
      color=228
      ref="${ref} $PLUSMINUS"
    else
      color=156
      ref="${ref}"
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      b="$BRANCH"
    else
      b="$DETACHED"
    fi
    prompt_segment CURRENT_BG 224 "$b "
    prompt_segment CURRENT_BG $color "$ref "
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$CROSS"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment CURRENT_BG default "$symbols "
}

prompt_caret(){
  EMOJIS=( 😈 💩 👻 💀 👅 🤷 🦊 🍼 🦁 🙈 🙉 🙊 🐒 🍑 🍆 💊 💣 💔 🐡 🚬 👑 🫀 🧠 )
  SELECTED_EMOJI=${EMOJIS[$RANDOM % ${#EMOJIS[@]}]}
  NEWLINE=$'\n'
  print -n "${NEWLINE}${SELECTED_EMOJI}  "
}

# End the prompt, closing any open segments
prompt_end() {
  print -n "%{%k%}"
  print -n "%{%f%}"
  CURRENT_BG=''

}

## Main prompt
prompt_agnoster_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
  prompt_status
  prompt_context
  prompt_virtualenv
  prompt_dir
  prompt_git
  prompt_caret
  prompt_end
}

prompt_agnoster_precmd() {
  vcs_info
  PROMPT='%{%f%b%k%}$(prompt_agnoster_main)'
}

prompt_agnoster_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_agnoster_precmd

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_agnoster_setup "$@"
