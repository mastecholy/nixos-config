local KEYS = require("lib.keys")

hl.define_submap("resize", function()
  local keyresize_spec = {
    [KEYS.ARROW.LEFT]  = { x = -10, y = 0, relative = true },
    [KEYS.ARROW.RIGHT] = { x = 10, y = 0, relative = true },
    [KEYS.ARROW.UP]    = { x = 0, y = -10, relative = true },
    [KEYS.ARROW.DOWN]  = { x = 0, y = 10, relative = true },
  }
  for bind, resize_spec in pairs(keyresize_spec) do
    hl.bind(
      bind,
      hl.dsp.window.resize(resize_spec),
      {
        repeating = true
      }
    )
  end

  hl.bind(KEYS.SPECIAL.ESCAPE, hl.dsp.submap("reset"))
  hl.bind(KEYS.SPECIAL.ENTER, hl.dsp.submap("reset"))
end)
