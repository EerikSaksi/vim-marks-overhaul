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
    silent exec '!mkdir ' . marksDir
    let i = 0
    let lines = []
    while i < 26
      let lines = add(lines, '')
      let i += 1
    endwhile
    call writefile(lines, marksDir . '/vim_marks_overhaul_root_paths')
  endif
  return marksDir
endfunction

function! s:EscapableIn()
  let in = getchar()
  "undo
  if nr2char(in) == "\e"
    return
  endif
  return in
endfunction

function! s:CustomJumpMark()
  "if nerdtree open close it so you don't open file in small nerd tree window
  if exists("g:NERDTree") && g:NERDTree.IsOpen()
    :NERDTreeToggle 
  endif
  let in = s:EscapableIn()
  if 97 <= in && in <= 122 
    "first we find the jump file which was requested
    let rootPathFiles = s:GetMarksFilePath() . '/' . nr2char(in)
    let rootPath = s:GetRootPathsList()[in - 97]

    if (filereadable(rootPathFiles))
      let lines = readfile(rootPathFiles)
      let i = 0
      while i < len(lines) && len(lines[i])
        echo nr2char(i + 97) . ' ' . lines[i]
        let i += 1
      endwhile
      let in = s:EscapableIn()

      silent exec 'find ' .  rootPath . '/' . lines[in - 97]

      "make sure that all files in directory actually saved
      let files = s:GetFileList()
      for dirFile in files
        let notFound = 1
        for savedFile in lines
          if dirFile == savedFile 
            let notFound = 0
            break
          endif
        endfor
        if notFound 
          let lines[i] = dirFile
          let i+=1
        endif
      endfor
      redraw
    endif
  endif
endfunction


function! s:GetFileList()
  let files = []
  redir => files
    :silent echo globpath('.', '*')
  redir end
  let files = split(files, '\n')
  let i = 0
  while i < len(files) 
    if isdirectory(files[i])
      call remove(files, i)
    else
      let files[i] = files[i][2:]
      let i += 1
    endif
  endwhile
  return files
endfunction

function! s:GetRootPathsList()
  return readfile(s:GetMarksFilePath() . '/vim_marks_overhaul_root_paths')
endfunction

function! s:CustomMark()
  "get current directory
  let pwd = getcwd()
  let in = s:EscapableIn()
  if 97 <= in && in <= 122 
    let path = s:GetMarksFilePath() . "/" . nr2char(in)


    let rootpaths = s:GetRootPathsList()
    let i = 0
    while i < 26
      if rootpaths[i] == getcwd()
        echo "Directory already marked with " . nr2char(i + 97)
        return
      endif
      let i += 1
    endwhile
    if filereadable(path)
      echo "Some directory already marked with " . nr2char(in) . ". Override (y/n)?"
      let yesno = getchar()
      if yesno != 121
        return
      endif
      silent exec '!rm ' . path
    endif
    silent exec '!touch ' . path

    let rootpaths[in - 97] = getcwd()

    let files = s:GetFileList()
    while len(files) < 26
      call add(files, '')
    endwhile

    call writefile(rootpaths, s:GetMarksFilePath() . '/vim_marks_overhaul_root_paths')
    call writefile(files, path)
  endif
endfunction

if !exists(":OverhaulJump")
 command -nargs=? OverhaulJump :call s:CustomJumpMark()
endif
if !exists(":OverhaulMark")
  command -nargs=? OverhaulMark :call s:CustomMark()
endif
