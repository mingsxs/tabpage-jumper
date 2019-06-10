
"----------------------------------------------------
" This file contains main-body of tabpage jumper    |
" plugin.                                           |
"                                                   |
" Date: 2019/05/24                                  |
" License: MIT                                      |
" Author: Ming Li (adagio.ming@gmail.com)           |
"----------------------------------------------------


" Check necessary events dependency before sourcing script.
if !(exists('##TabEnter') && exists('##TabLeave'))
    echomsg "Error: Plugin requires event #TabEnter & #TabLeave supported, update VIM first."
    finish
endif

"-----------------------------------------------------------------------
" Navigate between previous and next tabpages.
"-----------------------------------------------------------------------
" Tabpage jump queue maximum length.
if !exists('g:tabpage_queue_max')
    let g:tabpage_queue_max = 10
endif

" jump queue global initializations.
if !exists('s:tabpageJumpQueue')
    " tabpage jump queue.
    let s:tabpageJumpQueue = [1]
    " index of current tabpage in jump queue.
    let s:tabpageJumpQueueCurrentIndex = 0
    " recorded all tabpages count.
    let s:tabpagesNumber = 1
endif

" update tabpage number in jump queue when open a new tabpage.
function s:UpdateTabpageNumberWhenNew()
    " this tabpage is new opened tabpage.
    let l:newTabpageNumber = tabpagenr()
    let l:i = 0
    " skip the last item.
    let l:length = len(s:tabpageJumpQueue) - 1
    while l:i < l:length
        if s:tabpageJumpQueue[l:i] >= l:newTabpageNumber
            let s:tabpageJumpQueue[l:i] += 1
        endif
        let l:i += 1
    endwhile
endfunction

" update tabpage number in jump queue when close a tabpage.
function s:UpdateTabpageNumberAfterClosed()
    " this tabpge number indicates the one it will enter, not the closed one.
    let l:newTabpageNumber = tabpagenr()
    let l:closedTabpageNumber = s:tabpageLeaved
    let l:i = 0
    let l:length = len(s:tabpageJumpQueue)
    while l:i < l:length
        if s:tabpageJumpQueue[l:i] == l:closedTabpageNumber
            call remove(s:tabpageJumpQueue, l:i)
            let l:length -= 1
            continue
        elseif s:tabpageJumpQueue[l:i] > l:newTabpageNumber
            let s:tabpageJumpQueue[l:i] -= 1
        endif
        let l:i += 1
    endwhile
    " remove duplicate neighbours.
    let l:i = 0
    let l:length -= 1
    while l:i < l:length
        if s:tabpageJumpQueue[l:i] == s:tabpageJumpQueue[l:i+1]
            call remove(s:tabpageJumpQueue, l:i)
            let l:length -= 1
            continue
        endif
        let l:i += 1
    endwhile
endfunction

" tabpage jump queue updating trigger and tabpage number when #TabEnter comes.
" ****************************CLARIFICATION*****************************
" Background:
" 1. Jump queue updating is always triggered by event #TabEnter, but functions to
" switch between tabpages will trigger it as well.
" 2. command tabmove{n} will move current tabpage to somewhere else yet no
" triggering #TabEnter/#TabLeave event, therefore, jump queue stays unchanged.
" Workaround:
" 1. unsetting flag s:tabpageJumpQueueUpdateTrigger will not trigger jump queue
" updating, even a event #TabEnter comes, this flag can only be set by functions:
" mingsxs#tabpage#jumper#GoPreviousTabpage & mingsxs#tabpage#jumper#GoNextTabpage.
" this flag is a switch, to make sure event signal comes from commands & 
" mappings input instead of definded functions.
" 2. update s:tabpageOpened when event #TabLeave comes, this parameter is
" a workaround to sovle tabm{*} command jumping issue.
" **********************************************************************
if !exists('s:tabpageJumpQueueUpdateTrigger')
    let s:tabpageJumpQueueUpdateTrigger = 1
    " var below stores the opened tabpage number.
    let s:tabpageOpened = 1
    " var below stores tabpage number just left.
    let s:tabpageLeaved = 1
    " var below set the tabpageJumpQueue reset flag.
    let s:tabpageJumpQueueRst = 0
endif

" update tabpage jump queue, can only be triggered when open a new tab or
" manually jump to certain existent tabpage.
function! mingsxs#jumper#MaintainJumpQueueWhenEnter()
    let l:curPageNumber = tabpagenr()

    if s:tabpageJumpQueueUpdateTrigger
        " update tabpage jump queue.
        if s:tabpageJumpQueueCurrentIndex > 0
            let s:tabpageJumpQueue = s:tabpageJumpQueue[:s:tabpageJumpQueueCurrentIndex-1]
                        \ + s:tabpageJumpQueue[s:tabpageJumpQueueCurrentIndex+1:]
                        \ + [s:tabpageJumpQueue[s:tabpageJumpQueueCurrentIndex], l:curPageNumber]
        else
            let s:tabpageJumpQueue = s:tabpageJumpQueue[1:] + [s:tabpageJumpQueue[0], l:curPageNumber]
        endif

        let l:total = tabpagenr('$')
        " if new tabpages opened.
        if l:total > s:tabpagesNumber
            call s:UpdateTabpageNumberWhenNew()
            let s:tabpagesNumber = l:total
        " if one tabpage closed.
        elseif l:total < s:tabpagesNumber
            if !s:tabpageJumpQueueRst
                call s:UpdateTabpageNumberAfterClosed()
            else
                let s:tabpgeJumpQueueRst = 0
            endif
            let s:tabpagesNumber = l:total
        endif

        " check if tabpage jump queue overflows.
        if len(s:tabpageJumpQueue) > g:tabpage_queue_max
            let s:tabpageJumpQueue = s:tabpageJumpQueue[1:]
        endif

        " update current tabpage location index.
        let s:tabpageJumpQueueCurrentIndex = len(s:tabpageJumpQueue) - 1
    endif

    " update s:tabpageOpened to current tabpage number at last.
    let s:tabpageOpened = l:curPageNumber
endfunction

" update tabpage jump queue when tabmove{N} command was executed.
" ****************************CLARIFICATION*****************************
" Background:
" command tabmove{n} will move current tabpage to somewhere else yet no
" triggering #TabEnter/#TabLeave event, therefore, jump queue stays unchanged.
" Workaround:
" How to know if user has executed a tabm{*} command to switch between
" tabpages manually yet making no updating of jump queue? we know that each
" event #TabEnter pairs to event #TabLeave, during this pair, the tabpage
" number should stay unchanged, and equals to tabpagenr().
"
" 1. each time when event #TabEnter comes, update the s:tabpageOpened to
" current tabpage number, (see :help tabpagenr()).
"
" 2. each time when event #TabLeave comes, compare s:tabpageOpened with
" current tabpage number, if don't match, then we know a tabm{*}  command
" should has been executed before last tabpage operation.
"
" 3. now we know, s:tabpageOpened is where the tabm{*} command jumps from,
" and current tabpage is where the tabm{*} command jumps to. then use them to
" adjust our jump queue.
"
" NOTICE:
"
" Since event trigger is not fully reliable, when user types mapping to use
" this plugin for tabpage switch, function defined below will make a double
" check of jump queue, in case it is always correctly updated. If error is
" detected, jump queue will reset.
"
" **********************************************************************
" compare current tabpage number with the one stored when #TabEnter comes.
function! mingsxs#jumper#MaintainJumpQueueWhenLeave()
    let l:curPageNumber = tabpagenr()
    let l:i = 0
    let l:length = len(s:tabpageJumpQueue)
    if (l:curPageNumber != s:tabpageOpened) && (!s:tabpageJumpQueueRst)
        if l:curPageNumber > s:tabpageOpened
            while l:i < l:length
                if s:tabpageJumpQueue[l:i] > s:tabpageOpened && s:tabpageJumpQueue[l:i] <= l:curPageNumber
                    let s:tabpageJumpQueue[l:i] -= 1
                elseif s:tabpageJumpQueue[l:i] == s:tabpageOpened
                    let s:tabpageJumpQueue[l:i] = l:curPageNumber
                endif
                let l:i += 1
            endwhile
        else
            while l:i < l:length
                if s:tabpageJumpQueue[l:i] >= l:curPageNumber && s:tabpageJumpQueue[l:i] < s:tabpageOpened
                    let s:tabpageJumpQueue[l:i] += 1
                elseif s:tabpageJumpQueue[l:i] == s:tabpageOpened
                    let s:tabpageJumpQueue[l:i] = l:curPageNumber
                endif
                let l:i += 1
            endwhile
        endif
    endif
    let s:tabpageLeaved = l:curPageNumber
endfunction

" go to previous tabpage.
function! mingsxs#jumper#GoPreviousTabpage()
    if s:tabpageJumpQueueCurrentIndex > 0
        " close tabpage jump queue trigger flag.
        let s:tabpageJumpQueueUpdateTrigger = 0
        let s:tabpageJumpQueueCurrentIndex -= 1
        let l:previousTabpageNumber = s:tabpageJumpQueue[s:tabpageJumpQueueCurrentIndex]
        let l:jumpCmd = l:previousTabpageNumber.'tabnext'
        exe l:jumpCmd
        " Add robustness.
        let l:curPageNumber = tabpagenr()
        if s:tabpageJumpQueue[s:tabpageJumpQueueCurrentIndex] != l:curPageNumber
            echomsg "Error detected, jumplist cleared."
            let s:tabpageJumpQueue = [l:curPageNumber]
            let s:tabpageJumpQueueCurrentIndex = 0
            let s:tabpageJumpQueueRst = 1
        endif
        return 0
        " open tabpage jump queue trigger flag.
        let s:tabpageJumpQueueUpdateTrigger = 1
    else
        echomsg "No previous tabpage"
    endif
endfunction

" go to next tabpage.
function! mingsxs#jumper#GoNextTabpage()
    if s:tabpageJumpQueueCurrentIndex < len(s:tabpageJumpQueue) - 1
        " close tabpage jump queue trigger flag.
        let s:tabpageJumpQueueUpdateTrigger = 0
        let s:tabpageJumpQueueCurrentIndex += 1
        let l:nextTabpageNumber = s:tabpageJumpQueue[s:tabpageJumpQueueCurrentIndex]
        let l:jumpCmd = l:nextTabpageNumber.'tabnext'
        exe l:jumpCmd
        " Add robustness.
        let l:curPageNumber = tabpagenr()
        if s:tabpageJumpQueue[s:tabpageJumpQueueCurrentIndex] != l:curPageNumber
            echomsg "Error detected, jumplist cleared."
            let s:tabpageJumpQueue = [l:curPageNumber]
            let s:tabpageJumpQueueCurrentIndex = 0
            let s:tabpageJumpQueueRst = 1
        endif
        return 0
        " open tabpage jump queue trigger flag.
        let s:tabpageJumpQueueUpdateTrigger = 1
    else
        echomsg "No next tabpage"
    endif
endfunction

