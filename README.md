<h1 align="center">Next-Up</h1>
<p align="center">Simple todolist for Vim </p>


Nextup.vim is heavily inspired by [Todolist][todolist].
You should definitely check out Todolist to see if it suits all of your needs.
Nextup.vim was only created because I wanted a pure vimscript solution for my todos.


<!-- vim-markdown-toc GFM -->

* [Installation](#installation)
* [Configuration](#configuration)
* [Creating Todos](#creating-todos)
  * [Example](#example)
* [Tagging Todos](#tagging-todos)
  * [Example](#example-1)
* [Listing Todos](#listing-todos)
  * [Example](#example-2)
  * [Example](#example-3)
* [Editing Todos](#editing-todos)
* [Removing a todo](#removing-a-todo)
* [Completing a todo](#completing-a-todo)
* [Archiving](#archiving)
  * [Example](#example-4)
* [Clean](#clean)

<!-- vim-markdown-toc -->

## Installation

Install nextup.vim using your favorite plugin manager. Mine is [Vim-Plug][vimplug].

```
Plug 'davinche/nextup.vim'
```

## Configuration

You can configure where Next-up saves your todos by defining `g:nextup_directory`.

```
let g:nextup_directory = expand('~/Dropbox/my_notes')
```

## Creating Todos

Use the command `NextUp` to create a new todo.

```
NextUp this is a thing I need to do
```

You can specify the due date by tagging entering `due _______` at the end of your todo.

### Example

```
:NextUp This is a thing that must be done. Due friday.
```

When you to list your todos, something like this would show:

```
1      [ ]     2018-05-15      This is a thing that must be done. Due friday.
```

## Tagging Todos

When creating a new todo, any words beginning with a `+` is considered a tag.

### Example

```
:NextUp Need to do my science +homework. Due Friday.
```
The above would be tagged under `homework`.

## Listing Todos

You can see all of your todos by running

```
:NextUpList
```

You can also convenient add a keyboard mapping to show your todos by adding a mapping to `<Plug>(NextUpList)`

### Example

```
nmap <leader>l <Plug>(NextUpList)
```

To filter your todos by tags, simply add the tags you want to filter for in your `:NextUpList` command.

### Example

```
:NextUpList +homework
```

## Editing Todos

You can edit a todo using the `:NextUpEdit` command. To edit a todo, you must first know the `id` of the todo.
Once you know the `id`, you can run:

```
:NextUpEdit 1
```

where `1` is the id of the todo in this example.

## Removing a todo

Similar to editing, you can remove a todo by running the `:NextUpRemove <id>` command.

## Completing a todo

To mark a todo as complete, simply run the `:NextUpComplete <id>` command.
You do the reverse (remove the completion marker), you can run `:NextUpUncomplete <id>`.



## Archiving

You can remove a todo from view by archiving it. You can archive a todo by running the `:NextUpArchive` command

### Example

```
:NextUpArchive 1
```
To archive **all** completed todos, run the `:NextUpArchiveCompleted` command.


## Clean

Cleaning involves deleting all archived todos. To delete all the archived todos, run `:NextUpClean`.

[todolist]: http://todolist.site/
[vimplug]: junegunn/vim-plug
