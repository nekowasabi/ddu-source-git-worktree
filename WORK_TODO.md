# 作業手順 - ddu-source-git-worktree ディレクトリジャンプ機能実装

## Phase 1: 基本機能の実装（完了）

### Step 1: git#worktree#location_list 関数の実装 ✅
- [x] `autoload/git/worktree.vim` ファイルを作成
- [x] `git worktree list` コマンドを実行する関数を実装
- [x] 出力をパースして期待される形式に変換
  - 入力: `/path/to/worktree commit_hash [branch_name]`
  - 出力: `["path:1:branch_name:", ...]`
- [x] 現在のworktreeを特定する機能を追加
- [x] エラーハンドリングを実装

### Step 2: 基本動作の確認 ✅
- [x] `:Ddu git-worktree` でworktreeの一覧が表示されることを確認
- [x] 基本機能が正常に動作することを確認

## Phase 2: デフォルトアクションの変更（必須）

### Step 3: open アクションをディレクトリジャンプに変更
- [ ] `denops/@ddu-kinds/gitWorktree.ts` の `open` アクションを変更
- [ ] ファイルを開く機能を削除し、ディレクトリジャンプ機能を実装
- [ ] 選択されたworktreeのディレクトリに移動する機能を実装
- [ ] 移動完了のメッセージ表示を追加
- [ ] エラーハンドリングを実装（存在しないディレクトリなど）

### Step 4: アクションのテスト
- [ ] `<CR>` でディレクトリ移動が正常に動作することを確認
- [ ] 複数のworktreeで動作確認
- [ ] エラーケースのテスト（権限不足、存在しないパスなど）

## Phase 3: UI改善とユーザビリティ向上

### Step 5: 表示形式の改善
- [ ] ブランチ名とパスを分かりやすく表示
- [ ] 現在いるworktreeを識別可能にする
  - [ ] `(current)` マーカーの追加
  - [ ] 色付けやハイライト（可能であれば）
- [ ] 相対パス表示オプションの検討

### Step 6: キーマッピングの設定
- [ ] デフォルトのキーマッピングを設定
  - [ ] `<CR>` → `open` アクション（ディレクトリジャンプ）
  - [ ] `d` → `clear` アクション
- [ ] カスタマイズ可能なキーマッピングの実装

## Phase 4: ドキュメント整備とテスト

### Step 7: ドキュメントの更新
- [ ] `README.md` の更新
  - [ ] 新機能の説明を追加
  - [ ] 使用方法の説明を追加
  - [ ] キーマッピングの説明を追加
- [ ] コード内のコメント追加
- [ ] 設定例の追加

### Step 8: テストとデバッグ
- [ ] 様々な環境でのテスト
  - [ ] macOS での動作確認
  - [ ] Linux での動作確認（可能であれば）
  - [ ] Windows での動作確認（可能であれば）
- [ ] エッジケースのテスト
  - [ ] worktreeが存在しない場合
  - [ ] Git リポジトリ外での実行
  - [ ] 権限エラーの処理
- [ ] パフォーマンステスト

## Phase 5: 最終調整と完成

### Step 9: コードレビューと最適化
- [ ] コードの最適化
- [ ] パフォーマンスの改善
- [ ] セキュリティの確認
- [ ] コーディングスタイルの統一

### Step 10: リリース準備
- [ ] バージョン番号の更新
- [ ] CHANGELOG の作成
- [ ] 最終動作確認
- [ ] リリースノートの作成

## 技術的な実装詳細

### autoload/git/worktree.vim の実装例
```vim
function! git#worktree#location_list() abort
  let l:result = []
  let l:current_dir = getcwd()
  
  try
    let l:output = system('git worktree list')
    if v:shell_error != 0
      return []
    endif
    
    let l:lines = split(l:output, '\n')
    for l:line in l:lines
      " パースロジックを実装
      " 形式: path:1:branch_name:annotation
    endfor
    
  catch
    return []
  endtry
  
  return l:result
endfunction
```

### open アクション（ディレクトリジャンプ）の実装例
```typescript
open: async (args: {
  denops: Denops;
  context: Context;
  actionParams: unknown;
  items: DduItem[];
}) => {
  const action = args.items[0]["action"] as { path: string; lineNr: number };
  try {
    await args.denops.cmd(`cd ${action.path}`);
    await args.denops.cmd(`echo "Changed directory to: ${action.path}"`);
  } catch (error) {
    await args.denops.cmd(`echoerr "Failed to change directory: ${error}"`);
  }
  return Promise.resolve(ActionFlags.None);
},
```

## 注意事項

1. **互換性**: ddu.vim v3.10.2 との互換性を保持
2. **エラーハンドリング**: 全ての操作で適切なエラー処理を実装
3. **テスト**: 各機能を段階的にテストしながら進める
4. **ドキュメント**: 実装と並行してドキュメントを更新

## 期待される最終成果物

- ✅ 動作する `git#worktree#location_list` 関数
- ディレクトリジャンプ機能を持つ `open` アクション（デフォルト動作）
- 改善されたUI表示
- 完全なドキュメント
- テスト済みの安定した実装