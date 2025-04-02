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

_bwjq_pipefail() {
  # Usage _bwjq_pipefail ${pipestatus[@]}
  for st in "$@"; do
    if [[ "$st" -ne 0 ]]; then
      return $st
    fi
  done
}

bwjq_eval() {
  local -a cmd=("${(z)1}")
  shift
  "$cmd[@]" "$@"
}

bwjq_jq() {
  bwjq_eval "${BWJQ_JQ:-jq}" "$@"
}

bwjq_copy() {
  cat | bwjq_eval "${BWJQ_COPY:-clipcopy}"
}

bwjq_qrencode() {
  bwjq_eval "${BWJQ_QRENCODE:-qrencode -t UTF8}"
}

bwjq_escape_jq() {
  sed -e 's/\t/\\t/g' -e 's/\n/\\n/g' -e 's/\r/\\r/g'
}

bwjq_raw_jq() {
  sed -e 's/\\t/\t/g' -e 's/\\n/\n/g' -e 's/\\r/\r/g' -e 's/\\\\/\\/g'
}

bwjq_request_params() {
  if [[ $# -eq 0 ]]; then
    return
  fi

  printf "?%s=%s" "$1" "$2"

  local j
  for (( i=3, j=4; i <= $#; i += 2, j += 2)); do
    printf "&%s=%s" "${(P)i}" "${(P)j}"
  done
}

bwjq_request() {

  local -a opt_stdin

  zparseopts -D -K -E -- \
             -stdin=opt_stdin || return

  local method=$1 endpoint=$2 res
  local -a data_args
  local params=$(bwjq_request_params "${@:3}")
  # if ! [[ -t 0 ]]; then
  if [[ ${#opt_stdin[@]} -ne 0 ]]; then
    data_args+=("-d" "$(</dev/stdin)")
  fi

  local serve_port=${BWJQ_SERVE_PORT:-8087}

  curl -sX "$method" "http://localhost:${serve_port}$endpoint$params" -H 'accept: application/json' -H 'Content-Type: application/json' "${data_args[@]}"

}

bwjq_request_path() {
  local -a opt_raw narg opt_stdin

  zparseopts -D -K -E -- \
             -stdin=opt_stdin \
             r=opt_raw || return

  local method="$1" endpoint="$2" jqpath="$3" res exitcode
  local params_list=("${@:4}")
  bwjq_request "${opt_stdin[@]}" "$method" "$endpoint" "${params_list[@]}" \
  | bwjq_jq "${opt_raw[@]}" -ceM "$jqpath"
  _bwjq_pipefail ${pipestatus[@]} || return $?
}

bwjq_status() {
  local res
  res=$(bwjq_request_path -r GET '/status' '.data.template.status')
  _bwjq_pipefail ${pipestatus[@]} || return $?
  printf "%s\n" "$res" >&2
  if [[ "$res" == "unlocked" ]]; then
    return 0
  else
    return 1
  fi
}

bwjq_sync() {
  local res
  bwjq_request_path -r POST '/sync' '.title'
}

bwjq_wait_port() {
  local port limit
  port=$1
  limit=$2
  while ! nc -z localhost $port && [[ $limit -ne 0 ]]; do
        sleep 1
        limit=$((limit-1))
  done
}

bwjq_serve() {
  local serve_port=${BWJQ_SERVE_PORT:-8087}
  if ! pgrep -af "bw serve" > /dev/null 2>&1; then
    bw serve --port ${serve_port} > /dev/null 2> /dev/null &!
    bwjq_wait_port ${serve_port} 5
  fi
}

bwjq_encrypt() {
  if [ -z "${BWJQ_GPG_KEY}" ]; then
    args=("--default-recipient-self")
  else
    args=("--recipient" "${BWJQ_GPG_KEY}")
  fi
  gpg --quiet --batch --yes --default-recipient-self --encrypt -o $@
}

bwjq_decrypt() {
  gpg --quiet --batch --yes --decrypt $@
}

bwjq_unlock_password() {
  if [ ! -f ${gpg_file} ]; then
    return 1
  fi
  local res=$(bwjq_decrypt $1 \
  | {
    awk '{print "{\"password\":\"" $0 "\"}"}' \
    | bwjq_request_path -r --stdin POST /unlock .data.title
  } 2> /dev/null)
  _bwjq_pipefail ${pipestatus[@]} || printf "%s\n" "$res"
}

bwjq_unlock() {
  bwjq_serve

  local st
  if st=$(bwjq_status) 2> /dev/null; then
    return
  fi

  local pass
  local gpg_file

  gpg_file=${BWJQ_PASS_FILE:-~/.config/zsh-bitwarden/pass.gpg}
  mkdir -p $(dirname $gpg_file)

  while ! bwjq_unlock_password $gpg_file; do
    echo -n "Enter your master password: " >&2
    if ! read -s pass; then
      return 1
    fi
    if ! printf "%s" "$pass" | bwjq_encrypt ${gpg_file}; then
      return 1
    fi
  done

}

bwjq_lock() {
  bwjq_serve

  local st res

  if ! st=$(bwjq_status) 2> /dev/null; then
    return
  fi

  bwjq_request_path -r POST /lock .data.title

}

bwjq_display() {
  local -a \
        opt_clip \
        opt_qr

  zparseopts -D -F -K -- \
             {c,-clipboard}=opt_clip \
             {q,-qrcode}=opt_qr || return

  if [[ ${#opt_qr} -ne 0 ]]; then
    bwjq_qrencode
  elif [[ ${#opt_clip} -ne 0 ]]; then
    bwjq_copy
    # { sleep 45 && printf '' | bwjq_copy 2>&1; } &!
    echo "Copied to clipboard. Will clear in 45 seconds"
  else
    cat
  fi
}

bwjq_generate() {
  local -a \
        opt_clip \
        opt_qr \
        opt_lower \
        opt_upper \
        opt_special \
        opt_num \
        opt_len
  zparseopts -D -F -K -- \
             {c,-clipboard}=opt_clip \
             {q,-qrcode}=opt_qr \
             {l,-lowercase}=opt_lower \
             {u,-uppercase}=opt_upper \
             {s,-special}=opt_special \
             {n,-number}=opt_num \
             -length:=opt_len || return

  bwjq_unlock || return $?

  local -a param_list
  (( ${#opt_lower[@]})) && param_list+=( "lowercase" "true" )
  (( ${#opt_upper[@]})) && param_list+=( "uppercase" "true" )
  (( ${#opt_special[@]})) && param_list+=( "special" "true" )
  (( ${#opt_num[@]})) && param_list+=( "number" "true" )
  (( ${#opt_len[@]})) && param_list+=( "length" "${opt_len[-1]}" )

  bwjq_request_path -r GET "/generate$params" .data.data "${param_list[@]}" \
  | sed 's/.$//' | bwjq_display "${opt_clip[@]}" "${opt_qr[@]}"
}

bwjq_init_file() {
  local itemfile=$(mktemp)
  chmod 600 "$itemfile"
  cat > "$itemfile"
  printf "%s" "$itemfile"
}

bwjq_edit_file() {
  local modtime_before=$(stat -c %Y "$1")
  $EDITOR "$1" || return $?
  local modtime_after=$(stat -c %Y "$1")
  if [[ "$modtime_before" -eq "$modtime_after" ]]; then
    shred -u "$itemfile"
    return 1
  fi
}
