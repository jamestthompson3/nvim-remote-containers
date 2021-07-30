command! AttachToContainer lua require'docker'.attachToContainer()
command! -nargs=1 BuildImage  lua require'docker'.buildImage(<f-args>)
command! StartImage lua require'docker'.startImage()
