# NVIM-Remote-Containers

This plugin aims to give you the functionality of VSCode's [remote container development](https://code.visualstudio.com/docs/remote/containers) plugin. It will allow you to spawn and develop in docker containers and pulls config information from a `devcontainer.json` file.

## Available Lua Functions

- `parseConfig`: parses `devcontainer.json` file
- `attachToContainer`: Attaches to a docker container or builds a container from a user chose image
- `buildImage`: Builds container from the Dockerfile specified in the `devcontainer.json` file. Takes a boolean parameter to determine whether or not to show the build process in a floating window or in the quickfix list.

## Available Vim Commands

- `AttachToContainer` wrapper for the `attachToContainer` lua function.
- `BuildImage` wrapper for the `buildImage` lua function, takes "true" or "false" as an argument to decide whether or not to show the build progress in a floating window.
- `StartImage` lists all available images and starts the one selected by you given the arguments found in the `devcontainer.json` file in your project's workspace.

## Extras

Set your statusline to reflect the current connected container through `g:currentContainer`:

```viml
hi Container guifg=#BADA55 guibg=Black
set statusline+=%#Container#%{g:currentContainer}
```

## Usage

If you are currently in a directory that has a `devcontainer.json` file, you can run the following vim commands:

```viml
" If you haven't built the image specified in you config.
" Takes `true` or `false` depending on whether or not you want to see the build progress in a floating window.
:BuildImage
" Attach to the container you just built / a previously built container
:AttachToContainer
" Start a container from a pre-built image
:StartImage
```

## Contributing

Lua code is formatted in a pre-commit hook using [stylelua](https://github.com/JohnnyMorganz/StyLua). Please install this as part of contributing to the project.
