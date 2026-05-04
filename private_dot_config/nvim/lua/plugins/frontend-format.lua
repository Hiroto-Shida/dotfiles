-- フロントエンド開発向けの保存時フォーマット設定
-- AstroLSP で「保存時に format を呼ぶ」挙動を制御し、
-- none-ls(null-ls) 側で「どの formatter を使うか」を定義する。
--
-- このファイルの方針:
-- 1. JS/TS/HTML/CSS/JSON/Astro/Vue/Svelte などは保存時に整形する
-- 2. 整形には LSP 付属 formatter ではなく prettier を優先して使う
-- 3. prettier はグローバルではなく、各プロジェクトの node_modules/.bin/prettier のみ使う
-- 4. package.json や Prettier 設定ファイルがあるプロジェクトでだけ prettier を有効にする
--
-- 前提:
-- - 各プロジェクトで prettier を devDependencies に入れておくこと
-- - Astro を整形する場合は必要に応じて prettier-plugin-astro も入れること

---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    opts = {
      formatting = {
        format_on_save = {
          -- 保存時フォーマットを有効化する。
          -- AstroNvim ではここが false だと none-ls 側に formatter があっても自動実行されない。
          enabled = true,
        },
        -- prettier 実行に少し時間がかかるプロジェクト向けに余裕を持たせる。
        timeout_ms = 2000,
        filter = function(client)
          -- フロントエンド系 filetype では formatter を null-ls のみに絞る。
          -- これで tsserver/vtsls/html/cssls/jsonls などの LSP formatter と競合させず、
          -- 保存時整形の責務を prettier に寄せる。
          local frontend_filetypes = {
            javascript = true,
            javascriptreact = true,
            typescript = true,
            typescriptreact = true,
            json = true,
            jsonc = true,
            html = true,
            css = true,
            scss = true,
            less = true,
            yaml = true,
            markdown = true,
            astro = true,
            vue = true,
            svelte = true,
          }

          if frontend_filetypes[vim.bo.filetype] then return client.name == "null-ls" end
          -- それ以外の filetype は AstroNvim / 他 LSP の通常挙動に任せる。
          return true
        end,
      },
    },
  },
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local null_ls = require "null-ls"

      opts.sources = require("astrocore").list_insert_unique(opts.sources or {}, {
        null_ls.builtins.formatting.prettier.with {
          -- グローバル prettier にはフォールバックせず、
          -- プロジェクトローカルの node_modules/.bin/prettier だけを使う。
          -- 「保存時にそのプロジェクトの prettier 設定で整形したい」という意図のため。
          only_local = "node_modules/.bin",
          condition = function(utils)
            -- Prettier を使う前提があるプロジェクトでだけ source を有効化する。
            -- 何も設定がないディレクトリで無駄に prettier をぶら下げないための条件。
            return utils.root_has_file "package.json"
              or utils.root_has_file ".prettierrc"
              or utils.root_has_file ".prettierrc.json"
              or utils.root_has_file ".prettierrc.js"
              or utils.root_has_file ".prettierrc.cjs"
              or utils.root_has_file "prettier.config.js"
              or utils.root_has_file "prettier.config.cjs"
              or utils.root_has_file ".prettierrc.toml"
          end,
          extra_filetypes = {
            -- built-in の既定対象に加えて、フロントエンドでよく使う filetype を明示する。
            "astro",
            "svelte",
            "vue",
          },
        },
      })
    end,
  },
}
