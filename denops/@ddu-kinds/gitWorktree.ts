import {
  ActionFlags,
  Actions,
  BaseKind,
  Context,
  DduItem,
  PreviewContext,
  Previewer,
} from "https://deno.land/x/ddu_vim@v3.10.2/types.ts";
import { Denops } from "https://deno.land/x/ddu_vim@v3.10.2/deps.ts";
import { is, maybe } from "https://deno.land/x/unknownutil@v3.15.0/mod.ts";

export type ActionData = {
  path: string;
  lineNr: number;
  info?: string;
};

type Params = Record<never, never>;

const isDduItemAction = is.ObjectOf({ path: is.String, lineNr: is.Number });

export const GitWorktreeAction: Actions<Params> = {
  open: async (args: {
    denops: Denops;
    context: Context;
    actionParams: unknown;
    items: DduItem[];
  }) => {
    const action = args.items[0]["action"] as { path: string; lineNr: number };
    
    try {
      // ディレクトリに変更
      await args.denops.cmd(`cd ${action.path}`);
      
      // ブランチ名を取得してecho
      const branchResult = await args.denops.call("system", "git branch --show-current");
      const branchName = String(branchResult).trim();
      
      if (branchName) {
        await args.denops.cmd(`echo "Switched to branch: ${branchName} (${action.path})"`);
      } else {
        await args.denops.cmd(`echo "Changed directory to: ${action.path}"`);
      }
    } catch (error) {
      await args.denops.cmd(`echoerr "Failed to change directory: ${error}"`);
    }
    
    return Promise.resolve(ActionFlags.None);
  },
  clear: async (args: {
    denops: Denops;
    context: Context;
    actionParams: unknown;
    items: DduItem[];
  }) => {
    // 分割代入
    const { denops, items } = args;

    try {
      for (const item of items) {
        // unknownutilのmaybe関数便利
        const action = maybe(item?.action, isDduItemAction);

        if (!action) {
          return ActionFlags.None;
        }

        await denops.call(
          "git#worktree#del_worktree_at_line",
          action.path,
          action.lineNr,
        );
      }
    } catch {
    }

    console.log("git worktrees cleared");
    return ActionFlags.None;
  },
};

export class Kind extends BaseKind<Params> {
  override actions = GitWorktreeAction;
  defaultAction = "open";
  override getPreviewer(args: {
    denops: Denops;
    item: DduItem;
    actionParams: unknown;
    previewContext: PreviewContext;
  }): Promise<Previewer | undefined> {
    const action = args.item.action as ActionData;
    if (!action) {
      return Promise.resolve(undefined);
    }

    return Promise.resolve({
      kind: "buffer",
      path: action.path,
    });
  }

  override params(): Params {
    return {};
  }
}