
"----------------------------------------------------
" This file contains mappings and autocmd event.    |
"                                                   |
" Date: 2019/05/24                                  |
" Author: Ming Li (adagio.ming@gmail.com)           |
"----------------------------------------------------


"-----------------------------------------------------------------------
" file sourced flag.
"-----------------------------------------------------------------------
if !exists('g:user_setting_sourced')
    let g:user_setting_sourced = 1
endif


"-----------------------------------------------------------------------
" update tabpage jump queue and tabpage queue numbers.
"-----------------------------------------------------------------------
autocmd TabLeave * :call mingsxs#jumper#MaintainJumpQueueWhenLeave()
autocmd TabEnter * :call mingsxs#jumper#MaintainJumpQueueWhenEnter()


"-----------------------------------------------------------------------
" Vim tabpage feature map.
"-----------------------------------------------------------------------
" go to previous tabpage in tabpage jump list.
nnoremap <silent> [t :call mingsxs#jumper#GoPreviousTabpage()<cr>

" go to next tabpage in tabpage jump list.
nnoremap <silent> ]t :call mingsxs#jumper#GoNextTabpage()<cr>

