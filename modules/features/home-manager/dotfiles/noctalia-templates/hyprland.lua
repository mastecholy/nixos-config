-- Rendered by Noctalia to ~/.config/hypr/noctalia.lua on every palette change
-- (see modules/features/home-manager/modules/desktop/theme.nix)

local primary = "rgb({{colors.primary.default.hex_stripped}})"
local secondary = "rgb({{colors.secondary.default.hex_stripped}})"
local outline = "rgb({{colors.outline_variant.default.hex_stripped}})"
local surface = "rgb({{colors.surface.default.hex_stripped}})"
local on_surface = "rgb({{colors.on_surface.default.hex_stripped}})"
local on_secondary = "rgb({{colors.on_secondary.default.hex_stripped}})"
local error = "rgb({{colors.error.default.hex_stripped}})"
local on_error = "rgb({{colors.on_error.default.hex_stripped}})"

local function apply_theme()
  hl.config({
    general = {
      col = {
        active_border = primary,
        inactive_border = outline,
      },
    },
    decoration = {
      shadow = {
        color = "rgba({{colors.shadow.default.hex_stripped}}99)",
      },
    },
    group = {
      col = {
        border_active = secondary,
        border_inactive = outline,
        border_locked_active = error,
        border_locked_inactive = outline,
      },
      groupbar = {
        col = {
          active = secondary,
          inactive = surface,
          locked_active = error,
          locked_inactive = surface,
        },
        text_color = on_secondary,
        text_color_inactive = on_surface,
        text_color_locked_active = on_error,
        text_color_locked_inactive = on_surface,
      },
    },
    misc = {
      background_color = surface,
    },
  })
end

return { apply_theme = apply_theme }
