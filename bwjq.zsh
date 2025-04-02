# zsh-jq -- A Bitwarden CLI wrapper for Zsh
# https://github.com/Game4Move78/zsh-bitwarden

# Copyright (c) 2021 Patrick Lenihan

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

source "${0:h}/base.zsh"

bwjq_script() {
  local script="$1"
  shift
  cat \
    <(bwjq_request GET '/list/object/folders') \
    <(bwjq_request GET '/list/object/items') \
    | bwjq_jq \
        -nceM \
        --stream \
        -f "$script" \
        "$@"
}

bwjq_candidates() {

  local -a \
        opt_key \
        opt_greedy \
        opt_recursive \
        opt_exp \
        opt_all \

        zparseopts -D -K -E -- \
          {k,-key}=opt_key \
          {g,-greedy}=opt_greedy \
          {r,-recursive}=opt_recursive \
          {e,-expand}=opt_exp \
          {a,-all}=opt_all \
          || return

  bwjq_unlock || return $?

  prefix="$1"
  bwjq_script \
    "${BWJQ_BWJQ}" \
    -r \
    --arg key "${opt_key[1]}" \
    --arg greedy "${opt_greedy[1]}" \
    --arg recursive "${opt_recursive[1]}" \
    --arg expand "${opt_exp[1]}" \
    --arg all "${opt_all[1]}" \
    --arg prefix "$prefix"
}

_bwjq_bwjq() {
  local cur
  cur="${words[CURRENT]}"
  local -a opts

  opts=("${(@f)$(bwjq_candidates ${(Q)cur})}")
  compadd -S '' -- "${opts[@]}"
}

bwjq_fzf() {
  local stdin=$(cat)
  paste \
    <(printf "%s" "$stdin" | cut -f1) \
    <(printf "%s" "$stdin" | cut -f2 | column -t -s $'\t') \
  | fzf -d $'\t' --with-nth=1 --select-1 --header-lines=1 \
  | cut -f2
}

bwjq_bwjq() {
  local -a \
        opt_clip \
        opt_qr \
        opt_fzf

  zparseopts -D -K -E -- \
             {c,-clip}=opt_clip \
             {q,-qr}=opt_qr \
             {f,-fzf}=opt_fzf \
    || return

  local -a bwjq_args

  if [[ ${#opt_fzf} -ne 0 ]]; then
    bwjq_args+=("--expand" "--all")
  fi

  bwjq_candidates "${bwjq_args[@]}" -g -r -k "$@" \
    | {
    local key
    read -r key
    if [[ "$key" == "value" ]]; then
      bwjq_display "${opt_clip[@]}" "${opt_qr[@]}"
    elif [[ "$key" == "tree" ]]; then
      tree --fromfile --noreport .
    elif [[ "$key" == "tsv" ]]; then
      bwjq_fzf | bwjq_display "${opt_clip[@]}" "${opt_qr[@]}"
    fi
  }

}

bwjq_list() {
  local -a \
        opt_clip \
        opt_qr

  zparseopts -D -K -E -- \
             {c,-clip}=opt_clip \
             {q,-qr}=opt_qr \
    || return

  prefix="$1"

  bwjq_unlock || return $?

  bwjq_script \
    "${BWJQ_LIST}" \
    -r \
    --arg prefix "$prefix" \
  | bwjq_display "${opt_clip[@]}" "${opt_qr[@]}"

}

compdef _bwjq_bwjq bwjq_bwjq
compdef _bwjq_bwjq bwjq_list

alias bwjq='bwjq_bwjq'
alias bwls='bwjq_list'
alias bwst='bwjq_status'
alias bwsn='bwjq_sync'
alias bwul='bwjq_unlock'
alias bwlk='bwjq_lock'
alias bwgp='bwjq_generate -ulns'
alias bwgu='bwjq_generate -uln'

export BWJQ_BWJQ="${0:h}/bwjq_new.jq"
export BWJQ_LIST="${0:h}/bwjq_list.jq"

export BWJQ_JQ='jq'
export BWJQ_QRENCODE='qrencode -t UTF8'
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  export BWJQ_COPY='clipcopy'
elif [ "$(uname)" = "Darwin" ]; then
  export BWJQ_COPY='pbcopy'
else
  export BWJQ_COPY='xclip -selection clipboard'
fi
