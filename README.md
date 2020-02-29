# NVIM-Remote-Containers

This plugin aims to give you the functionality of VSCode's [remote container development](https://code.visualstudio.com/docs/remote/containers) plugin. It will allow you to spawn and develop in docker containers and pulls config information from a `devcontainer.json` file.

## Available Lua Functions

- `parseConfig`: parses `.devcontainer.json` file
- `attachToContainer`: Attaches to a docker container or builds a container from a user chose image
- `buildImage`: Builds container from the Dockerfile specified in the `devcontainer.json` file

## Available Vim Commands

- `AttachToContainer` wrapper for the `attachToContainer` lua function.
- `BuildImage` wrapper for the `buildImage` lua function.

## Extras

Set your statusline to reflect the current connected container through `g:currentContainer`:
```viml
hi Container guifg=#BADA55 guibg=Black
set statusline+=%#Container#%{g:currentContainer}
```

## Usage

If you are currently in a directory that has a `devcontainer.json` file, you can run the following vim commands:
```viml
" If you haven't built the image specified in you config:
:BuildImage
" Attach to the container you just built / a previously built container
:AttachToContainer
```
