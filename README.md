# vim-marks-overhaul

This overrides and extends on some of vim's mark features.

- All marks are global

  This includes lower case marks. The location of marks in files is not saved, so you will instead jump to where you were editing most recently.

- Different marks for different projects

  If you're not inside a git project, the global marks are used. Otherwise, project specific marks are used automatically.

- Warns when overriding marks

  If you try to assign a mark to a file that is already used, a warning prompt will appear.

- Warns when double referencing file

  If you have already assigned a mark to the current file, a warning will appear, and proceeding erases the old mark.

- Reminders for marks

  If you access a file that has been marked through other means (such as through NERDTree) an echo will execute reminding you of the mark that was assigned to this file.

- Support for NERDTree

  Executing a jump will first close NERDTree (if plugin exists) to avoid opening the buffer in the small left side window.


## Installation

If you use a plugin manager, such as [vim-plug], follow its instructions on how to install plugins from github.

To install the stable version of the plugin, if using [vim-plug], put this in your `vimrc`/`init.vim`:

```
Plug 'eeriksaksi/vim-marks-overhaul'
```

## Use / Mappings

- Override default vim marks

  ```
  nnoremap <silent> ' :OverhaulJump <CR>
  nnoremap <silent> m :OverhaulMark <CR>
  ```

- Use the last git repos mark files when launching instead of globals (if you worked on git project bogosort when last using vim, bogosorts marks will be used even outside of the project until you enter another git project)
  ```
  let g:vim_marks_overhaul#use_globals = 0
  ```

- Change cache directory:
  ```
  let g:vim_marks_overhaul#marks_file_path = $HOME ".cache/vim-marks-overhault"
  ```


# vim-marks-overhaul
This is my first vim plugin so I really don't know what I'm doing, so any constructive criticism or feature suggestions are welcome.
I copied the basic structure from vim-bujo, as it used similar logic (todo list for git repo vs marks file.)

[vim-plug]: https://github.com/junegunn/vim-plug
[:h mods]: https://vimhelp.org/map.txt.html#%3Cmods%3E

## License

Copyright (c) Eerik Saksi. Distributed under the same terms as Vim itself.
See `:help license`.
