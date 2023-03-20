" slash
let g:s = '/'
if has("win32") || has("win64")
	let g:s = "\\"
endif

if has("win32") || has("win64")
	let g:vim_marks_overhaul#marks_file_path = get(g:, "vim_marks_overhaul#marks_file_path", $HOME . "\\Documents\\vim-marks-overhaul")
else
	let g:vim_marks_overhaul#marks_file_path = get(g:, "vim_marks_overhaul#marks_file_path", $HOME . "/.cache/vim-marks-overhaul")
endif
let g:buffer_visited_with_marks = 0

" Make directory if it doesn't exist"
if empty(glob(g:vim_marks_overhaul#marks_file_path))
  call mkdir(g:vim_marks_overhaul#marks_file_path)
endif

if !filereadable(g:vim_marks_overhaul#marks_file_path . g:s . "last_used")
  call writefile([""], g:vim_marks_overhaul#marks_file_path . g:s . "last_used")
endif

" InGitRepository() tells us if the directory we are currently working in
" is a git repository. It makes use of the "git rev-parse --is-inside-work-tree"
" command. This command outputs true to the shell if so, and a STDERR message 
" otherwise.
"
" Used to 
function s:InGitRepository()
  :silent let bool = system("git rev-parse --is-inside-work-tree")

  " The git function will return true with some leading characters
  " if we are in a repository. So, we split off those characters
  " and just check the first word.
  if split(bool, '\v\n')[0] == "true"
    return 1
  endif
endfunction

" GetToplevelFolder() gives us a clean name of the git repository that we are
" currently working in
function s:GetToplevelFolder()
  let absolute_path = system("git rev-parse --show-toplevel")
  let repo_name = split(absolute_path, '/')
  let repo_name_clean = split(repo_name[-1], '\v\n')[0]

  "if not using globals write the last used mark file
  call writefile([repo_name_clean], g:vim_marks_overhaul#marks_file_path . g:s . "last_used")
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
    let marksFile = g:vim_marks_overhaul#marks_file_path . g:s . repo_name 
  else 
    let gitRepo = readfile(g:vim_marks_overhaul#marks_file_path . g:s . "last_used")[0]
    let marksFile = g:vim_marks_overhaul#marks_file_path . g:s . gitRepo
  endif
  if !filereadable(marksFile)
    " init empty marks file
    let i = 0
    let lines = []
    while i < 79
      let lines = add(lines, "")
      let i += 1
    endwhile
    silent exec "!touch " . marksFile
    call writefile(lines, marksFile)
  endif
  return marksFile
endfunction

function! s:CustomJumpMark(from_terminal)
  let lines = readfile(s:GetMarksFilePath())
	echo s:GetToplevelFolder()

  "get the filename of the current file
  let fileName = ""
  redir => fileName 
    silent! echo expand("%:p")
  redir end

  let in = getchar()
  "undo
  if nr2char(in) == "\e"
    return
  endif

	let mark = in - 65
	let filePathLen = len(lines[mark])
  if lines[mark] != ""
		for file in MruGetFiles() 
			let relativeFilePath = split(trim(file), trim(lines[mark]))
			if len(relativeFilePath) 
				echo 'file ' .file
				echo 'relativeFilePath' . relativeFilePath[0]
				let numSlashes = len(split(relativeFilePath[0], g:s))

				if numSlashes < 2 
					echo 'numSlashes < 2' . file
					"we visited this mark with the marks plugin
					let g:buffer_visited_with_marks = 1

					if exists("g:vscode")
						call VSCodeExtensionNotify("open-file", lines[mark] . g:s . relativeFilePath[0])
					else
						execute "e " . lines[mark] . g:s .  relativeFilePath[0]
					endif

					return
				endif
			endif
		endfor
  else
    echo "No such mark"
  endif
endfunction


function! s:MarkReminder()
	if !g:buffer_visited_with_marks
		let dir = getcwd()
		let lines = readfile(s:GetMarksFilePath())

    let i = 0
		for line in lines
			if dir == line
				redraw
				echo "Use mark " . nr2char(i + 65)
				return
			endif
			let i += 1
		endfor
	endif
	let g:buffer_visited_with_marks = 0
endfunction
autocmd BufWritePost * :call s:MarkReminder()

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
      if nr2char(option) == "y"
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
        if nr2char(option) == "y"
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
  command -nargs=? OverhaulJump :call s:CustomJumpMark(0)
endif
if !exists(":OverhaulJumpFromTerminal")
  command -nargs=? OverhaulJumpFromTerminal :call s:CustomJumpMark(1)
endif
if !exists(":OverhaulMark")
  command -nargs=? OverhaulMark :call s:CustomMark()
endif
