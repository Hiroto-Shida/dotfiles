---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>gd"] = { "<Cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
          ["<Leader>gh"] = { "<Cmd>DiffviewFileHistory %<CR>", desc = "Git file history (current file)" },
          ["<Leader>gm"] = {
            function()
              local file = vim.api.nvim_buf_get_name(0)
              if file == "" then return end
              local line = vim.api.nvim_win_get_cursor(0)[1]
              local blame = vim.fn.system({
                "git",
                "blame",
                "-L",
                ("%d,%d"):format(line, line),
                "--porcelain",
                file,
              })
              if vim.v.shell_error ~= 0 then
                vim.notify("Git blame failed", vim.log.levels.WARN)
                return
              end
              local commit = blame:match("^([0-9a-f]+)%s")
              if not commit then
                vim.notify("Commit not found for current line", vim.log.levels.WARN)
                return
              end
              require("snacks").gitbrowse({ what = "commit", commit = commit })
            end,
            desc = "Open Git commit for current line",
          },
          ["<Leader>gq"] = { "<Cmd>DiffviewClose<CR>", desc = "Close Diffview" },
        },
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local astrocore, get_icon = require "astrocore", require("astroui").get_icon
      opts.on_attach = function(bufnr)
        local prefix, maps = "<Leader>g", astrocore.empty_map_table()
        for _, mode in ipairs { "n", "v" } do
          maps[mode][prefix] = { desc = get_icon("Git", 1, true) .. "Git" }
        end

        maps.n[prefix .. "d"] = { "<Cmd>DiffviewOpen<CR>", desc = "Open Diffview" }
        maps.n[prefix .. "h"] = { "<Cmd>DiffviewFileHistory %<CR>", desc = "Git file history (current file)" }
        maps.n[prefix .. "q"] = { "<Cmd>DiffviewClose<CR>", desc = "Close Diffview" }
        maps.n[prefix .. "l"] = { function() require("gitsigns").blame_line() end, desc = "View Git blame" }
        maps.n[prefix .. "L"] =
          { function() require("gitsigns").blame_line { full = true } end, desc = "View full Git blame" }
        maps.n[prefix .. "p"] = { function() require("gitsigns").preview_hunk_inline() end, desc = "Preview Git hunk" }

        maps.n["[G"] = { function() require("gitsigns").nav_hunk "first" end, desc = "First Git hunk" }
        maps.n["]G"] = { function() require("gitsigns").nav_hunk "last" end, desc = "Last Git hunk" }
        maps.n["]g"] = { function() require("gitsigns").nav_hunk "next" end, desc = "Next Git hunk" }
        maps.n["[g"] = { function() require("gitsigns").nav_hunk "prev" end, desc = "Previous Git hunk" }

        astrocore.set_mappings(maps, { buffer = bufnr })
      end
      return opts
    end,
  },
}
