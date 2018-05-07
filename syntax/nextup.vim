if exists('b:current_syntax')
    finish
endif

syntax match id '^\d\+' nextgroup=completion skipwhite
syntax match completion '\[\(\s\|x\)\]' nextgroup=friendlyDate skipwhite
syntax match friendlyDate '\(\d\{4}-\d\{2}-\d\{2}\|today\|tomorrow\)'
syntax match tag '+\S\+'

highlight default link id Type
highlight default link friendlyDate Boolean
highlight default link tag Keyword
