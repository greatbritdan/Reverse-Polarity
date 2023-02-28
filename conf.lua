function love.conf(t)
    local env = require("env")

    t.window.width = env.width*env.scale
    t.window.height = env.height*env.scale
    t.window.vsync = env.vsync
    t.window.resizable = env.resizable
    if env.minwidth then
        t.window.minwidth = env.minwidth*env.scale
    end
    if env.minheight then
        t.window.minheight = env.minheight*env.scale
    end
    t.window.fullscreen = env.fullscreen

    t.version = "11.3"
    t.identity = "reversepolarity"
    t.window.title = "Reverse Polarity"
    t.window.icon = "images/icon.png"
end