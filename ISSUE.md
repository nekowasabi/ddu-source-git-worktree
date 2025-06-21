# Add Directory Jump Functionality to ddu-source-git-worktree

## 概要

`git worktree list` コマンドの結果からパスを取得し、dduの一覧に表示して、選択した候補にセットされたディレクトリにジャンプする機能を実装する。デフォルトのアクション（`<CR>`）でディレクトリジャンプを実行し、従来の `open` アクションは削除する。

## 現在の状況

### 変更点
1. **`git#worktree#location_list` 関数を実装済み**
   - `autoload/git/worktree.vim` に実装完了
   - プラグインの基本動作が可能になった
2. **アクション仕様の変更**
   - `open` アクション（ファイルを開く）を削除
   - `cd` アクションをデフォルト動作（`<CR>`）に変更

### 現在の実装
- **Source**: `denops/@ddu-sources/gitWorktree.ts`
- **Kind**: `denops/@ddu-kinds/gitWorktree.ts` 
- **Actions**: `clear` (worktreeを削除)
- **基本機能**: `git#worktree#location_list` 関数を実装済み

## 実装計画

### 1. デフォルトアクションの変更 (必須)

#### `open` アクションの削除と `cd` アクションの実装
`denops/@ddu-kinds/gitWorktree.ts` の `GitWorktreeAction`:

```typescript
// openアクションを削除し、cdアクションをデフォルト動作にする
export const GitWorktreeAction: Actions<Params> = {
  // デフォルトアクション（<CR>で実行）
  open: async (args: {
    denops: Denops;
    context: Context;
    actionParams: unknown;
    items: DduItem[];
  }) => {
    const action = args.items[0]["action"] as { path: string; lineNr: number };
    await args.denops.cmd(`cd ${action.path}`);
    await args.denops.cmd(`echo "Changed directory to: ${action.path}"`);
    return Promise.resolve(ActionFlags.None);
  },
  // 既存のclearアクションは保持
  clear: // ... 既存の実装
};
```

**実装内容**:
- 既存の `open` アクションの内容を `cd` 機能に変更
- `<CR>` でデフォルトのディレクトリジャンプを実行
- エラーハンドリングを追加

### 2. UI表示の改善

#### 表示形式の改善
- ブランチ名とパスを分かりやすく表示
- 現在いるworktreeを識別可能にする
- 相対パス表示オプションの追加

例:
```
[main] ~/project/main
[feature/new-ui] ~/project/.git/worktrees/feature-new-ui (current)
[hotfix/bug-123] ~/project/.git/worktrees/hotfix-bug-123
```

## 技術仕様

### git worktree list の出力形式
```
/Users/user/project                           commit_hash [main]
/Users/user/project/.git/worktrees/feature    commit_hash [feature/branch]
```

### 期待される関数の戻り値形式
```vim
[
  "/Users/user/project:1:main:",
  "/Users/user/project/.git/worktrees/feature:1:feature/branch:"
]
```

### デフォルトアクションの動作
1. ユーザーがworktreeを選択
2. `<CR>` でディレクトリジャンプを実行
3. 選択されたworktreeのディレクトリに移動
4. 移動先のパスを表示

## 実装の優先順位

1. **High**: `open` アクションを `cd` 機能に変更（主要機能）
2. **Medium**: UI表示の改善
3. **Low**: 設定オプションの追加

**完了済み**:
- ✅ `git#worktree#location_list` 関数の実装

## 期待される動作

1. `:Ddu git-worktree` でworktreeの一覧を表示
2. 矢印キーでworktreeを選択
3. `<CR>` でディレクトリジャンプ（デフォルト動作）
4. `d` で `clear` アクション（worktree削除）

## 関連ファイル

- `denops/@ddu-sources/gitWorktree.ts` - メインのソース実装
- `denops/@ddu-kinds/gitWorktree.ts` - アクションの実装
- `autoload/git/worktree.vim` - 新規作成が必要
- `README.md` - 使用方法の更新が必要

## 互換性

- ddu.vim v3.10.2 との互換性を維持
- Neovim/Vim の両方で動作する Vim script を使用
- 既存のアクション（`open`, `clear`）との互換性を保持