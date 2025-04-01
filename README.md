# bwjq
This plugin provides jq scripts to manage a [bitwarden](https://github.com/bitwarden/cli) session

## Installation

See [INSTALL.md](INSTALL.md).

## Usage

| Command                 | Description                 | Deps       |
|-------------------------|-----------------------------|------------|
| `bwul`                  | unlock the vault            |            |
| `bwlk`                  | lock the vault              |            |
| `bwst`                  | vault status                |            |
| `bwsn`                  | sync the vault              |            |
| `bwg`                   | alphanum + special password |            |
| `bwgs`                  | alphanum password           |            |
| `bwjq PATH`             | show value                  |            |
| `bwjq --fzf PATH`       | search values               | `fzf`      |
| `bwjq --clipboard PATH` | copy value to clipboard     |            |
| `bwjq --qrcode PATH`    | print value as QR code      | `qrencode` |

## Parameters

PATH follow the format FOLDERNAME/ITEMNAME/VALUEPATH. This value supports tab autocompletions.

## Customization

Clipboard uses variable `BW_COPY`. Defaults to

| MacOSX  | pbcopy   |
| Wayland | clipcopy |
| Else    | xclip    |

jq executable found using variable `BW_JQ`. Can switch to other implementations (e.g. `export BW_JQ='gojq'`) but behaviour may differ.
