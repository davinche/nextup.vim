" -----------------------------------------------------------------------------
" UTILS -----------------------------------------------------------------------
" -----------------------------------------------------------------------------
function! nextup#get_date(...)
    if has('win32')
        return tolower(nextup#trim(system('date /t')))
    endif

    let l:cmd = 'date'
    let l:flags = ''
    let l:fmt = '+%F'
    " 1st param will be any additional date args
    if a:0 > 0
        let l:flags = a:1
    endif
    " 2nd param will be output date format
    if a:0 == 2
        let l:fmt = a:2
    endif
    return nextup#trim(system(join([l:cmd, l:flags, '"'.l:fmt.'"'], ' ')))
endfunction

function! nextup#get_epoch(date)
    if has('mac')
        return str2nr(nextup#get_date('-j -f "%F" ' . a:date, '+%s'), 10)
    else
        return str2nr(nextup#get_date('-d ' . a:date, '+%s'), 10)
    endif
endfunction

function! nextup#get_tomorrow(...)
    let fmt = '+%F'
    if a:0 > 0
        let fmt = a:1
    endif

    if !has('mac')
        return nextup#get_date('-d "tomorrow"', fmt)
    endif
    return nextup#get_date('-v +1d', fmt)
endfunction

function! nextup#get_next_day(day)
    if len(a:day) < 3
        return ''
    endif
    let days_map = {'mon': 0, 'tue': 1, 'wed': 2, 'thu': 3, 'fri': 4, 'sat': 5, 'sun': 6}
    let l:target_lower = tolower(a:day)
    if !has_key(days_map, l:target_lower[0:2])
        return ''
    endif

    if !has('mac')
        return nextup#get_date('-d "next '. l:target . '"')
    endif

    " get the index of today
    let l:today_index = get(days_map, nextup#get_date('', '+%a'))
    let l:target_index = get(days_map, l:target_lower[0:2])

    " get date offset
    let l:diff = l:target_index - l:today_index
    if l:diff <= 0
        let l:diff += 7
    endif
    return nextup#get_date('-v +'.l:diff.'d')
endfunction

function! nextup#get_friendly_date(date)
    if has('mac')
        let l:flags = '-j -f "%F" ' . a:date
    else
        let l:flags = '-d '  . a:date
    endif
    let l:date = nextup#trim(nextup#get_date(l:flags, '+%e'))
    return nextup#get_date(l:flags,'+%a %b') . ' ' . l:date
endfunction

function! nextup#trim(inputStr)
    if len(a:inputStr) == 0
        return ''
    endif
    let l:trimmed = substitute(a:inputStr, '^\s\+', '', '')
    let l:trimmed = substitute(l:trimmed, '\s*\n*$', '', '')
    return l:trimmed
endfunction

function! nextup#increment_id()
    let g:nextup_NEXT_ID += 1
    call writefile([g:nextup_NEXT_ID], g:nextup_directory . '/_autoincrement')
endfunction

function! nextup#remove_file(file)
    if has('win32')
        call system('del /s /q ' . shellescape(resolve(a:file)))
    else
        call system('rm -rf ' . shellescape(resolve(a:file)))
    endif
endfunction

" -----------------------------------------------------------------------------
" Index Manipulation ----------------------------------------------------------
" -----------------------------------------------------------------------------

" comparator function for sorted index
function! nextup#index_comparator(p1, p2)
    let l:date1 = fnamemodify(a:p1, ':h:h:t')
    let l:date2 = fnamemodify(a:p2, ':h:h:t')

    " if either is not date1 or date2 is not actually a date, then we
    " prioritize it to the front of the list
    if l:date1 !~ '\d\{4\}-\d\{2\}-\d\{2\}'
        return -1
    elseif l:date2 !~ '\d\{4}-\d\{2}-\d\{2}'
        return 1
    endif

    if l:date1 == l:date2
        let l:id1 = str2nr(fnamemodify(a:p1, ':h:t'), 10)
        let l:id2 = str2nr(fnamemodify(a:p2, ':h:t'), 10)
        return l:id2 - l:id1
    endif
    return str2nr(nextup#get_epoch(l:date1)) - str2nr(nextup#get_epoch(l:date2))
endfunction

" Index Bootstrap Method  -----------------------------------------------------
function! nextup#load_index()
    if exists('g:nextup_todos_list')
        return
    endif

    let g:nextup_todos_list = split(globpath(resolve(g:nextup_directory . '/nextup'), '**/index.nextup'), "\n")
    let g:nextup_todos_list = uniq(sort(g:nextup_todos_list, 'nextup#index_comparator'))
endfunction

" Index entry ADD/REMOVE ------------------------------------------------------
function! nextup#add_to_index(todoList, todoPath)
    call add(a:todoList, resolve(a:todoPath))
    call uniq(sort(a:todoList, 'nextup#index_comparator'))
endfunction

function! nextup#remove_from_index(index, search)
    let l:index = index(a:index, a:search)
    if l:index != -1
        call remove(a:index, l:index)
    endif
endfunction

" User Input String Parser ----------------------------------------------------
function! nextup#parse_input(inputStr)
    let l:tags = []
    let l:date = 'untagged'

    let l:trimmed = nextup#trim(a:inputStr)
    let l:chunks = split(l:trimmed, ' ')
    call filter(l:chunks, '!empty(nextup#trim(v:val))')
    let l:len = len(l:chunks)

    let l:i = 0
    while l:i < l:len
        let l:curr = l:i
        let l:i += 1
        " check for tags
        if l:chunks[l:curr][0] == '+'
            let l:tags = add(l:tags, l:chunks[l:curr][1:])
            continue
        endif

        " check for due date
        if l:curr == l:len-1
            " match against due
            if l:len > 1 && l:chunks[l:curr-1] ==? 'due'
                " Get the due date based on the word
                let l:target =  tolower(l:chunks[l:curr])

                if l:target ==? 'today'
                    let l:date = nextup#get_date()
                elseif l:target ==? 'tomorrow'
                    let l:date = nextup#get_tomorrow()
                endif

                " check against days of the week
                let l:target_lower = tolower(l:target)
                let l:potential_date = nextup#get_next_day(l:target_lower)
                if !empty(l:potential_date)
                    let l:date = l:potential_date
                    break
                endif
            endif
        endif
    endwhile

    return {
      \ 'value': l:trimmed,
      \ 'tags': l:tags,
      \ 'date': l:date,
    \ }
endfunction

" -----------------------------------------------------------------------------
" User Prompts ----------------------------------------------------------------
" -----------------------------------------------------------------------------
" could use some refactor


function! nextup#prompt_create(input)
    let l:text = nextup#trim(a:input)
    if empty(l:text)
        let l:text = nextup#trim(input('create next-up: '))
        echo "\n"
    endif
    call nextup#create_nextup_from_text(l:text)
endfunction

function! nextup#prompt_edit(...)
    if a:0 > 0
        let l:id = nextup#trim(a:1)
    else
        let l:id = nextup#trim(input('edit next-up: '))
        echo "\n"
    endif
    if !empty(l:id)
        if nextup#edit_todo(l:id) == v:true
            echo 'Next-up [' . l:id . '] updated.'
        endif
    endif
endfunction

function! nextup#prompt_remove(...)
    if a:0 > 0
        let l:id = nextup#trim(a:1)
    else
        let l:id = nextup#trim(input('remove next-up: '))
        echo "\n"
    endif
    if !empty(l:id)
        if nextup#remove_todo(l:id) == v:true
            echo 'Next-up [' . l:id . '] removed.'
        endif
    endif
endfunction

function! nextup#prompt_complete(...)
    if a:0 > 0
        let l:id = nextup#trim(a:1)
    else
        let l:id = nextup#trim(input('complete next-up: '))
        echo "\n"
    endif
    if !empty(l:id)
        if nextup#complete_todo(l:id) == v:true
            echo 'Next-up [' . l:id . '] completed.'
        endif
    endif
endfunction

function! nextup#prompt_archive(...)
    if a:0 > 0
        let l:id = nextup#trim(a:1)
    else
        let l:id = nextup#trim(input('archive next-up: '))
        echo "\n"
    endif
    if !empty(l:id)
        if nextup#archive_todo(l:id) == v:true
            echo 'Next-up [' . l:id . '] archived.'
        endif
    endif
endfunction

function! nextup#prompt_unarchive(...)
    if a:0 > 0
        let l:id = nextup#trim(a:1)
    else
        let l:id = nextup#trim(input('unarchive next-up: '))
        echo "\n"
    endif
    if !empty(l:id)
        if nextup#unarchive_todo(l:id) == v:true
            echo 'Next-up [' . l:id . '] unarchived.'
        endif
    endif
endfunction

function! nextup#prompt_wip()
    if a:0 > 0
        let l:id = nextup#trim(a:1)
    else
        let l:id = nextup#trim(input('resume next-up: '))
        echo "\n"
    endif
    if !empty(l:id)
        if nextup#complete_todo(l:id, 1) == v:true
            echo 'Next-up [' . l:id . '] is now marked as WIP.'
        endif
    endif
endfunction

" -----------------------------------------------------------------------------
" NEXT-UP CRUD ----------------------------------------------------------------
" -----------------------------------------------------------------------------
function! nextup#create_nextup_from_text(text)
    let text = nextup#trim(a:text)
    if !empty(text)
        let l:id = nextup#create_todo(nextup#parse_input(text))
        echo 'Next-up [' . l:id . '] created.'
    endif
endfunction

function! nextup#create_from_line()
    let text = nextup#trim(getline('.'))
    call nextup#create_nextup_from_text(text)
endfunction

function! nextup#create_todo(todo, ...)
    let l:todo = nextup#trim(get(a:todo, 'value', ''))
    if empty(l:todo)
        return
    endif

    " make sure the todos directory exists
    call mkdir(g:nextup_directory, 'p')
    call mkdir(g:nextup_directory . '/nextup', 'p')
    call mkdir(g:nextup_directory . '/tags', 'p')

    " use custom index (edit) or autoincrement
    if a:0 == 1
        let l:curr_id = a:1
    else
        let l:curr_id = g:nextup_NEXT_ID
        call nextup#increment_id()
    endif

    " create the folder
    let l:dir = g:nextup_directory . '/nextup/' . get(a:todo, 'date') . '/' . l:curr_id
    call mkdir(l:dir, 'p')
    let l:file = l:dir . '/index.nextup'

    " create tags
    let l:tags = get(a:todo, 'tags', [])

    for l:t in l:tags
        " check to see if tag file exists
        let l:tags_file = g:nextup_directory . '/tags/' . l:t
        if filereadable(l:tags_file)
            let l:existing = readfile(l:tags_file)
            call nextup#add_to_index(l:existing, l:file)
            call writefile(l:existing, l:tags_file)
        else
            call writefile([l:file], l:tags_file)
        endif
    endfor

    " completion
    let l:completed = get(a:todo, 'completed')
    if l:completed
        let l:completed = '[x]'
        call writefile([], l:dir . '/_complete')
    else
        let l:completed = '[ ]'
        call nextup#remove_file(l:dir . '/_complete')
    endif

    " craft special formatted message
    let to_join = [l:curr_id, l:completed]
    if get(a:todo, 'date') != 'untagged'
        call add(to_join, get(a:todo, 'date'))
    else
        call add(to_join, '')
    endif
    call add(to_join, l:todo)

    " save our todo
    call writefile([join(to_join, '__NEXTUP__')], l:file)

    " add our file to the index
    call nextup#load_index()
    call nextup#add_to_index(g:nextup_todos_list, l:file)
    return l:curr_id
endfunction

function! nextup#remove_todo(id)
    call nextup#load_index()
    let l:test = a:id . '/index.nextup'
    let l:ind = index(map(copy(g:nextup_todos_list), 'v:val =~ l:test'), 1)
    if l:ind != -1
        " remove todo from tags
        let l:todo_file = g:nextup_todos_list[l:ind]
        if filereadable(l:todo_file)
            let l:parsed = nextup#parse_input(readfile(l:todo_file)[0])
            let l:tags = get(l:parsed, 'tags', [])
            for l:t in l:tags
                let l:tag_file = g:nextup_directory . '/tags/' . l:t
                if filereadable(l:tag_file)
                    let l:tag_index = readfile(l:tag_file)
                    call nextup#remove_from_index(l:tag_index, l:todo_file)
                    if len(l:tag_index) != 0
                        call writefile(l:tag_index, l:tag_file)
                    else
                        call nextup#remove_file(l:tag_file)
                    endif
                endif
            endfor
        endif

        " remove the todo
        let l:to_remove = fnamemodify(resolve(g:nextup_todos_list[l:ind]), ':p:h')
        call nextup#remove_from_index(g:nextup_todos_list, l:todo_file)
        call nextup#remove_file(l:to_remove)
        return v:true
    endif
    return v:false
endfunction

function! nextup#edit_todo(id)
    call nextup#load_index()
    let l:test = a:id . '/index.nextup'
    let l:ind = index(map(copy(g:nextup_todos_list), 'v:val =~ l:test'), 1)
    if l:ind < 0
        echo 'error: could not find todo with id "' . a:id . '"'
        return v:false
    endif
    let l:text = split(get(readfile(g:nextup_todos_list[l:ind]), 0), '__NEXTUP__')[-1]
    let l:newText = nextup#trim(input('new note: ', l:text))
    if empty(l:newText)
        return v:false
    endif
    if nextup#remove_todo(a:id) == v:true
        call nextup#create_todo(nextup#parse_input(l:newText), a:id)
        return v:true
    endif
    return v:false
endfunction

function! nextup#complete_todo(id, ...)
    call nextup#load_index()
    let l:test = a:id . '/index.nextup'
    let l:ind = index(map(copy(g:nextup_todos_list), 'v:val =~ l:test'), 1)
    if l:ind < 0
        echo 'error: could not find todo with id "' . a:id . '"'
        return v:false
    endif
    let l:text = split(get(readfile(g:nextup_todos_list[l:ind]), 0), '__NEXTUP__')[-1]
    if nextup#remove_todo(a:id) == v:true
        let l:todo = nextup#parse_input(l:text)
        " no undo flag
        if a:0 == 0
            let l:todo.completed = 1
        endif
        call nextup#create_todo(l:todo, a:id)
        return v:true
    endif
    return v:false
endfunction

function! nextup#archive_completed()
    let archive_list = split(globpath(resolve(g:nextup_directory . '/nextup'), '**/_complete'), "\n")
    call uniq(sort(archive_list, 'nextup#index_comparator'))
    if len(archive_list) == 0
        return
    endif

    if has('win32')
        let cmd = 'move'
    else
        let cmd = 'mv'
    endif

    " Make sure archive directory exists
    let archive_dir = g:nextup_directory . '/archived'
    call mkdir(archive_dir, 'p')
    let archive_dir = shellescape(resolve(archive_dir))

    " go through each directory with the _complete file
    " and move it into the archive dir
    for archive in archive_list
        let dir = shellescape(resolve(fnamemodify(archive, ':p:h')))
        call system(cmd . ' ' . dir . ' ' . archive_dir)
    endfor
endfunction

function! nextup#archive_todo(id)
    call nextup#load_index()
    let archive_dir = resolve(g:nextup_directory . '/archived')
    call mkdir(archive_dir, 'p')
    let archive_dir = shellescape(archive_dir)
    let l:test = a:id . '/index.nextup'
    let l:ind = index(map(copy(g:nextup_todos_list), 'v:val =~ l:test'), 1)
    if l:ind < 0
        echo 'error: could not find todo with id "' . a:id . '"'
        return v:false
    endif
    let l:dir = shellescape(resolve(fnamemodify(g:nextup_todos_list[l:ind], ':p:h')))
    if has('win32')
        call system('move ' . l:dir .' ' . archive_dir)
    else
        call system('mv ' .l:dir .' ' . archive_dir)
    endif
    call nextup#remove_from_index(g:nextup_todos_list, g:nextup_todos_list[l:ind])
    return v:true
endfunction

function! nextup#unarchive_todo(id)
    let found = split(globpath(g:nextup_directory . '/archived', '**/'. a:id .'/*.nextup'), "\n")
    if len(found) == 0
        return v:false
    endif

    " read the date it is supposed to be under
    let date = split(readfile(found[0])[0], '__NEXTUP__')[-2]
    if empty(date)
        let date = 'untagged'
    endif
    call nextup#load_index()
    call mkdir(g:nextup_directory . '/nextup/'. date, 'p')

    " get the path to the directory
    let dir = shellescape(resolve(fnamemodify(found[0], ':p:h')))
    if has('win32')
        let cmd = 'move '
    else
        let cmd = 'mv '
    endif
    call system(cmd . dir . ' ' . shellescape(resolve(g:nextup_directory . '/nextup/' . date)))
    call nextup#add_to_index(g:nextup_todos_list, resolve(g:nextup_directory . '/nextup/' . date . '/' . a:id . '/index.nextup'))
    return v:true
endfunction

function! nextup#archive_clean()
    let to_delete = split(globpath(g:nextup_directory . '/archived', '*'), "\n")
    for d in to_delete
        call nextup#remove_file(d)
    endfor
    echo 'Archive cleaned.'
endfunction
" -----------------------------------------------------------------------------
" Listing Next-Ups ------------------------------------------------------------
" -----------------------------------------------------------------------------

function! nextup#get_new_command()
    if !exists('g:nextup_list_split') || g:nextup_list_split != 'vertical'
        return 'new '
    endif

    return 'vnew '
endfunction

function! nextup#list_todos(split, ...)
    let buf = bufnr('NEXTUP')
    " buffer does not exist
    if buf == -1
        let cmd = nextup#get_new_command()
        if !a:split
            let cmd = 'edit '
        endif
        execute cmd . 'NEXTUP'
        setlocal buftype=nofile bufhidden=wipe noswapfile noundofile undolevels=-1
    endif

    if a:0 > 0
        call nextup#load_todos_buffer(a:1)
    else
        call nextup#load_todos_buffer()
    endif
endfunction

function! nextup#load_todos_buffer(...)
    call nextup#load_index()
    let buf = bufnr('NEXTUP')
    if buf == -1
        return
    endif
    let win = bufwinnr(buf)
    if win == -1
        let cmd = nextup#get_new_command()
        execute cmd . 'NEXTUP'
        let win = bufwinnr(buf)
    endif

    if winnr() != win
        execute win . 'wincmd w'
    endif

    " clear the buffer
    execute 'silent! normal! ggdG'
    call append(line('$'), 'Next Up:')

    " default to listing the whole index
    let file_index = g:nextup_todos_list

    " but if we provided tags or days, use the tags or files folders instead
    if a:0 > 0
        " dirty conditional for only listing archived
        if a:0 == 1 && a:1 ==? 'archived'
            let file_index = split(globpath(resolve(g:nextup_directory . '/archived'), '**/index.nextup'), "\n")
        else
            let split_words = split(a:1, ' ')
            let total = nextup#filter_and_load_tags(split_words) + nextup#filter_and_load_days(split_words)
            if len(total) > 0
                let file_index = total
                call uniq(sort(file_index, 'nextup#index_comparator'))
            endif
        endif
    endif

    " today vs tomorrow in YYYY-MM-DD to be compared
    " with the date in the note. If date matches today or tomorrow, use
    " 'today' or 'tomorrow' instead of the YYYY-MM-DD
    let today = nextup#get_date()
    let tomorrow = nextup#get_tomorrow()

    " load the actual todos
    for file in file_index
        if filereadable(file)
            let contents = split(get(readfile(file), 0), '__NEXTUP__')
            let id = contents[0]
            let checkbox = contents[1]
            let date = contents[2]
            let note = contents[3]
            if date == today
                let date = 'today'
            elseif date == tomorrow
                let date = 'tomorrow'
            endif

            let formatted = printf('%-7s%-8s%-16s%s', id, checkbox, date, note)
            call append(line('$'), formatted)
        endif
    endfor
    execute 'normal! 1Gdd'
endfunction

function! nextup#filter_and_load_tags(list)
    let tags = filter(copy(a:list), 'len(v:val) > 1 && v:val[0] == "+"')
    if len(tags) == 0
        return []
    endif
    let file_index = []
    for t in tags
        let tag_file = g:nextup_directory . '/tags/' . t[1:]
        if filereadable(tag_file)
            call extend(file_index, readfile(tag_file))
        endif
    endfor
    return file_index
endfunction

function! nextup#filter_and_load_days(list)
    let days = copy(a:list)
    let today = filter(copy(a:list), 'v:val ==? "today"')
    let tomorrow = filter(copy(a:list), 'v:val ==? "tomorrow"')
    call filter(map(days, 'nextup#get_next_day(v:val)'), '!empty(v:val)')
    call map(today, 'nextup#get_date()')
    call map(tomorrow, 'nextup#get_tomorrow()')
    let days = days + today + tomorrow
    let total = []
    for d in days
        let day_directory = resolve(g:nextup_directory . '/nextup/' . d)
        if isdirectory(day_directory)
            call extend(total, split(globpath(day_directory, '**/index.nextup'), "\n"))
        endif
    endfor
    return total
endfunction
