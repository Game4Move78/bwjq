# bwjq
This plugin provides jq scripts to manage a
[bitwarden](https://github.com/bitwarden/cli) session.

## Purpose

This tool uses pure ZSH and JQ scripting to get values from bitwarden through a simple and usable interface. It can be used like the familiar standard unix password manager `pass`, which is very good but does not have the same cross platform compatibility as bitwarden.

Folders, vault item names and then their templates are nested into one folder hierarchy, so it can be used like `bwjq myfolder/myitem/login/password`. At the moment bwjq supports listing the store tree under a given path, autocompletions and searching store paths from the fuzzy finder using `fzf`. It should be much faster than bitwarden CLI because it makes RESTful API calls to the local express web server launched by bw serve, which seems to noticeably reduce overhead from launching their node js app every time.

If there is interest I can add additional features. Contributions and feedback are welcome.

## Installation

See [INSTALL.md](INSTALL.md).

## Usage

| Command        | Description             | Notes           |
|----------------|-------------------------|-----------------|
| `bwul`         | unlock the vault        |                 |
| `bwlk`         | lock the vault          |                 |
| `bwst`         | vault status            |                 |
| `bwsn`         | sync the vault          |                 |
| `bwgu`         | generate username       |                 |
| `bwgp`         | generate password       |                 |
| `bwjq PATH`    | show value              |                 |
| `bwjq -f PATH` | search values           | Uses `fzf`      |
| `bwjq -c PATH` | copy value to clipboard | Uses `clipcopy` |
| `bwjq -q PATH` | print value as QR code  | Uses `qrencode` |

Paths correspond to folder, followed by item followed by the path. So the password in item "myitem" in folder "myfolder" can be shown using `bwjq myfolder/myitem/login/password`. Items without a folder are prefixed by `/`. Autocompletions are supported for paths.

## Customization

| Env Variable    | Description          | Examples            |
|-----------------|----------------------|---------------------|
| `BWJQ_JQ`         | jq command           | `jq`, `gojq`        |
| `BWJQ_BWJQ`     | jq script for `bwjq` | `./bwjq_new.jq`     |
| `BWJQ_COPY`     | clipboard command    | `clipcopy`, `xclip` |
| `BWJQ_QRENCODE` | qrencode command     | `qrencode -t UTF8`  |

## Development

All the jq functions used are in `bwjq_utils.jq`. If you want to experiment with new scripts you can use `bwjq_script SCRIPT` which will have folders and items streamed in as inputs, and can be read in order using `read_folders` followed by `read_items`.

| Function                     | Description                         |
|------------------------------|-------------------------------------|
| `read_folders`               | read folders from input stream      |
| `read_items`                 | read items from input stream      |
| `read_folder_map`            | maps folder ids to names            |
| `subfolders`                 | given folder map extract subfolders |
| `read_items_from_folder_map` | use folder map extract items        |

## Limitations

At the moment the argument parsing is basic and uses zparseopts. Flags such as `-q` and `-f` can be written as `-q -f` but not `-q`. Search terms can be provided to fzf finder, but have not yet been implemented for multiple command line arguments.

## Related

[bw](https://bitwarden.com/help/cli/)
[bw serve](https://bitwarden.com/help/bitwarden-apis/#vault-management-api)
[jq](https://jqlang.org/manual/)
[rbw](https://github.com/doy/rbw/)
