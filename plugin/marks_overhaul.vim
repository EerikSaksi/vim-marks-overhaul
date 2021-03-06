" bujo.vim - A minimalist todo list manager
" Maintainer:   Eerik Saksi <eeriksak.si/>
" Version:      0.1

" Get custom configs
let g:vim_marks_overhaul#marks_file_path = get(g:, "vim_marks_overhaul#marks_file_path", $HOME . "/.cache/vim-marks-overhaul")



" Make bujo directory if it doesn't exist"
if empty(glob(g:vim_marks_overhaul#marks_file_path))
  call mkdir(g:vim_marks_overhaul#marks_file_path)
endif

if !filereadable(g:vim_marks_overhaul#marks_file_path . '/last_used')
  silent exec '!touch ' . g:vim_marks_overhaul#marks_file_path . '/last_used'
endif

" InGitRepository() tells us if the directory we are currently working in
" is a git repository. It makes use of the 'git rev-parse --is-inside-work-tree'
" command. This command outputs true to the shell if so, and a STDERR message 
" otherwise.
"
" Used to 
function s:InGitRepository()
  :silent let bool = system("git rev-parse --is-inside-work-tree")

  " The git function will return true with some leading characters
  " if we are in a repository. So, we split off those characters
  " and just check the first word.
  if split(bool, '\v\n')[0] == 'true'
    return 1
  endif
endfunction

" GetToplevelFolder() gives us a clean name of the git repository that we are
" currently working in
function s:GetToplevelFolder()
  let absolute_path = system("git rev-parse --show-toplevel")
  let repo_name = split(absolute_path, "/")
  let repo_name_clean = split(repo_name[-1], '\v\n')[0]

  "if not using globals write the last used mark file
  call writefile([repo_name_clean], g:vim_marks_overhaul#marks_file_path . '/last_used')
  return repo_name_clean
endfunction


" GetMarksFilePath() returns which file path we will be using. If we are in a
" git repository, we return the directory for that specific git repo.
" Otherwise, we return the general file path. 
"
" If we are passed an argument, it means that the user wants to open the
" general marks file, so we also return the general file path in that case
function s:GetMarksFilePath()
  "use git repo marks
  if s:InGitRepository()
    let repo_name = s:GetToplevelFolder()
    let marksFile = g:vim_marks_overhaul#marks_file_path . "/" . repo_name 
  else 
    let gitRepo = readfile(g:vim_marks_overhaul#marks_file_path . '/last_used')[0]
    let marksFile = g:vim_marks_overhaul#marks_file_path . '/' . gitRepo
  endif
  if !filereadable(marksFile)
    " init empty marks file
    let i = 0
    let lines = []
    while i < 79
      let lines = add(lines, '')
      let i += 1
    endwhile
    silent exec '!touch ' . marksFile
    call writefile(lines, marksFile)
  endif
  return marksFile
endfunction

function! s:CustomJumpMark()
  "if nerdtree open close so you don't open file in small nerd tree window
  if exists("g:NERDTree") && g:NERDTree.IsOpen()
    :NERDTreeToggle 
  endif
  let lines = readfile(s:GetMarksFilePath())

  "get the filename of the current file
  let fileName = ""
  redir => fileName 
    silent! echo expand('%:p')
  redir end

  let in = getchar()
  "undo
  if nr2char(in) == "\e"
    return
  endif
  if 65 < in || in < 122 && lines[in - 65] != ''
    "by default CocCommand opens the directory and not inside the folder, so
    "we ls the files inside and jump to the first one
    let files = ""
    redir => files
      silent! exe '!ls ' . lines[in - 65]
    redir end
    let firstFile = split(files, "\n")[-1]
    execute 'CocCommand explorer --position floating --root-strategies reveal --reveal ' . lines[in - 65] . '/' . firstFile
  endif
endfunction




function! s:CustomMark()
  "in stores the mark we want to use
  let filePath = getcwd()

  let lines = readfile(s:GetMarksFilePath())
  let in = getchar()
  if 65 < in || in < 122 
    let lines = readfile(s:GetMarksFilePath())
    if strlen(lines[in - 65]) != 0
      echo lines[in - 65] . ' already occupies this mark. Override? (y/n)' 
      let option = getchar()
      if nr2char(option) == 'y'
        let lines[in - 65] = filePath
        call writefile(lines, s:GetMarksFilePath())
      endif
      return
    endif

    "find if this file is already refered to
    let i = 0
    while i < 57
      if lines[i] == filePath 
        echo nr2char(i + 65) . " already refers to this file. Override? (y/n)"
        let option = getchar()
        if nr2char(option) == 'y'
          let lines[i] = ""
        else
          return
        endif
      endif
      let i+=1
    endwhile
    let lines[in - 65] = filePath
    call writefile(lines, s:GetMarksFilePath())
  endif
endfunction

if !exists(":OverhaulJump")
  command -nargs=? OverhaulJump :call s:CustomJumpMark()
endif
if !exists(":OverhaulMark")
  command -nargs=? OverhaulMark :call s:CustomMark()
endif
