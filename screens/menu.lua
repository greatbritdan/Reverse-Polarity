local menu = {}

local menutimer, menustate, menugui, settingsgui, levelgui, rebidning, reset, resettype

function changeSetting(name, val)
    local save = true
    if name == "scale" then
        local scale = SCALE
        if val == 1 then
            SCALE = math.min(SCALE+1, 4)
        else
            SCALE = math.max(1, SCALE-1)
        end
        if SCALE ~= scale then
            secretgui.elements["scale"].text = tostring(SCALE)
            love.window.setMode(ENV.width*SCALE, ENV.height*SCALE, {vsync=VSYNC, resizable=ENV.resizable, minwidth=ENV.minwidth*SCALE, minheight=ENV.minheight*SCALE})
        else
            save = false
        end
    elseif name == "vsync" then
        VSYNC = val
        love.window.setMode(ENV.width*SCALE, ENV.height*SCALE, {vsync=VSYNC, resizable=ENV.resizable, minwidth=ENV.minwidth*SCALE, minheight=ENV.minheight*SCALE})
    elseif name == "music" then
        MUSICVOL = val
        updatesounds()
        playsound(Musictest)
    elseif name == "sfx" then
        SFXVOL = val
        updatesounds()
        playsound(Breaksound)
    elseif name == "notutor" then
        NOTUTORIAL = val
    elseif name == "skipcut" then
        SKIPCUTSCENE = val
    elseif name == "control" and rebidning then
        CONTROLS[rebidning] = val
        settingsgui.elements[rebidning].text = getControlText(rebidning)
        rebidning = false
    elseif name == "debug" then
        DEBUG = val
    elseif name == "invince" then
        INVINCE = val
    end
    if save then
        savesavefile("savefile")
    end
end

local levelnames = {"the factory", "the pipeline", "the basement"}

function getControlName(name)
    if name == "rotateleft" then name = "rotate left" end
    if name == "rotateright" then name = "rotate right" end
    return name
end
function getControlText(name)
    return getControlName(name) .. ":  " .. CONTROLS[name]
end

function loadLevel(i)
    Levelselected = true
    if not i then
        i = LEVELREACHED
        Levelselected = false
    end
    Leveltoload = i
    Screen:changeState("game", {"fade", 0.5, {0,0,0}}, {"fade", 0.5, {0,0,0}})
end

function creategui()
    local buttonimg, buttonquads = Gui_generateButtonImg("images/base/guibuttons.png",5)
    local buttonstyle = { margin=5, buttonimg=buttonimg, buttonquads=buttonquads, buttoncornersize=5, textcolor={gray={1,1,1}} }

    local half = round(HEIGHT/2)
    local x = round((WIDTH*0.5)-48)
    if WIDTH >= 256 then
        x = round((WIDTH*0.25)-48)
    end
    menugui = GuiGroup:new()
    menugui:add("start",       Gui:new({type="button", x=x, y=half-44, w=96, h=24}, {text="start",        func=function() loadLevel() end}, buttonstyle))
    menugui:add("levelselect", Gui:new({type="button", x=x, y=half-12, w=96, h=24}, {text="level select", func=function() menustate = "levelselect"; reset = nil end}, buttonstyle))
    menugui:add("settings",    Gui:new({type="button", x=x, y=half+20, w=96, h=24}, {text="settings",     func=function() menustate = "settings";    reset = nil end}, buttonstyle))
    menugui:add("secrets",     Gui:new({type="button", x=x, y=half+52, w=96, h=24}, {text="secrets",      func=function() menustate = "secrets";     reset = nil end, secret=true}, buttonstyle)) -- :eyes:

    local vsync = 1
    if VSYNC then vsync = 2 end
    local notutor = 1
    if NOTUTORIAL then notutor = 2 end
    local skipcut = 1
    if SKIPCUTSCENE then skipcut = 2 end

    local x = round(WIDTH/2)
    if WIDTH >= 312 then
        x = round(WIDTH/4)
    end
    settingsgui = GuiGroup:new()
    settingsgui:add("vsync",   Gui:new({type="toggle", x=x-36, y=48,  w=72, h=24}, {text="", state=vsync, values={false,true}, image=GUIICONIMGS, quad={false,1}, basequad=GUIICONQUADS, func=function(s) changeSetting("vsync", s:getValue()) end}, buttonstyle))
    settingsgui:add("music",   Gui:new({type="scroll", x=x-64, y=88,  w=128, h=24}, {dir="hor", fill=12, limit={0,100,0,5}, value=MUSICVOL, displayvalue=true, unpressfunc=function(s) changeSetting("music", s:getValue()) end}, buttonstyle))
    settingsgui:add("sfx",     Gui:new({type="scroll", x=x-64, y=128, w=128, h=24}, {dir="hor", fill=12, limit={0,100,0,5}, value=SFXVOL,   displayvalue=true, unpressfunc=function(s) changeSetting("sfx", s:getValue()) end}, buttonstyle))
    settingsgui:add("notutor", Gui:new({type="toggle", x=x-36, y=168, w=72, h=24}, {text="", state=notutor, values={false,true}, image=GUIICONIMGS, quad={false,1}, basequad=GUIICONQUADS, func=function(s) changeSetting("notutor", s:getValue()) end}, buttonstyle))
    if HEIGHT >= 256 then
        settingsgui:add("skipcut", Gui:new({type="toggle", x=x-36, y=208, w=72, h=24}, {text="", state=skipcut, values={false,true}, image=GUIICONIMGS, quad={false,1}, basequad=GUIICONQUADS, func=function(s) changeSetting("skipcut", s:getValue()) end}, buttonstyle))
    end
    if WIDTH >= 312 then
        settingsgui:add("left",        Gui:new({type="button", x=round((WIDTH*0.75)-64), y=68, w=128, h=24},  {text=getControlText("left"), func=function(s) rebidning = "left" end}, buttonstyle))
        settingsgui:add("right",       Gui:new({type="button", x=round((WIDTH*0.75)-64), y=98, w=128, h=24},  {text=getControlText("right"), func=function(s) rebidning = "right" end}, buttonstyle))
        settingsgui:add("jump",        Gui:new({type="button", x=round((WIDTH*0.75)-64), y=128, w=128, h=24}, {text=getControlText("jump"), func=function(s) rebidning = "jump" end}, buttonstyle))
        settingsgui:add("rotateleft",  Gui:new({type="button", x=round((WIDTH*0.75)-64), y=158, w=128, h=24}, {text=getControlText("rotateleft"), func=function(s) rebidning = "rotateleft" end}, buttonstyle))
        settingsgui:add("rotateright", Gui:new({type="button", x=round((WIDTH*0.75)-64), y=188, w=128, h=24}, {text=getControlText("rotateright"), func=function(s) rebidning = "rotateright" end}, buttonstyle))
    end

    levelgui = GuiGroup:new()
    local levelcount = 3
    if WIDTH >= 324 then
        local x = round( (WIDTH/2) - (((96*levelcount)+(4*(levelcount-1)))/2) )
        for i = 1, levelcount do
            levelgui:add("level"..i, Gui:new({type="button", x=x, y=round((HEIGHT/2)-12), w=96, h=24}, {text=levelnames[i], func=function() loadLevel(i) end}, buttonstyle))
            x = x + 96+4
        end
    else
        local y = round( (HEIGHT/2) - (((24*levelcount)+(4*(levelcount-1)))/2) )
        for i = 1, levelcount do
            levelgui:add("level"..i, Gui:new({type="button", x=round((WIDTH/2)-96), y=y, w=96, h=24}, {text=levelnames[i], func=function() loadLevel(i) end}, buttonstyle))
            y = y + 24+4
        end
    end
    levelgui:add("levele", Gui:new({type="button", x=(WIDTH/2)-48, y=round(HEIGHT-40), w=96, h=24}, {text="the credits", func=function() loadLevel("e") end}, buttonstyle))

    local debug = 1
    if DEBUG then debug = 2 end
    local invince = 1
    if INVINCE then invince = 2 end
    local x = round(WIDTH/2)
    secretgui = GuiGroup:new()
    secretgui:add("debug",     Gui:new({type="toggle", x=x-36, y=48,  w=72,  h=24}, {text="", state=debug, values={false,true}, image=GUIICONIMGS, quad={false,1}, basequad=GUIICONQUADS, func=function(s) changeSetting("debug", s:getValue()) end}, buttonstyle))
    secretgui:add("invince",   Gui:new({type="toggle", x=x-36, y=88,  w=72,  h=24}, {text="", state=invince, values={false,true}, image=GUIICONIMGS, quad={false,1}, basequad=GUIICONQUADS, func=function(s) changeSetting("invince", s:getValue()) end}, buttonstyle))

    secretgui:add("scale<", Gui:new({type="button", x=x-64, y=128, w=24, h=24}, {image=GUIICONIMGS, quad=GUIICONQUADS[8], func=function(s) changeSetting("scale", -1) end}, buttonstyle))
    secretgui:add("scale>", Gui:new({type="button", x=x+40, y=128, w=24, h=24}, {image=GUIICONIMGS, quad=GUIICONQUADS[9], func=function(s) changeSetting("scale", 1) end}, buttonstyle))
    secretgui:add("scale",  Gui:new({type="button", x=x-36, y=128, w=72, h=24}, {text=tostring(SCALE)}, buttonstyle))
end

--

function menu.load(last)
    love.graphics.setBackgroundColor(35,35,35)
    menutimer, menustate = 0, "main"
    if Levelselected then
        menustate = "levelselect"
    end
    creategui()

    Gamemusic:stop()
    Menumusic:stop()
end

function menu.resize()
    creategui()
end

function menu.update(dt)
    if not Menumusic:isPlaying() then
        Menumusic:play()
    end

    menutimer = menutimer + dt*2
    if (menustate == "main" or menustate == "settings") and reset then
        reset = reset + dt
        if reset >= 3 then
            local scale, vsync, width, height = SCALE, VSYNC, WIDTH, HEIGHT
            if menustate == "main" then
                DEBUG, INVINCE = false, false
                LEVELREACHED = 1
                TOPRANKS = {{time=false, deaths=false}, {time=false, deaths=false}, {time=false, deaths=false}}
                --SCALE = ENV.scale
                --secretgui.elements["scale"].text = tostring(SCALE)
            else
                VSYNC = ENV.vsync
                MUSICVOL, SFXVOL = 50, 50
                NOTUTORIAL, SKIPCUTSCENE = false, false
                CONTROLS = { left="a", right="d", jump="space", rotateleft="q", rotateright="e", pause="escape", reset="backspace" }
                --WIDTH, HEIGHT = ENV.width, ENV.height
                updatesounds()
            end
            if scale ~= SCALE or vsync ~= VSYNC or width ~= WIDTH or height ~= HEIGHT then
                love.window.setMode(WIDTH*SCALE, HEIGHT*SCALE, {vsync=VSYNC, resizable=ENV.resizable, minwidth=ENV.minwidth*SCALE, minheight=ENV.minheight*SCALE})
            end

            reset = false
            savesavefile("savefile")
            playsound(Deathsound)
            creategui()
        end
    end
    if menustate == "settings" then
        settingsgui:update(dt)
    elseif menustate == "secrets" then
        secretgui:update(dt)
    end
end

function menu.draw()
    love.graphics.setColor(1,1,1)
    for x = 1, math.ceil(WIDTH/384) do
        for y = 1, math.ceil(WIDTH/256) do
            love.graphics.draw(Backimg, (x-1)*384, (y-1)*256)
        end
    end
    if menustate == "main" and WIDTH >= 256 then
        love.graphics.draw(Titlelevelimg, Titlelevelquads[1], (WIDTH*0.75)-64, (HEIGHT/2)-256)
        love.graphics.draw(Titlelevelimg, Titlelevelquads[2], (WIDTH*0.75)-64, HEIGHT/2)
        local oy = (HEIGHT/2)-10
        love.graphics.draw(Playerextraimg, Playerextraquads[4], (WIDTH*0.75), oy+10+(math.sin(menutimer*1.5)*48), 0, -1, 1, 10, 11)
    end
    love.graphics.draw(Darkimg, 0, 0, 0, WIDTH, 1)
    love.graphics.draw(Darkimg, 0, HEIGHT, 0, WIDTH, -1)

    if menustate == "main" then
        menugui:draw()
        local x = (WIDTH*0.5)-54
        if WIDTH >= 256 then
            x = (WIDTH*0.25)-54
        end
        love.graphics.draw(Titleimg, x, 12)

        local fit = "center"
        if WIDTH >= 256 then
            fit = "left"
        end
        love.graphics.printf("made by aidan\nfor the 2023 love game jam!", 4, round(HEIGHT-8-(getFontHeight()*3)+getFontSpacing()), round(WIDTH-8), fit)
        if reset then
            love.graphics.setColor(1,0.6,0.6)
        end
        love.graphics.printf("hold backspace for 3 sec to reset scores", 4, round(HEIGHT-4-getFontHeight()+getFontSpacing()), round(WIDTH-8), fit)
    else
        love.graphics.setColor(0.2,0.2,0.2,0.6)
        love.graphics.rectangle("fill", 8, 8, WIDTH-16, HEIGHT-16)

        love.graphics.setColor(1,1,1)
        if menustate == "settings" then
            love.graphics.printf("settings - press esc to return to menu", 12, 12, WIDTH-24, "center")

            local w = round(WIDTH)
            if WIDTH >= 312 then
                w = round(WIDTH/2)
            end
            love.graphics.printf("vsync",          0, 38,  w, "center")
            love.graphics.printf("music volume",   0, 78,  w, "center")
            love.graphics.printf("sfx volume",     0, 118, w, "center")
            love.graphics.printf("no tutorial",    0, 158, w, "center")
            if HEIGHT >= 256 then
                love.graphics.printf("skip cutscenes", 0, 198, w, "center")
            end
            if WIDTH >= 312 then
                love.graphics.printf("controls", round(WIDTH/2), 58, round(WIDTH/2), "center")

                if rebidning then
                    love.graphics.setColor(1,1,0)
                    love.graphics.printf("press the key you want to use for " .. getControlName(rebidning), 12, 24, WIDTH-24, "center")
                    love.graphics.setColor(1,1,1)
                end
            end
            if reset then
                love.graphics.setColor(1,0.6,0.6)
            end
            love.graphics.printf("to reset hold backspace for 3 seconds", 12, HEIGHT-12-getFontHeight()+getFontSpacing(), WIDTH-24, "center")

            settingsgui:draw()
        elseif menustate == "levelselect" then
            love.graphics.printf("level select - press esc to return to menu", 12, 12, WIDTH-24, "center")

            local textw, time, deaths
            local levelcount = 3
            if WIDTH >= 324 then
                local x = round( (WIDTH/2) - (((96*levelcount)+(4*(levelcount-1)))/2) )
                for i = 1, levelcount do
                    time, deaths = "--.--", TOPRANKS[i].deaths or "-"
                    if TOPRANKS[i].time then
                        time = string.format("%.2f", TOPRANKS[i].time)
                    end
                    love.graphics.setColor(1,1,1)
                    if not TOPRANKS[i].time then
                        love.graphics.setColor(0.5,0.5,0.5)
                    end

                    textw = getFontWidth(time)
                    love.graphics.draw(Staticonsimg, Staticonsquads[1], x+48-(textw/2)-6, (HEIGHT/2)+16)
                    love.graphics.printf(time, x+6, round((HEIGHT/2)+17), 96, "center")

                    textw = getFontWidth(deaths)
                    love.graphics.draw(Staticonsimg, Staticonsquads[2], x+48-(textw/2)-6, (HEIGHT/2)+28)
                    love.graphics.printf(deaths, x+6, round((HEIGHT/2)+29), 96, "center")

                    x = x + 96+4
                end
            else
                local y = round( (HEIGHT/2) - (((24*levelcount)+(4*(levelcount-1)))/2) )
                for i = 1, levelcount do
                    time, deaths = "--.--", TOPRANKS[i].deaths or "-"
                    if TOPRANKS[i].time then
                        time = string.format("%.2f", TOPRANKS[i].time)
                    end
                    love.graphics.setColor(1,1,1)
                    if not TOPRANKS[i].time then
                        love.graphics.setColor(0.5,0.5,0.5)
                    end

                    textw = getFontWidth(time)
                    love.graphics.draw(Staticonsimg, Staticonsquads[1], round((WIDTH/2)+48-(textw/2))-6, y+2)
                    love.graphics.printf(time, round(WIDTH/2)+6, y+3, 96, "center")

                    textw = getFontWidth(deaths)
                    love.graphics.draw(Staticonsimg, Staticonsquads[2], round((WIDTH/2)+48-(textw/2))-6, y+14)
                    love.graphics.printf(deaths, round(WIDTH/2)+6, y+15, 96, "center")

                    y = y + 24+4
                end
            end

            levelgui:draw()
        elseif menustate == "secrets" then
            love.graphics.printf("secrets - press esc to return to menu\nfor all the super cool features!", 12, 12, WIDTH-24, "center")

            love.graphics.printf("debug", 0, 38, round(WIDTH), "center")
            love.graphics.printf("invincibility", 0, 78, round(WIDTH), "center")
            love.graphics.printf("scale (unstable)", 0, 118, round(WIDTH), "center")

            love.graphics.printf("debug controls\nf10 - hitboxes (ingame)\nf11 - refresh level (ingame)\nf12 - show info (fps)\nclick screen - move player (ingame)", 0, 177, round(WIDTH), "center")

            secretgui:draw()
        end
    end
end

function menu.mousepressed(x, y, button)
    if menustate == "main" then
        menugui:click(x, y, button)
    elseif menustate == "settings" then
        settingsgui:click(x, y, button)
    elseif menustate == "levelselect" then
        levelgui:click(x, y, button)
    elseif menustate == "secrets" then
        secretgui:click(x, y, button)
    end
end
function menu.mousereleased(x, y, button)
    -- always unclick
    menugui:unclick(x, y, button)
    settingsgui:unclick(x, y, button)
    levelgui:unclick(x, y, button)
    secretgui:unclick(x, y, button)
end

function menu.keypressed(key)
    if rebidning then
        if key == CONTROLS["pause"] then
            rebidning = false
        else
            changeSetting("control", key)
        end
        return
    end
    if key == CONTROLS["reset"] and (menustate == "main" or menustate == "settings") then
        rebidning = false
        reset = 0
    end
    if key == CONTROLS["pause"] and menustate ~= "main" then
        menustate = "main"
    end
end
function menu.keyreleased(key)
    reset = nil
end

function menu.wheelmoved(x, y)
    if menustate == "settings" then
        settingsgui:scrolled(y)
    elseif menustate == "secrets" then
        secretgui:scrolled(y)
    end
end

return menu