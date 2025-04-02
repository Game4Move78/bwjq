# bwjq
This plugin provides jq scripts to manage a
[bitwarden](https://github.com/bitwarden/cli) session.

## Installation

See [INSTALL.md](INSTALL.md).

## Usage

| Command              | Description             | Deps       |
|----------------------|-------------------------|------------|
| `bwul`               | unlock the vault        |            |
| `bwlk`               | lock the vault          |            |
| `bwst`               | vault status            |            |
| `bwsn`               | sync the vault          |            |
| `bwgu`               | generate username       |            |
| `bwgp`               | generate password       |            |
| `bwjq PATH`          | show value              |            |
| `bwjq -f PATH`       | search values           | `fzf`      |
| `bwjq -c PATH`       | copy value to clipboard |            |
| `bwjq -q PATH`       | print value as QR code  | `qrencode` |

Paths correspond to folder, followed by item followed by the path. So the password in item "myitem" in folder "myfolder" can be shown using `bwjq myfolder/myitem/login/password`. Autocompletions are supported for paths.

## Customization

| Env Variable    | Description          | Examples            |
|-----------------|----------------------|---------------------|
| `BW_JQ`         | jq command           | `jq`, `gojq`        |
| `BWJQ_BWJQ`     | jq script for `bwjq` | `./bwjq_new.jq`     |
| `BWJQ_COPY`     | clipboard command    | `clipcopy`, `xclip` |
| `BWJQ_QRENCODE` | qrencode command     | `./bwjq_new.jq`     |

## Development

All the jq functions used are in `bwjq_utils.jq`. If you want to experiment with new scripts you can use `bwjq_script SCRIPT` which will have folders and items streamed in as inputs, and can be read in order using `read_folders` followed by `read_items`.

| Function                     | Description                         |
|------------------------------|-------------------------------------|
| `read_folders`               | read folders from input stream      |
| `read_items`                 | read items from input stream      |
| `read_folder_map`            | maps folder ids to names            |
| `subfolders`                 | given folder map extract subfolders |
| `read_items_from_folder_map` | use folder map extract items        |
