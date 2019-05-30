# tabpage-jumper

## Introduciton

This plugin is built for VIM users switching between previously and currently opened tabpages, it works exactly like VIM built-in shortkey Ctrl+i/Ctrl+o, except for it sources tabpages instead of text postions.     
If you are a VIM tabpage user for either developing or just editing, it could be quite a handy tool for you to deal with different opened tabpges, especially when tabpages's growing more and more. Before I decided to make this plugin, I'vd been drained much by lots of tabpages opened at the same time, and the built-in tabpage commands don't support this feature, so each time I have to remember the tabpage number and jump back manually. In this case, I got lost many times, but for now, with this small plugin, you don't have to worried about being lost at all!    
This plugin maintains a jumplist for tabpages just like Ctrl+i/Ctrl+o, it will remember the tabpages you have entered or leaved, newly opened or closed. This jumplist will always stay updated when event #TabEnter and #TabLeave comes, even if you use tabmove command to move current tabpge, it will stay updated as well.   
Addtionally, for robustness purpose, I add self-check in the code in case the event triggers #TabEnter or #TabLeave doesn't work well sometimes. When this case happens, plugin will wipe the jumplist history and restart working from null list.   

## Install
#### 1. Downloading file
Just download both files(jumper.vim & setting.vim) with the directories, and put the root directory(tabpage-jumper/) under your own .vim/bundle folder. Remember don't break current directory levels when downloading it.

#### 2. Using Vundle
Put below line in your .vimrc file for getting this plugin,   
`Plugin 'mingsxs/tabpage-jumper'`    
and do   
`PluginInstall`   

##Option
By default, the jumplist length is 10, which means, only 10 previous tabpage number will be remembered and updated. If you want to change jumplist length, put script line like below in your .vimrc or whatever .vim file that will be sourced during VIM startup.   
`let g:tabpage_queue_max = 20`

## Mapping
By default, operation 'Go to previous tabpage' is mapped to shortkey '\[t', and operation 'Go to next tabpage' is mapped to '\[t', you can set them as what you like.
##### -Cancel the existent mapping
edit file 'tabpage-jumper/plugin/setting.vim', and cancel the lines below,
(```)
nnoremap <silent> [t :call mingsxs#tabpage#jumper#GoPreviousTabpage()<cr>     
nnoremap <silent> ]t :call mingsxs#tabpage#jumper#GoNextTabpage()<cr>     
\-----------------------------------------------------------------------------     
" nnoremap <silent> ]t :call mingsxs#tabpage#jumper#GoNextTabpage()<cr>    
" nnoremap <silent> ]t :call mingsxs#tabpage#jumper#GoNextTabpage()<cr>    
(```)

##### -Add your own mapping
add two lines mapping for 'Go to previous tabpage' & 'Go to next tabpage' operation in either above setting.vim file or your own .vimrc file, for example,   
(```)
nnoremap <silent> <...> *** :call mingsxs#tabpage#jumper#GoNextTabpage()<cr>    
nnoremap <silent> <...> *** :call mingsxs#tabpage#jumper#GoNextTabpage()<cr>    
(```)

After getting all these ready, then just get started!
