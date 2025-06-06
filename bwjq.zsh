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
  local -a \
        opt_custom

  zparseopts -D -K -E -- \
             -custom:=opt_custom \
    || return

  local -a bwjq_args

  if [[ ${#opt_custom} -ne 0 ]]; then
    bwjq_args+=(-L ${opt_custom[-1]})
  else
    bwjq_args+=(-L $BWJQ_CUSTOM)
  fi

  local script="$1"
  shift
  cat \
    <(bwjq_request GET '/list/object/folders') \
    <(bwjq_request GET '/list/object/items') \
    | bwjq_jq \
        -nceM \
        --stream \
        -f "$script" \
        "$@" \
        ${bwjq_args[@]} -L $BWJQ_PATH
}

bwjq_candidates() {

  local -a \
        opt_key \
        opt_greedy \
        opt_recursive \
        opt_exp \
        opt_custom \
        opt_all

  zparseopts -D -K -E -- \
             {k,-key}=opt_key \
             {g,-greedy}=opt_greedy \
             {r,-recursive}=opt_recursive \
             {e,-expand}=opt_exp \
             {a,-all}=opt_all \
             -custom:=opt_custom \
  || return

  bwjq_unlock || return $?

  prefix="$1"
  [[ $# -ne 0 ]] && shift
  bwjq_script \
    "${BWJQ_BWJQ}" \
    -r \
    --arg key "${opt_key[1]}" \
    --arg greedy "${opt_greedy[1]}" \
    --arg recursive "${opt_recursive[1]}" \
    --arg expand "${opt_exp[1]}" \
    --arg all "${opt_all[1]}" \
    --arg prefix "$prefix" \
    "${opt_custom[@]}" \
    "$@"
}

_bwjq() {

  setopt local_options EXTENDED_GLOB

  local cur
  cur="${words[CURRENT]}"
  local -a opts

  opts=("${(@f)$(bwjq_candidates ${(Q)cur})}")
  local prefix="${(Q)cur%[^\/]}"

  values=("${(@)opts#${prefix}}")
  values=("${(@I:2:)values//([^\/]#\/|[^\/]##)/}")

  compadd -S '' -d values -a opts

}

bwjq_fzf() {
  local stdin=$(cat)
  paste \
    <(printf "%s" "$stdin" | cut -f1) \
    <(printf "%s" "$stdin" | cut -f2 | column -t -s $'\t') \
  | fzf -d $'\t' --with-nth=1 --select-1 --header-lines=1 \
  | cut -f2
}

bwjq() {
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
      perl -pe 'chomp if eof' | bwjq_display "${opt_clip[@]}" "${opt_qr[@]}"
    elif [[ "$key" == "tree" ]]; then
      tree --fromfile --noreport .
    elif [[ "$key" == "tsv" ]]; then
      bwjq_fzf | perl -pe 'chomp if eof' | bwjq_display "${opt_clip[@]}" "${opt_qr[@]}"
    fi
  }

}

compdef _bwjq bwjq

alias bwst='bwjq_status'
alias bwsn='bwjq_sync'
alias bwul='bwjq_unlock'
alias bwlk='bwjq_lock'
alias bwgp='bwjq_generate -ulns'
alias bwgu='bwjq_generate -uln'

export BWJQ_BWJQ="${0:h}/bwjq.jq"

export BWJQ_PATH="${0:h}"
export BWJQ_CUSTOM="${0:h}/custom"

export BWJQ_JQ='jq'
export BWJQ_QRENCODE='qrencode -t UTF8'
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  export BWJQ_COPY='clipcopy'
elif [ "$(uname)" = "Darwin" ]; then
  export BWJQ_COPY='pbcopy'
else
  export BWJQ_COPY='xclip -selection clipboard'
fi
