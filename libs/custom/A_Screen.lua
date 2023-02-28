-- MADE BY AIDAN
-- A_Screen - a lightweight, simple screen-state manager.

Screen = {}

function Screen:initialize()
    self.screens = {}
    for i, v in pairs(love.filesystem.getDirectoryItems(ENV.screenspath)) do
        local file = love.filesystem.getInfo(ENV.screenspath .. "/" .. v)
        if file.type == "directory" then
            for i2, v2 in pairs(love.filesystem.getDirectoryItems(ENV.screenspath .. "/" .. v)) do
                local file2 = love.filesystem.getInfo(ENV.screenspath .. "/" .. v .. "/" .. v2)
                if file2.type == "directory" then
                    local name = v .. "/" .. v2:sub(1,-5)
                    self.screens[name] = require(ENV.screenspath .. "/" .. name)
                end
            end
        else
            local name = v:sub(1,-5)
            self.screens[name] = require(ENV.screenspath .. "/" .. name)
        end
    end

    self.state = false
    self.laststate, self.nextstate = false

    self.transitionlock = {"mousepressed", "mousereleased", "keypressed", "keyreleased", "wheelmoved"} -- functions that wont be triggered while transitioning.
end

function Screen:update(dt)
    self:runFunction("update", {dt})
    if self.transition then
        self:updateTransition(dt)
    end
end

function Screen:draw()
    local r,g,b,a = love.graphics.getColor()
    love.graphics.push()
    love.graphics.scale(SCALE,SCALE)
    self:runFunction("draw")
    if self.transition then
        self:drawTransition()
    end
    love.graphics.pop()
    love.graphics.setColor(r,g,b,a)
end

function Screen:mousepressed(x, y, button)
    self:runFunction("mousepressed", {x, y, button})
end
function Screen:mousereleased(x, y, button)
    self:runFunction("mousereleased", {x, y, button})
end
function Screen:keypressed(key)
    self:runFunction("keypressed", {key})
end
function Screen:keyreleased(key)
    self:runFunction("keyreleased", {key})
end
function Screen:wheelmoved(x, y)
    self:runFunction("wheelmoved", {x, y})
end
function Screen:mousemoved(x, y, dx, dy)
    self:runFunction("mousemoved", {x, y, dx, dy})
end
function Screen:resize()
    self:runFunction("resize")
end
function Screen:textinput(text)
    self:runFunction("textinput", {text})
end


--

function Screen:setState(state, transition)
    if self.laststate then
        self:runFunction("unload", {state})
    end

    self.laststate = self.state
    self.state = state
    self.nextstate = false

    if self.state then
        self:runFunction("load", {self.laststate})
    end
end

function Screen:changeState(state, transout, transin)
    self.nextstate = state
    self.transition = "out"
    self.transitiontimer = 0
    self.transitionout = transout or {"none", 0, {0,0,0}}
    self.transitionin = transin or {"none", 0, {0,0,0}}
    self:updateTransition(0)
end

function Screen:runFunction(name, args)
    -- if no function for screen or transiton locks the function
    if (not self.screens[self.state][name]) or (self.transition and tablecontains(self.transitionlock, name)) then
        return
    end
    if args then
        self.screens[self.state][name](unpack(args))
    else
        self.screens[self.state][name]()
    end
end

function Screen:updateTransition(dt)
    if not self.transition then
        return
    end

    self.transitiontimer = self.transitiontimer + dt
    local trans = self.transitionout
    if self.transition == "in" then
        trans = self.transitionin
    end

    if trans[1] == "none" or self.transitiontimer >= trans[2] then
        if self.transition == "out" then
            self.transition = "in"
            self.transitiontimer = self.transitiontimer - trans[2]
            self:setState(self.nextstate)
        else
            self.transition = false
            self:runFunction("ready")
        end
        self:updateTransition(0)
    end
end

function Screen:drawTransition(dt)
    local trans, transt = self.transitionout, "out"
    if self.transition == "in" then
        trans, transt = self.transitionin, "in"
    end
    local percent = self.transitiontimer/trans[2]
    local r,g,b
    if trans[3] then
        r,g,b = trans[3][1] or 0, trans[3][2] or 0, trans[3][3] or 0
    else
        r,g,b = 0, 0, 0
    end

    if trans[1] == "fade" then
        if transt == "out" then
            love.graphics.setColor(r,g,b,percent)
        else
            love.graphics.setColor(r,g,b,1-percent)
        end
        love.graphics.rectangle("fill",0,0,WIDTH,HEIGHT)
    end

    if trans[1] == "sweep-left" then
        love.graphics.setColor(r,g,b)
        if transt == "out" then
            love.graphics.rectangle("fill",WIDTH-(WIDTH*percent),0,WIDTH*percent,HEIGHT)
        else
            love.graphics.rectangle("fill",0,0,WIDTH-(WIDTH*percent),HEIGHT)
        end
    end

    if trans[1] == "sweep-right" then
        love.graphics.setColor(r,g,b)
        if transt == "out" then
            love.graphics.rectangle("fill",0,0,WIDTH*percent,HEIGHT)
        else
            love.graphics.rectangle("fill",WIDTH*percent,0,WIDTH-(WIDTH*percent),HEIGHT)
        end
    end

    if trans[1] == "doors-hor" then
        love.graphics.setColor(r,g,b)
        if transt == "out" then
            love.graphics.rectangle("fill",0,0,(WIDTH/2)*percent,HEIGHT)
            love.graphics.rectangle("fill",WIDTH-((WIDTH/2)*percent),0,(WIDTH/2)*percent,HEIGHT)
        else
            love.graphics.rectangle("fill",0,0,(WIDTH/2)-((WIDTH/2)*percent),HEIGHT)
            love.graphics.rectangle("fill",WIDTH/2+((WIDTH/2)*percent),0,(WIDTH/2)-((WIDTH/2)*percent),HEIGHT)
        end
    end
end

Screen:initialize()