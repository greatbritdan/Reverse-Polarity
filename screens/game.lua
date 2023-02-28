local game = {}

MAP = Map:new()
CAMERA = false
HITBOXES = false

local update, draw, loadobj

function getPlayerByID(id)
    if MAP.objects and MAP.objects["player"] and MAP.objects["player"][id] then
        return MAP.objects["player"][id]
    end
end
function getTextByID(id)
    for i, v in pairs(MAP.objects["text"]) do
        if v.id == id then
            return v
        end
    end
end

function reverseMagnet(dir)
    local list = {up="down", down="up", left="right", right="left"}
    return list[dir]
end
function shiftLeftMagnet(dir)
    local list = {up="left", down="right", left="down", right="up"}
    return list[dir]
end
function shiftRightMagnet(dir)
    local list = {up="right", down="left", left="up", right="down"}
    return list[dir]
end
function triggerAnim(fid)
    local splitted = fid:split("|")
    local target, id, action, arg = splitted[1], splitted[2], splitted[3], nil
    if #splitted > 3 then
        arg = splitted[4]
    end

    if target == "text" then
        if NOTUTORIAL and string.sub(id, 1, 5) == "intro" then
            return
        end
        if MAP.objects["text"] then
            local v = getTextByID(id)
            if arg then
                v[action](v, arg)
            else
                v[action](v)
            end
        end
    elseif target == "player" then
        if MAP.objects["player"] then
            local v = getPlayerByID(tonumber(id))
            if action == "enablerotation" then
                v.rotationenabled = true
            elseif action == "ending" then
                v:win()
            end
        end
    end
end

function createpausegui()
    local buttonimg, buttonquads = Gui_generateButtonImg("images/base/guibuttons.png",5)
    local buttonstyle = { margin=5, buttonimg=buttonimg, buttonquads=buttonquads, buttoncornersize=5, textcolor={gray={1,1,1}} }

    pausegui = GuiGroup:new()
    pausegui:add("resume", Gui:new({type="button", x=round((WIDTH/2)-48), y=round((HEIGHT/2)-32), w=96, h=24}, {text="resume",         func=function() paused = false; if music then music:play() end end}, buttonstyle))
    pausegui:add("menu",   Gui:new({type="button", x=round((WIDTH/2)-48), y=round((HEIGHT/2)+8),  w=96, h=24}, {text="return to menu", func=function() Screen:changeState("menu", {"fade", 0.5, {0,0,0}}, {"fade", 0.5, {0,0,0}}) end}, buttonstyle))
end

--

local movementenabled, rotationenabled, music
function game.load(last)
    love.graphics.setBackgroundColor(35,35,35)

    CHECKPOINTS = {}
    TEXTS = {}

    RANKS = {visible=true, enabled=false, time=0, deaths=0}

    WON = false

    MAP:loadMap("level"..Leveltoload, loadobj)
    CAMERA = MAP.camera
    MAP.level = Leveltoload
    
    local p = getPlayerByID(1)
    if p then
        MAP:cameraFocus(p, true)
        movementenabled, rotationenabled = p.movementenabled, p.rotationenabled
        p.movementenabled, p.rotationenabled = false, false
        if Leveltoload == "e" then
            p.gravity, p.vy, p.maxspeedy = 32, 32, 32
            p.falling = true
            RANKS.visible = false
            CAMERA:setStatic(true, false)
        end
    end

    music = false
    if Leveltoload == "e" then
        music = Menumusic
    end
    Menumusic:stop()

    paused = false
    createpausegui()
end

function game.ready()
    local p = getPlayerByID(1)
    if p then
        p.movementenabled, p.rotationenabled = movementenabled, rotationenabled
    end
end

function game.resize()
    CAMERA:setView(0, 0, WIDTH, HEIGHT)
    createpausegui()
end

function neweffect(t, x, y)
    if not MAP.objects["effects"] then
        MAP.objects["effects"] = {}
    end
    table.insert(MAP.objects["effects"], EFFECT:new(t, x, y))
end

function game.update(dt)
    if paused then
        return
    end

    if music and (not MAP.objects["player"][1].won) and (not music:isPlaying()) then
        music:stop()
        music:play()
    end

    if RANKS.enabled then
        RANKS.time = RANKS.time + dt
    end

    -- texts fun
    local delete
    for i, v in pairs(TEXTS) do
        v.y = v.y - 16*dt
        v.timer = v.timer + dt
        if v.timer >= 1 then
            if not delete then delete = {} end
            table.insert(delete, i)
        end
    end
    if delete then
        table.sort(delete, function(a,b) return a>b end)
        for _, i in pairs(delete) do
            table.remove(TEXTS, i)
        end
    end

    update("magnet", dt)
    update("player", dt)
    update("cannon", dt)
    update("cannonball", dt)
    update("ground", dt)
    update("trigger", dt)
    update("text", dt)

    update("effects", dt)

    physicsUpdate(MAP, dt)

    MAP:update(dt)
    
    local p = getPlayerByID(1)
    if p then
        MAP:cameraFocus(p, false, dt)

        -- checkpoints
        if not p.dead then
            for x, y in pairs(CHECKPOINTS) do
                if p.x+(p.w/2) >= x+8 and x > p.startx then
                    p.startx, p.starty = x+2, y
                    playsound(Checkpointsound)
                    table.insert(TEXTS, {x=x-120, y=y-4, text="checkpoint!", timer=0})
                end
            end
        end
    end
end

function game.draw()
    CAMERA:set()

    love.graphics.setColor(1,1,1)
    MAP:drawImages("back")

    love.graphics.setColor(BACKLIGHT,BACKLIGHT,BACKLIGHT)
    MAP:drawTiles("back")

    love.graphics.setColor(1,1,1)
    draw("spikes")
    draw("magnet")

    MAP:drawTiles("main")
    draw("ground") -- platforms
    draw("text")
    
    love.graphics.setColor(1,1,1)
    draw("cannonball")
    draw("cannon")
    draw("player")

    draw("effects")
    
    for i, v in pairs(TEXTS) do
        love.graphics.setColor(1,1,1,(1-v.timer)*1)
        love.graphics.printf(v.text, v.x, v.y, 256, "center")
    end
    
    if HITBOXES then
        love.graphics.setColor(1,1,1,0.2)
        MAP:drawEntitiesColl()
    end

    love.graphics.setColor(1,1,1,0.8)
    MAP:drawImages("fore")

    CAMERA:unset()

    love.graphics.draw(Darkimg, 0, 0, 0, WIDTH, 1)
    love.graphics.draw(Darkimg, 0, HEIGHT, 0, WIDTH, -1)

    if paused then
        love.graphics.setColor(0.2,0.2,0.2,0.6)
        love.graphics.rectangle("fill", 8, 8, WIDTH-16, HEIGHT-16)

        love.graphics.setColor(1,1,1)

        love.graphics.printf("paused - press esc to resume", 12, 12, WIDTH-24, "center")
        pausegui:draw()
    else
        if not RANKS.visible then
            return
        end
        
        local time = string.format("%.2f", RANKS.time)
        local w = 12+20+getFontWidth(time)+getFontWidth(RANKS.deaths)
        local x = round((WIDTH/2)-(w/2))

        love.graphics.setColor(0,0,0,0.8)
        love.graphics.rectangle("fill", x, 0, w, 14)

        love.graphics.setColor(1,1,1)
        if not RANKS.enabled then
            love.graphics.setColor(0.5,0.5,0.5)
        end

        love.graphics.draw(Staticonsimg, Staticonsquads[1], x+2, 2)
        love.graphics.print(time, x+4+10, 3)
        love.graphics.draw(Staticonsimg, Staticonsquads[2], x+8+10+getFontWidth(time), 2)
        love.graphics.print(RANKS.deaths, x+10+20+getFontWidth(time), 3)
    end
end

function game.keypressed(key)
    for i, v in pairs(MAP.objects["player"]) do
        if key == v:getControls("jump") then
            v:jump()
        elseif key == v:getControls("rotateleft") then
            v:rotate(-1)
        elseif key == v:getControls("rotateright") then
            v:rotate(1)
        end
        if key == v:getControls("left") or key == v:getControls("right") or key == v:getControls("jump") or key == v:getControls("rotateleft") or key == v:getControls("rotateright") then
            v:keypressed(key)
        end
    end
    if key == "f10" and DEBUG then
        HITBOXES = not HITBOXES
    elseif key == "f11" and DEBUG then
        local p = getPlayerByID(1)
        if p then
            local x, y, vx, vy, sx, sy = p.x, p.y, p.vx, p.vy, p.startx, p.starty
            local cx, cy = CAMERA.x, CAMERA.y

            CHECKPOINTS = {}
            TEXTS = {}
            RANKS = {visible=true, enabled=false, time=0, deaths=0}
            WON = false
        
            MAP:loadMap("level"..Leveltoload, loadobj)
            CAMERA = MAP.camera
            MAP.level = Leveltoload
            
            local np = getPlayerByID(1)
            if np then
                np.x, np.y = x, y
                np.vx, np.vy = vx, vy
                np.startx, np.starty = sx, sy
                np.dead, np.sleeping = false, false
                np.movementenabled, np.rotationenabled = true, true
                CAMERA:setPosition(cx, cy)
                if Leveltoload == "e" then
                    np.gravity, np.vy, np.maxspeedy = 32, 32, 32
                    np.falling = true
                    RANKS.visible = false
                    CAMERA:setStatic(true, false)
                end
            end
        end
    end
    if key == CONTROLS["pause"] then
        paused = not paused
        if music then
            if paused then
                music:pause()
            else
                music:play()
            end
        end
    end
end

function game.keyreleased(key)
    for i, v in pairs(MAP.objects["player"]) do
        if key == v:getControls("jump") then
            v:stopjump()
        end
    end
end

--

function game.mousepressed(x, y, button)
    if paused then
        pausegui:click(x, y, button)
    else
        if not DEBUG then
            return
        end
        local p = getPlayerByID(1)
        if p then
            p:teleport(CAMERA:screenToWorld(x,y,true))
        end
    end
end
function game.mousereleased(x, y, button)
    pausegui:unclick(x, y, button)
end

--

function loadobj(obj)
    if obj.class == "ground" then
        return "ground", P_GROUND:new(MAP, obj.x, obj.y, obj.width, obj.height, obj.properties.semisolid)
    elseif obj.class == "breakable" then
        return "ground", P_BREABALE:new(MAP, obj.x, obj.y, obj.width, obj.height)
    elseif obj.class == "platform" then
        return "ground", P_PLATFORM:new(MAP, obj.x, obj.y, obj.width, obj.height, obj.properties.semisolid)
    elseif obj.class == "spikes" then
        return "spikes", P_SPIKES:new(MAP, obj.x, obj.y, obj.width)

    elseif obj.class == "player" then
        return "player", P_PLAYER:new(MAP, obj.x, obj.y, obj.properties.sleeping, obj.properties.movementenabled, obj.properties.rotationenabled)

    elseif obj.class == "magnet" then
        return "magnet", P_MAGNET:new(MAP, obj.x, obj.y, obj.width, obj.height, obj.properties.north, obj.properties.oneside, obj.properties.range, obj.properties.win)

    elseif obj.class == "cannon" then
        return "cannon", P_CANNON:new(MAP, obj.x, obj.y, obj.properties.dir, obj.properties.speed, obj.properties.oneside, obj.properties.dontdisable)
    elseif obj.class == "cannonball" then
        return "cannonball", P_CANNONBALL:new(MAP, obj.x, obj.y, obj.properties.dir, obj.properties.speed, obj.properties.oneside)

    elseif obj.class == "trigger" then
        return "trigger", P_TRIGGER:new(MAP, obj.x, obj.y, obj.width, obj.height, obj.properties.id)
    elseif obj.class == "text" then
        return "text", P_TEXT:new(MAP, obj.x, obj.y, obj.name, obj.properties.id)

    elseif obj.class == "checkpoint" then
        CHECKPOINTS[obj.x] = obj.y

    end
    return false, false
end

function update(name, dt)
    if not MAP.objects[name] then
        return
    end
    local delete
    for i, v in pairs(MAP.objects[name]) do
        if v.update then
            v:update(dt)
        end
        if v.autodelete then
            local deletedistx, deletedisty = 128, 128
            if type(v.autodelete) == "number" then 
                deletedistx, deletedisty = v.autodelete, v.autodelete
            elseif type(v.autodelete) == "table" then 
                deletedistx, deletedisty = v.autodelete[1], v.autodelete[2]
            end
            if v.autodeleteimmunityx then
                deletedistx = math.huge
            end
            if v.autodeleteimmunityy then
                deletedisty = math.huge
            end
            if not MAP:onCamera(v.x, v.y, v.w, v.h, deletedistx, deletedisty) then
                if v.autodeleted then
                    v:autodeleted()
                end
                v._delete = true
            end
        end
        if v._delete then
            if not delete then delete = {} end
            table.insert(delete, i)
        end
        if v.y > MAPHEIGHT*16 and v.respawn then
            v:respawn()
        end
    end
    if delete then
        table.sort(delete, function(a,b) return a>b end)
        for _, i in pairs(delete) do
            table.remove(MAP.objects[name], i)
        end
    end
end

function draw(name, argument)
    if not MAP.objects[name] then
        return
    end
    for i, v in pairs(MAP.objects[name]) do
        if v.draw and ((not v.w) or MAP:onCamera(v.x, v.y, v.w, v.h)) then
            v:draw(argument)
        end
    end
end

return game