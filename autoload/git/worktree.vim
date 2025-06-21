" autoload/git/worktree.vim
" Git worktree utility functions for ddu-source-git-worktree

function! git#worktree#location_list() abort
  let l:result = []
  let l:current_dir = getcwd()
  
  try
    " git worktree list コマンドを実行
    let l:output = system('git worktree list')
    if v:shell_error != 0
      return []
    endif
    
    " 出力を行ごとに分割
    let l:lines = split(l:output, '\n')
    let l:line_number = 1
    
    for l:line in l:lines
      if empty(l:line)
        continue
      endif
      
      " git worktree list の出力形式をパース
      " 形式: /path/to/worktree commit_hash [branch_name]
      let l:parts = split(l:line, '\s\+')
      if len(l:parts) >= 3
        let l:path = l:parts[0]
        let l:commit = l:parts[1]
        let l:branch = substitute(join(l:parts[2:]), '^\[\(.*\)\]$', '\1', '')
        
        " 現在のディレクトリかどうかをチェック
        let l:is_current = (fnamemodify(l:path, ':p') ==# fnamemodify(l:current_dir, ':p'))
        let l:annotation = l:is_current ? 'current' : ''
        
        " 期待される形式に変換: "path:line:branch:annotation"
        let l:entry = l:path . ':' . l:line_number . ':' . l:branch . ':' . l:annotation
        call add(l:result, l:entry)
      endif
      
      let l:line_number += 1
    endfor
    
  catch
    " エラーが発生した場合は空の配列を返す
    return []
  endtry
  
  return l:result
endfunction

function! git#worktree#get_current_worktree() abort
  " 現在のworktreeのパスを取得
  try
    let l:current_dir = getcwd()
    let l:output = system('git worktree list')
    if v:shell_error != 0
      return ''
    endif
    
    let l:lines = split(l:output, '\n')
    for l:line in l:lines
      let l:parts = split(l:line, '\s\+')
      if len(l:parts) >= 1
        let l:path = l:parts[0]
        if fnamemodify(l:path, ':p') ==# fnamemodify(l:current_dir, ':p')
          return l:path
        endif
      endif
    endfor
  catch
    return ''
  endtry
  
  return ''
endfunction

function! git#worktree#is_git_repo() abort
  " 現在のディレクトリがGitリポジトリかどうかをチェック
  try
    let l:output = system('git rev-parse --is-inside-work-tree 2>/dev/null')
    return v:shell_error == 0 && trim(l:output) ==# 'true'
  catch
    return 0
  endtry
endfunction

function! git#worktree#del_worktree_at_line(path, lineNr) abort
  " worktree削除機能の実装
  try
    " パスの正規化
    let l:target_path = fnamemodify(a:path, ':p')
    
    " 現在のworktreeかチェック
    let l:current_worktree = git#worktree#get_current_worktree()
    let l:current_path = fnamemodify(l:current_worktree, ':p')
    
    if l:target_path ==# l:current_path
      echohl WarningMsg
      echo "Cannot remove current worktree: " . a:path
      echohl None
      return 0
    endif
    
    " パスの存在チェック
    if !isdirectory(a:path)
      echohl ErrorMsg
      echo "Worktree directory does not exist: " . a:path
      echohl None
      return 0
    endif
    
    " 削除確認
    let l:branch_name = ''
    let l:output = system('git worktree list')
    if v:shell_error == 0
      let l:lines = split(l:output, '\n')
      for l:line in l:lines
        let l:parts = split(l:line, '\s\+')
        if len(l:parts) >= 3 && fnamemodify(l:parts[0], ':p') ==# l:target_path
          let l:branch_name = substitute(join(l:parts[2:]), '^\[\(.*\)\]$', '\1', '')
          break
        endif
      endfor
    endif
    
    let l:confirm_msg = "Remove worktree '" . a:path . "'"
    if !empty(l:branch_name)
      let l:confirm_msg .= " (branch: " . l:branch_name . ")"
    endif
    let l:confirm_msg .= "? (y/N): "
    
    let l:choice = input(l:confirm_msg)
    if l:choice !=# 'y' && l:choice !=# 'Y'
      echo "\nCancelled."
      return 0
    endif
    
    " git worktree remove コマンド実行
    let l:remove_output = system('git worktree remove ' . shellescape(a:path))
    if v:shell_error != 0
      echohl ErrorMsg
      echo "\nFailed to remove worktree: " . l:remove_output
      echohl None
      return 0
    endif
    
    echo "\nRemoved worktree: " . a:path
    if !empty(l:branch_name)
      echo "Branch: " . l:branch_name
    endif
    return 1
    
  catch
    echohl ErrorMsg
    echo "Error removing worktree: " . a:path
    echohl None
    return 0
  endtry
endfunction