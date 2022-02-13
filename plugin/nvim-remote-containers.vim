command! AttachToContainer lua require'docker'.attachToContainer()
command! -nargs=1 BuildImage  lua require'docker'.buildImage(<f-args>)
command! StartImage lua require'docker'.startImage()
command! Parse lua require'docker'.parseConfig()

command! ComposeUp lua require'docker-compose'.composeUp()
command! ComposeDestroy lua require'docker-compose'.composeDestroy()
command! ComposeDown lua require'docker-compose'.composeDown()
