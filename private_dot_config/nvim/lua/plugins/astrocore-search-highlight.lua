---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = {
    -- Keep normal / and ? search matches highlighted after moving the cursor.
    -- This only disables AstroNvim's automatic hlsearch toggle; LSP/cursor
    -- reference highlighting is separate and remains untouched.
    on_keys = {
      auto_hlsearch = false,
    },
    options = {
      opt = {
        hlsearch = true,
      },
    },
  },
}
