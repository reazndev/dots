--#########################
--## SCROLL OVERVIEW ######
--#########################

hl.config({
    plugin = {
        scrolloverview = {
            gesture_distance = 300,
            scale = 0.5,
            workspace_gap = 100,
            layout = "vertical",
            wallpaper = 0,
            blur = false,
            input = {
                scroll_event_delay = 200,
                scrolling_mode = 0,
                drag_mode = 0,
                drag_threshold = 10,
            },
            shadow = {
                enabled = true,
                range = 35,
                render_power = 3,
                color = 0xaa000000,
            },
        },
    },
})

hl.plugin.scrolloverview.gesture({
    fingers = 3,
    direction = "vertical",
})

hl.define_submap("scrolloverview", function()
    hl.bind("left", hl.plugin.scrolloverview.navigate("left"))
    hl.bind("right", hl.plugin.scrolloverview.navigate("right"))
    hl.bind("up", hl.plugin.scrolloverview.navigate("up"))
    hl.bind("down", hl.plugin.scrolloverview.navigate("down"))
    hl.bind("return", hl.plugin.scrolloverview.overview("select"))
    hl.bind("escape", hl.plugin.scrolloverview.overview("off"))
    hl.bind("mouse:272", function()
        hl.plugin.scrolloverview.overview("select")
        hl.plugin.scrolloverview.window("select")
        hl.plugin.scrolloverview.overview("off")
    end, { mouse = true })
    hl.bind("mouse:274", hl.plugin.scrolloverview.window("close"), { mouse = true })

    for i = 1, 10 do
        local key = i % 10
        hl.bind("ALT + " .. key, hl.dsp.focus({ workspace = i }), { submap_universal = true })
    end
end)
