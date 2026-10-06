local KEYS = require("lib.keys")
local helpers = require("lib.helpers")

local navigations = {
    -- 1. Move focus (SUPER + h/j/k/l)
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.ALPHABET.H),
        action = hl.dsp.focus({ direction = "left" }),
        desc = "Move focus left"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.ALPHABET.J),
        action = hl.dsp.focus({ direction = "down" }),
        desc = "Move focus down"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.ALPHABET.K),
        action = hl.dsp.focus({ direction = "up" }),
        desc = "Move focus up"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.ALPHABET.L),
        action = hl.dsp.focus({ direction = "right" }),
        desc = "Move focus right"
    },

    -- 2. Move window (SUPER + SHIFT + h/j/k/l)
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.SHIFT, KEYS.ALPHABET.H),
        action = hl.dsp.window.move({ direction = "left" }),
        desc = "Move window left"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.SHIFT, KEYS.ALPHABET.J),
        action = hl.dsp.window.move({ direction = "down" }),
        desc = "Move window down"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.SHIFT, KEYS.ALPHABET.K),
        action = hl.dsp.window.move({ direction = "up" }),
        desc = "Move window up"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.SHIFT, KEYS.ALPHABET.L),
        action = hl.dsp.window.move({ direction = "right" }),
        desc = "Move window right"
    },

    -- 3. Move window to other monitor (SUPER + CTRL + h/j/k/l)
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.CTRL, KEYS.ALPHABET.H),
        action = hl.dsp.window.move({ monitor = "left" }),
        desc = "Move window to monitor left"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.CTRL, KEYS.ALPHABET.J),
        action = hl.dsp.window.move({ monitor = "down" }),
        desc = "Move window to monitor down"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.CTRL, KEYS.ALPHABET.K),
        action = hl.dsp.window.move({ monitor = "up" }),
        desc = "Move window to monitor up"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.CTRL, KEYS.ALPHABET.L),
        action = hl.dsp.window.move({ monitor = "right" }),
        desc = "Move window to monitor right"
    },

    -- 4. Resize window (SUPER + CTRL + SHIFT + h/j/k/l)
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.CTRL, KEYS.MODIFIER.SHIFT, KEYS.ALPHABET.H),
        action = hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
        desc = "Resize window left"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.CTRL, KEYS.MODIFIER.SHIFT, KEYS.ALPHABET.J),
        action = hl.dsp.window.resize({ x = 0, y = 30, relative = true }),
        desc = "Resize window down"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.CTRL, KEYS.MODIFIER.SHIFT, KEYS.ALPHABET.K),
        action = hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
        desc = "Resize window up"
    },
    {
        key = helpers.register(KEYS.MODIFIER.SUPER, KEYS.MODIFIER.CTRL, KEYS.MODIFIER.SHIFT, KEYS.ALPHABET.L),
        action = hl.dsp.window.resize({ x = 30, y = 0, relative = true }),
        desc = "Resize window right"
    },
}

for _, nav in ipairs(navigations) do
    hl.bind(
        nav.key,
        nav.action,
        {
            description = nav.desc,
        }
    )
end
