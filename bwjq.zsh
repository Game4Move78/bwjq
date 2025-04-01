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

bwjq_bwjq_candidates() {

  local -a \
        karg \
        carg \
        rarg \
        earg \
        aarg \

  zparseopts -D -K -E -- \
             {k,-key}=karg \
             {c,-complete}=carg \
             {r,-recursive}=rarg \
             {e,-expand}=earg \
             {a,-all}=aarg \
    || return

  bwjq_unlock || return $?

  prefix="$1"
  cat \
    <(bwjq_request GET '/list/object/folders') \
    <(bwjq_request GET '/list/object/items') \
    | bwjq_jq \
        -nrcM \
        --stream \
        --arg key "${karg[1]}" \
        --arg complete "${carg[1]}" \
        --arg recursive "${rarg[1]}" \
        --arg expand "${earg[1]}" \
        --arg all "${aarg[1]}" \
        --arg prefix "$prefix" -f "${BWJQ_BWJQ}"
}

_bwjq_bwjq() {
  local cur
  cur="${words[CURRENT]}"
  local -a opts

  opts=("${(@f)$(bwjq_bwjq_candidates ${(Q)cur})}")
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
        carg \
        qrarg \
        fzfarg

  zparseopts -D -K -E -- \
             {c,-clipboard}=carg \
             {q,-qrcode}=qrarg \
             -fzf=fzfarg \
    || return

  local -a bwjq_args

  if [[ ${#fzfarg} -ne 0 ]]; then
    bwjq_args+=("--expand" "--all")
  fi

  bwjq_bwjq_candidates "${bwjq_args[@]}" -c -r -k "$@" \
  | {
    local key
    read -r key
    if [[ "$key" == "value" ]]; then
      bwjq_display "${carg[@]}" "${qarg[@]}"
    elif [[ "$key" == "tree" ]]; then
      tree --fromfile --noreport .
    elif [[ "$key" == "tsv" ]]; then
      bwjq_fzf | bwjq_display "${carg[@]}" "${qarg[@]}"
    fi
  }

}

compdef _bwjq_bwjq bwjq_bwjq

alias bwjq='bwjq_bwjq'
alias bwst='bwjq_status'
alias bwsn='bwjq_sync'
alias bwul='bwjq_unlock'
alias bwlk='bwjq_lock'
alias bwgp='bwjq_generate -ulns'
alias bwgu='bwjq_generate -uln'

export BWJQ_BWJQ="${0:h}/bwjq.jq"
