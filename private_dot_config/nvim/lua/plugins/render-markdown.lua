---@type LazySpec
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- MDX専用パーサーではなく、Markdown部分をMarkdownとして描画する。
    ft = { "markdown", "markdown.mdx" },
    init = function()
      -- Neovim標準では .mdx のfiletypeが未設定のため追加する。
      vim.filetype.add {
        extension = {
          mdx = "markdown.mdx",
        },
      }
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.icons",
    },
    opts = {
      -- Markdownを開いたときはレンダリングを有効にする。
      enabled = true,
      -- 内蔵LSP経由でチェックボックス・Calloutの補完を使えるようにする。
      -- AstroNvimのblink.cmpからも自動的に利用できる。
      completions = {
        lsp = { enabled = true },
      },
    },
    config = function(_, opts)
      -- markdown.mdxバッファではMarkdownのTree-sitterパーサーを使う。
      vim.treesitter.language.register("markdown", "markdown.mdx")
      require("render-markdown").setup(opts)
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.treesitter = opts.treesitter or {}
      opts.treesitter.ensure_installed = opts.treesitter.ensure_installed or {}

      for _, parser in ipairs { "markdown", "markdown_inline" } do
        if not vim.tbl_contains(opts.treesitter.ensure_installed, parser) then
          table.insert(opts.treesitter.ensure_installed, parser)
        end
      end

      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>um"] = {
        "<Cmd>RenderMarkdown toggle<CR>",
        desc = "Toggle Markdown rendering",
      }
    end,
  },
}
