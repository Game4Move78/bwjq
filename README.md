# bwjq
This plugin provides jq scripts to manage a [bitwarden](https://github.com/bitwarden/cli) session

## Installation

See [INSTALL.md](INSTALL.md).

## Usage

| Command        | Description             | Deps       |
|----------------|-------------------------|------------|
| `bwul`         | unlock the vault        |            |
| `bwlk`         | lock the vault          |            |
| `bwst`         | vault status            |            |
| `bwsn`         | sync the vault          |            |
| `bwgu`         | generate username       |            |
| `bwgp`         | generate password       |            |
| `bwjq PATH`    | show value              |            |
| `bwjq -f PATH` | search values           | `fzf`      |
| `bwjq -c PATH` | copy value to clipboard |            |
| `bwjq -q PATH` | print value as QR code  | `qrencode` |

## Parameters

PATH follows format FOLDERNAME/ITEMNAME/VALUEPATH. This value supports tab autocompletions.

## Customization

| Env Variable    | Description          | Examples            |
|-----------------|----------------------|---------------------|
| `BW_JQ`         | jq command           | `jq`, `gojq`        |
| `BWJQ_BWJQ`     | jq script for `bwjq` | `./bwjq_new.jq`     |
| `BWJQ_COPY`     | clipboard command    | `clipcopy`, `xclip` |
| `BWJQ_QRENCODE` | qrencode command     | `./bwjq_new.jq`     |
