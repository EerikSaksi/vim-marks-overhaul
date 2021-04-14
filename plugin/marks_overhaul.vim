" Vim Marks overhaul
" Maintainer:   Eerik Saksi 
" Version:      0.2

" Get custom configs
let g:vim_marks_overhaul#marks_file_path = get(g:, "vim_marks_overhaul#marks_file_path", $HOME . "/.cache/vim-marks-overhaul")

" Make vim marks directory if it doesn't exist
if empty(glob(g:vim_marks_overhaul#marks_file_path))
  call mkdir(g:vim_marks_overhaul#marks_file_path)
endif

"save last used git repo
if !filereadable(g:vim_marks_overhaul#marks_file_path . '/last_used')
  silent exec '!touch ' . g:vim_marks_overhaul#marks_file_path . '/last_used'
endif

" InGitRepository() tells us if the directory we are currently working in
" is a git repository. It makes use of the 'git rev-parse --is-inside-work-tree'
" command. This command outputs true to the shell if so, and a STDERR message 
" otherwise.
"
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
  else
    let repo_name = readfile(g:vim_marks_overhaul#marks_file_path . '/last_used')[0]
  endif
  let marksDir = g:vim_marks_overhaul#marks_file_path . '/' . repo_name
  if !isdirectory(marksDir)
    " init empty marks file
    let i = 0
    let lines = []
    while i < 26
      let lines = add(lines, '')
      let i += 1
    endwhile
    silent exec '!mkdir ' . marksDir
  endif
  return marksDir
endfunction

function! s:CustomJumpMark()
  "if nerdtree open close it so you don't open file in small nerd tree window
  if exists("g:NERDTree") && g:NERDTree.IsOpen()
    :NERDTreeToggle 
  endif

  let in = getchar()
  "undo
  if nr2char(in) == "\e"
    return
  endif

  if 97 <= in && in <= 122 
    "first we find the jump file which was requested
    let requestedFile = s:GetMarksFilePath() . '/' . nr2char(in)
    if (filereadable(requestedFile))
      "if exists return the file inside this requested directory
      let in = getchar()
      if nr2char(in) == "\e"
        return
      endif
      let lines = readfile(requestedFile)
      silent exec 'find ' . lines[in - 97][1:]
    endif
  endif
endfunction


function! s:CustomMark()
  "get current directory
  let pwd = getcwd()
  let in = getchar()
  if 97 <= in && in <= 122 
    let path = s:GetMarksFilePath() . "/" . nr2char(in)
    if filereadable(path)
      echo "Directory already marked with " . nr2char(in)
      return
    endif
    silent exec '!touch ' . path
    let i = 0

    let lines = []
    while i < 26
      let lines = add(lines, '')
      let i += 1
    endwhile

    let files = ""
    redir => files
      :ls
    redir end
    echo files

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
