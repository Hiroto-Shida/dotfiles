---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = {
    mappings = {
      n = {
        ["<Leader>yr"] = {
          function()
            local path = vim.fn.expand "%:."
            if path == "" then return end
            vim.fn.setreg("+", path)
            vim.notify(("Copied relative path: %s"):format(path))
          end,
          desc = "Yank relative path",
        },
      },
    },
  },
}
