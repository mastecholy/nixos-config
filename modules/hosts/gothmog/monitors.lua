-- Same layout as the previous niri setup: 1440p main on the left, portrait
-- 1080p on the right (its top sits 600px above the main monitor's top)

-- Main: 2560x1440 @ 170 Hz
hl.monitor({
    output = "DP-1",
    mode = "2560x1440@170",
    position = "0x600",
    scale = 1
})
-- Side: 1920x1080 @ 60 Hz rotated 90° (portrait, 1080 wide)
hl.monitor({
    output = "DP-2",
    mode = "1920x1080@60",
    position = "2560x0",
    scale = 1,
    transform = 1
})
-- Fallback for anything else plugged in
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1
})

for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1", persistent = i == 1 })
end
for i = 6, 9 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", persistent = i == 6 })
end
