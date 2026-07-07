return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.win = opts.picker.win or {}
      opts.picker.win.input = opts.picker.win.input or {}
      opts.picker.win.input.keys = opts.picker.win.input.keys or {}
      opts.picker.win.list = opts.picker.win.list or {}
      opts.picker.win.list.keys = opts.picker.win.list.keys or {}

      opts.picker.win.input.keys.HH = { "toggle_hidden", mode = { "i", "n" } }
      opts.picker.win.input.keys.II = { "toggle_ignored", mode = { "i", "n" } }
      opts.picker.win.list.keys.HH = "toggle_hidden"
      opts.picker.win.list.keys.II = "toggle_ignored"

      -- Grep 系 picker の左ペインは、右側 preview と情報が重複するため
      -- path + 行/列番号だけを表示して候補一覧を読みやすくする。
      local function grep_path_only(item, picker)
        return require("snacks.picker.format").filename(item, picker)
      end

      for _, source in ipairs { "grep", "grep_word", "grep_buffers", "git_grep" } do
        opts.picker.sources[source] = vim.tbl_deep_extend("force", opts.picker.sources[source] or {}, {
          format = grep_path_only,
        })
      end
    end,
  },
}
