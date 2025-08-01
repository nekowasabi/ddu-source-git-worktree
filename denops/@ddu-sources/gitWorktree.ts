import {
  BaseSource,
  DduOptions,
  Item,
  SourceOptions,
} from "https://deno.land/x/ddu_vim@v3.10.2/types.ts";
import { Denops } from "https://deno.land/x/ddu_vim@v3.10.2/deps.ts";
import { ensure, is } from "https://deno.land/x/unknownutil@v3.15.0/mod.ts";
import { ActionData } from "../@ddu-kinds/gitWorktree.ts";

type Params = Record<never, never>;

type GitWorktree = {
  path: string;
  line: number;
  word: string;
  annotation?: string;
};

type GitWorktrees = GitWorktree[];

export class Source extends BaseSource<Params> {
  override kind = "gitWorktree";

  override gather(args: {
    denops: Denops;
    options: DduOptions;
    sourceOptions: SourceOptions;
    sourceParams: Params;
    input: string;
  }): ReadableStream<Item<ActionData>[]> {
    return new ReadableStream({
      async start(controller) {
        const tree = async () => {
          const items: Item<ActionData>[] = [];

          try {
            const gitWorktreesData = ensure(
              await args.denops.call("git#worktree#location_list"),
              is.ArrayOf(is.String),
            );
            const gitWorktrees: GitWorktrees = [];
            for (const gitWorktreeData of gitWorktreesData) {
              const d = gitWorktreeData.split(":");
              const b: GitWorktree = {
                path: d[0],
                line: Number(d[1]),
                word: d[2],
                annotation: d[3],
              };
              gitWorktrees.push(b);
            }
            for (const gitWorktree of gitWorktrees) {
              items.push({
                word: gitWorktree.word,
                action: {
                  path: gitWorktree.path,
                  lineNr: gitWorktree.line,
                },
              });
            }
          } catch (e: unknown) {
            console.error(e);
          }

          return items;
        };

        controller.enqueue(
          await tree(),
        );

        controller.close();
      },
    });
  }

  override params(): Params {
    return {};
  }
}
