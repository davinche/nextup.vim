" -----------------------------------------------------------------------------
" Commands --------------------------------------------------------------------
" -----------------------------------------------------------------------------
command! -nargs=* NextUp :call nextup#prompt_create(<q-args>)
command! -nargs=? NextUpRemove :call nextup#prompt_remove(<args>)
command! -nargs=? NextUpEdit :call nextup#prompt_edit(<args>)
command! -nargs=? NextUpComplete :call nextup#prompt_complete(<args>)
command! -nargs=? NextUpUncomplete :call nextup#prompt_wip(<args>)
command! -nargs=? NextUpArchive :call nextup#prompt_archive(<args>)
command! -nargs=? NextUpUnarchive :call nextup#prompt_unarchive(<args>)
command! NextUpArchiveCompleted :call nextup#archive_completed()
command! -nargs=* NextUpList :call nextup#list_todos(1, <q-args>)
command! NextUpClean :call nextup#archive_clean()

" -----------------------------------------------------------------------------
" Mappings --------------------------------------------------------------------
" -----------------------------------------------------------------------------
nnoremap <silent> <Plug>(NextUpFromLine) :call nextup#create_from_line()<CR>
nnoremap <silent> <Plug>(NextUpList> :call nextup#list_todos(1)<CR>

" -----------------------------------------------------------------------------
" Configs ---------------------------------------------------------------------
" -----------------------------------------------------------------------------

if !exists('g:nextup_list_split')
    let g:nextup_list_split = 'horizontal'
endif

" -----------------------------------------------------------------------------
" CONSTANTS -------------------------------------------------------------------
" -----------------------------------------------------------------------------
" determine the directory for the todos
if !exists('g:nextup_directory')
    let g:nextup_directory = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/nunotes'
endif

" setup autoincrement id
if !filereadable(g:nextup_directory . '/_autoincrement')
    let g:nextup_NEXT_ID = 1
else
    let g:nextup_NEXT_ID = str2nr(readfile(g:nextup_directory . '/_autoincrement')[0], 10)
endif
