function updatesounds()
    Clicksound:setVolume(SFXVOL/100)
    Walksound:setVolume(SFXVOL/100)
    Jumpsound:setVolume(SFXVOL/100)
    Breaksound:setVolume(SFXVOL/100)
    Rotatesound:setVolume(SFXVOL/100)
    Deathsound:setVolume(SFXVOL/100)
    Checkpointsound:setVolume(SFXVOL/100)
    Cannonsound:setVolume(SFXVOL/100)
    Hitsound:setVolume(SFXVOL/100)

    Gamemusic:setVolume(0)
    Menumusic:setVolume(MUSICVOL/100)
    Musictest:setVolume(MUSICVOL/100)
end

function playsound(sound)
    sound:stop()
    sound:play()
end

function love.load()
    love.graphics.setDefaultFilter("nearest")

    ENV = require("env")
    WIDTH, HEIGHT, SCALE, VSYNC = ENV.width, ENV.height, ENV.scale, ENV.vsync

    MUSICVOL, SFXVOL = 50, 50
    NOTUTORIAL, SKIPCUTSCENE = false, false
    CONTROLS = { left="a", right="d", jump="space", rotateleft="q", rotateright="e", pause="escape", reset="backspace" }
    TOPRANKS = {{time=false, deaths=false}, {time=false, deaths=false}, {time=false, deaths=false}}

    BACKLIGHT = 0.4 -- leftover from when you could set it

    DEBUG, INVINCE = false, false
    LEVELREACHED, Leveltoload = 1, false

    -- LOAD LIBS --
    Class = require("libs/middleclass")
    JSON = require("libs/JSON")

    require("libs/custom/A_Utils")
    require("libs/custom/A_Map")
    require("libs/custom/A_Camera")
    require("libs/custom/A_Physics")
    require("libs/custom/A_UI")
    require("libs/custom/A_Screen")

    -- LOAD OBJECTS --
    require("objects/player")
    require("objects/ground")
    require("objects/magnet")
    require("objects/spikes")
    require("objects/cannon")
    require("objects/misc")
    require("objects/effects")

    local scale, vsync = SCALE, VSYNC
    loadsavefile("savefile")
    if SCALE ~= scale or VSYNC ~= vsync then
        love.window.setMode(WIDTH*SCALE, HEIGHT*SCALE, {vsync=VSYNC, resizable=ENV.resizable, minwidth=ENV.minwidth*SCALE, minheight=ENV.minheight*SCALE})
    end

    -- LOAD FONTS --
    setFont(newFont("pixel", ENV.imagespath .. "/font.png", "abcdefghijklmnopqrstuvwxyz 0123456789.,:;_-!?\"'/\\^*()[]%<>+=#|`{}~@", 1, 1))

    -- LOAD GRAPHICS --
    Titleimg = loadsprites("images/title")
    Titlelevelimg, Titlelevelquads = loadsprites("images/titlelevel", 2, 1)
    Backimg = loadsprites("images/backgrounds/factory/1")
    Darkimg = loadsprites("images/darkness")

    Staticonsimg, Staticonsquads = loadsprites("images/staticons", 3, 1)

    Playerimg, Playerquads = loadsprites("images/player", 4, 13, nil, {"hor","ver","up","left","down","right","body","o_up","o_left","o_down","o_right","b_hor","b_ver"})
    Playerextraimg, Playerextraquads = loadsprites("images/playerextra", 4, 1)

    Magnetimg, Magnetquads = loadsprites("images/magnet", 12, 9)
    Magneticonimg, Magneticonquads = loadsprites("images/magneticon", 2, 1)

    Cannonimg, Cannonquads = loadsprites("images/cannon", 4, 1, {"left","up","right","down"})
    Cannonballimg, Cannonballquads = loadsprites("images/cannonball", 3, 1)

    Spikesimg = loadsprites("images/spikes")
    Platformimg = loadsprites("images/platform")

    Effectimg, Effectquads = loadsprites("images/effects", 5, 4, {"dust1","dust2","spark","brick1","brick2"})

    -- LOAD AUDIO --
    Clicksound = love.audio.newSource("sounds/click.ogg", "static")
    Walksound = love.audio.newSource("sounds/walk.ogg", "static")
    Jumpsound = love.audio.newSource("sounds/jump.ogg", "static")
    Rotatesound = love.audio.newSource("sounds/rotate.ogg", "static")

    Deathsound = love.audio.newSource("sounds/death.ogg", "static")
    Checkpointsound = love.audio.newSource("sounds/checkpoint.ogg", "static")

    Hitsound = love.audio.newSource("sounds/hit.ogg", "static")
    Breaksound = love.audio.newSource("sounds/break.ogg", "static")
    Cannonsound = love.audio.newSource("sounds/cannon.ogg", "static")

    Gamemusic = love.audio.newSource("sounds/menumusic.ogg", "stream")
    Menumusic = love.audio.newSource("sounds/menumusic.ogg", "stream")
    Musictest = love.audio.newSource("sounds/break.ogg", "static")

    updatesounds()

    -- LOAD SCREEN --
    Screen:changeState("intro", nil, {"fade",0.5})
end

function love.update(dt)
    if love.keyboard.isDown("lalt") then
        return
    end
    dt = math.min(dt, 1/60) -- no falling through the world
    gdt = dt
    Screen:update(dt)
end

function love.draw()
    Screen:draw()
    if ENV.showfps or ENV.showdrawcalls or ENV.showcursor or ENV.showwindow then
        love.graphics.push()
        love.graphics.scale(SCALE,SCALE)
        love.graphics.setColor(1,1,1)
        local text = ""
        if ENV.showfps then
            text = text .. string.format("fps: %s\n", love.timer.getFPS())
        end
        if ENV.showdrawcalls then
            local stats = love.graphics.getStats()
            text = text .. string.format("drawcalls: %s\n", stats.drawcalls+1)
        end
        if ENV.showcursor then
            love.graphics.rectangle("fill", getX(), getY(), 1, 1)
            text = text .. string.format("cursor: %s - %s\n", getX(), getY())
        end
        if ENV.showwindow then
            local w, h, tw, th = WIDTH, HEIGHT, WIDTH*SCALE, HEIGHT*SCALE
            text = text .. string.format("window: %s (%s) - %s (%s)\n", w, tw, h, th)
        end
        love.graphics.print(text, 3, 3)
        love.graphics.pop()
    end
end

function love.mousepressed(x, y, button)
    x, y = getXY()
    Screen:mousepressed(x, y, button)
end
function love.mousereleased(x, y, button)
    x, y = getXY()
    Screen:mousereleased(x, y, button)
end
function love.keypressed(key)
    if key == "f12" and DEBUG then
        ENV.showfps, ENV.showdrawcalls, ENV.showcursor, ENV.showwindow = not ENV.showfps, not ENV.showdrawcalls, not ENV.showcursor, not ENV.showwindow
    end
    Screen:keypressed(key)
end
function love.keyreleased(key)
    Screen:keyreleased(key)
end
function love.textinput(text)
    Screen:textinput(text)
end
function love.wheelmoved(x, y)
    Screen:wheelmoved(x, y)
end
function love.mousemoved(x, y, dx, dy)
    Screen:mousemoved(x, y, dx, dy)
end
function love.resize(w, h, noscale)
    WIDTH, HEIGHT = w/SCALE, h/SCALE
    Screen:resize()
end