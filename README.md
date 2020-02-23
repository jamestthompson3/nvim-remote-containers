# NVIM-Remote-Containers

This plugin aims to give you the functionality of VSCode's [remote container development](https://code.visualstudio.com/docs/remote/containers) plugin. It will allow you to spawn and develop in docker containers and pulls config information from a `.devcontainer.json` file.

## Available Functions

- `parseConfig`: parses `.devcontainer.json` file
- `attachToContainer`: Attaches to a docker container or builds a container from a user chose image
- `buildContainer`: Builds container from the Dockerfile specified in the `.devcontainer.json` file

## Extras

Set your statusline to reflect the current connected container through `g:currentContainer`:
```viml
hi Container guifg=#BADA55 guibg=Black
set statusline+=%#Container#%{g:currentContainer}
```
