# NVIM-Remote-Containers

This plugin aims to give you the functionality of VSCode's [remote container development](https://code.visualstudio.com/docs/remote/containers) plugin. It will allow you to spawn and develop in docker containers and pulls config information from a `devcontainer.json` file.

## Available Lua Functions

- `parseConfig`: parses `devcontainer.json` file--takes in argument specifying type (dockerCompose, dockerFile, image)
- `attachToContainer`: Attaches to a docker container or builds a container from a user chose image
- `buildImage`: Builds container from the Dockerfile specified in the `devcontainer.json` file. Takes a boolean parameter to determine whether or not to show the build process in a floating window or in the quickfix list.
- `composeUp`: Brings docker-compose up
- `composeDown`: Brings docker-compose down
- `composeDestroy`: Destorys docker-compose containers

## Available Vim Commands

- `AttachToContainer` wrapper for the `attachToContainer` lua function.
- `BuildImage` wrapper for the `buildImage` lua function, takes "true" or "false" as an argument to decide whether or not to show the build progress in a floating window.
- `StartImage` lists all available images and starts the one selected by you given the arguments found in the `devcontainer.json` file in your project's workspace.
- `ComposeUp` wrapper for `composeUp` lua function.
- `ComposeDown` wrapper for `composeDown` lua function.
- `ComposeDestroy` wrapper for `composeDestroy` lua function.

## Extras

Set your statusline to reflect the current connected container through `g:currentContainer`:

```viml
hi Container guifg=#BADA55 guibg=Black
set statusline+=%#Container#%{g:currentContainer}
```

## Usage

Before using this plugin, you should install the `jsonc` treesitter module: `:TSInstall jsonc`, this is needed to parse the config file.

If you are in the root directory that has the `.devcontainer/` folder, you can run the following vim commands:

```viml
" If you haven't built the image specified in your config.
" Takes `true` or `false` depending on whether or not you want to see the build progress in a floating window.
:BuildImage
" Attach to the container you just built / a previously built container
:AttachToContainer
" Start a container from a pre-built image
:StartImage

" Runs the docker-compose -f <file> up
:ComposeUp
" Runs docker-compose -f <file> down
:ComposeDown
" Runs docker-compose rm <file> -fsv
:ComposeDestroy
```

## Contributing

Lua code is formatted in a pre-commit hook using [stylelua](https://github.com/JohnnyMorganz/StyLua). Please install this as part of contributing to the project.
