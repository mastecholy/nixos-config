local KEYS = require("lib.keys")
local helpers = require("lib.helpers")

local apps = {
  [helpers.register(KEYS.MODIFIER.SUPER, KEYS.SPECIAL.ENTER)]         =
  {
    cmd = "kitty",
    desc = "Open Kitty Terminal"
  },
  [helpers.register(KEYS.MODIFIER.SUPER, KEYS.ALPHABET.B)]            =
  {
    cmd = "firefox",
    desc = "Open Firefox Browser"
  },
  [helpers.register(KEYS.MODIFIER.SUPER, KEYS.ALPHABET.C)]            =
  {
    cmd = "kitty nvim",
    desc = "Open Neovim"
  }
}


for keybind, app in pairs(apps) do
  hl.bind(
    keybind,
    hl.dsp.exec_cmd(app.cmd),
    {
      description = app.desc,
    }
  )
end
