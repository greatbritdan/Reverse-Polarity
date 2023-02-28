-- MADE BY AIDAN
-- A_UI - a lightweight, simple GUI kit.
-- Requires: A_Utils

-- Current Elements:
-- Display (text and/or image)
-- Button
-- Toggle
-- Input
-- Scrollbar
-- Dropdown
-- Option Button (used internaly)

GUIICONIMGS = love.graphics.newImage(ENV.imagespath .. "/guiicons.png")
GUIICONNAMES = {"cross","add","subtract","exclaim","question","up","down","left","right","remove","edit"}
GUIICONIDXS = {}
GUIICONQUADS = {}
-- X, +, -, !, ?, UP, DOWN, LEFT, RIGHT, REMOVE, EDIT
for i = 1, 11 do
    GUIICONIDXS[i] = i
    GUIICONQUADS[i] = love.graphics.newQuad((i-1)*10, 0, 10, 10, 110, 10)
end

--

GuiGroup = Class("GuiGroup")

function GuiGroup:initialize(elements, enabled)
    self.elements = {}
    if elements then
        for i, v in pairs(elements) do
            self:add(i, v)
        end
    end
    self.enabled = true
    if enabled == false then
        self.enabled = false
    end
end

function GuiGroup:add(name, element)
    element._group = self
    element.enabled = true
    if enabled == false then
        element.enabled = false
    end
    if name then
        self.elements[name] = element
    else
        table.insert(self.elements, element)
    end
end
function GuiGroup:del(name)
    element._group = nil
    self.elements[name] = nil
end

function GuiGroup:forEach(func, args, condition, breakiftrue)
    if not self.enabled then
        return false
    end
    for i, v in pairs(self.elements) do
        if (condition == nil or condition(v) == true) and v.enabled then
            if args then
                res = v[func](v, unpack(args))
            else
                res = v[func](v)
            end
            if res and breakiftrue then
                return true
            end
        end
    end
    return false
end

function GuiGroup:checkEach(condition)
    if not self.enabled then
        return false
    end
    for i, v in pairs(self.elements) do
        if (condition == nil or condition(v) == true) and v.enabled then
            return true
        end
    end
    return false
end

function GuiGroup:update(dt)
    self:forEach("update", {dt})
end
function GuiGroup:draw()
    self:forEach("draw", nil, function(v) return (v.type ~= "dropdown" or v.collapsed) end)
    self:forEach("draw", nil, function(v) return (v.type == "dropdown" and (not v.collapsed)) end)
end
function GuiGroup:click(x, y, b)
    local broke = self:forEach("click", {x, y, b}, function(v) return (v.type == "dropdown" and (not v.collapsed)) end, true)
    if not broke then
        self:forEach("click", {x, y, b}, function(v) return (v.type ~= "dropdown" or v.collapsed) end, true)
    end
end
function GuiGroup:unclick(x, y, b)
    self:forEach("unclick", {x, y, b})
end
function GuiGroup:press(k)
    self:forEach("press", {k})
end
function GuiGroup:unpress(k)
    self:forEach("unpress", {k})
end
function GuiGroup:textinput(t)
    self:forEach("textinput", {t})
end
function GuiGroup:scrolled(y)
    local broke = self:forEach("scrolled", {y}, function(v) return (v.type == "dropdown" and (not v.collapsed)) end, true)
    if not broke then
        local broke = self:forEach("scrolled", {y}, function(v) return (v.type ~= "dropdown" or v.collapsed) end, true)
    end
end
function GuiGroup:resize()
    self:forEach("updaterange", nil)
end

--

Gui = Class("Gui")
local GUI_INPUTTING = false
local GUI_STYLE_DEFAULT = {
    marginx = 2,
    marginy = 2,
    backcolor  = {normal={0,0,0},       high={0,0,0}, press={0.5,0.5,0.5}},
    linecolor  = {normal={0.5,0.5,0.5}, high={1,1,1}, press={1,1,1}      },
    textcolor  = {normal={1,1,1},       high={1,1,1}, press={1,1,1},     gray={0.5,0.5,0.5}},
    imagecolor = {normal={1,1,1},       high={1,1,1}, press={1,1,1},     gray={0.5,0.5,0.5}}
}

function Gui_generateButtonImg(path, cornersize)
    local buttonimg = love.graphics.newImage(path)
    local buttonquads = {}

    local cs = cornersize
    local w, h = 15+(8*cs), 3+(2*cs)
    local function creatquads(n,x)
        buttonquads[n] = {
            top = {
                left =  love.graphics.newQuad(x,      0, cs, cs, w, h),
                mid =   love.graphics.newQuad(x+cs+1, 0, 1,  cs, w, h),
                right = love.graphics.newQuad(x+cs+3, 0, cs, cs, w, h)
            },
            mid = {
                left =  love.graphics.newQuad(x,      cs+1, cs, 1, w, h),
                mid =   love.graphics.newQuad(x+cs+1, cs+1, 1,  1, w, h),
                right = love.graphics.newQuad(x+cs+3, cs+1, cs, 1, w, h)
            },
            bottom = {
                left =  love.graphics.newQuad(x,      cs+3, cs, cs, w, h),
                mid =   love.graphics.newQuad(x+cs+1, cs+3, 1,  cs, w, h),
                right = love.graphics.newQuad(x+cs+3, cs+3, cs, cs, w, h)
            }
        }
    end

    creatquads("normal", 0)
    creatquads("high",   4+(2*cs))
    creatquads("press",  8+(4*cs))
    creatquads("black",  12+(6*cs))

    return buttonimg, buttonquads
end

-- get swag B)
function Gui:getStyle(style)
    if not style then style = {} end
    local result = {}

    result.marginx = style.marginx or style.margin or GUI_STYLE_DEFAULT.marginx
    result.marginy = style.marginy or style.margin or GUI_STYLE_DEFAULT.marginy

    if style.buttonimg and style.buttonquads and style.buttoncornersize then
        result.buttonimg = style.buttonimg
        result.buttonquads = style.buttonquads
        result.buttoncornersize = style.buttoncornersize
    end

    local cols = {"backcolor", "linecolor", "textcolor", "imagecolor"}
    for _, col in pairs(cols) do
        result[col] = deepcopy(GUI_STYLE_DEFAULT[col])
        if style[col] then
            if style[col].normal then
                result[col].normal = style[col].normal or GUI_STYLE_DEFAULT[col].normal
            end
            if style[col].high then
                result[col].high   = style[col].high   or GUI_STYLE_DEFAULT[col].high
            end
            if style[col].press then
                result[col].press  = style[col].press  or GUI_STYLE_DEFAULT[col].press
            end
            if (col == "textcolor" or col == "imagecolor") and result[col].gray then
                result[col].gray = style[col].gray or GUI_STYLE_DEFAULT[col].gray
            end
        end
    end

    return result
end

function Gui:initialize(position, properties, style)
    self.rawstyle = deepcopy(style)
    style = self:getStyle(style)
    self.type, self.style = position.type, deepcopy(style)
    self.x, self.y, self.w, self.h = position.x, position.y, position.w, position.h
    self.marginx = position.marginx or position.margin or style.marginx
    self.marginy = position.marginy or position.margin or style.marginy
    local defaultheight = self:height("")+(self.marginy*2)

    self.secret = properties.secret -- shhhh

    self.func, self.args = properties.func, properties.args
    self.state, self.states = properties.state or 1, false

    self.pressed, self.inputting, self.holding, self.repeating = false, false, false, false

    -- Text
    self.text = false
    if self.type ~= "scroll" and properties.text then
        if type(properties.text) == "table" then
            self.states = #properties.text
        end
        self.text = deepcopy(properties.text)
        self.textallignx, self.textalligny = properties.textallignx or "center", properties.textalligny or "center"
    end

    -- Image
    self.image = false
    self.quad = false
    self.basequad = false
    if self.type ~= "scroll" and properties.image then
        if type(properties.image) == "table" and (not self.states) then
            self.states = #properties.image
        end
        self.image = deepcopy(properties.image)
        if properties.quad then
            if type(properties.quad) == "table" and (not self.states) then
                self.states = #properties.quad
            end
            self.quad = deepcopy(properties.quad)
        end
        if properties.basequad then
            self.basequad = properties.basequad
        end
        self.imageallignx, self.imagealligny = properties.imageallignx or "center", properties.imagealligny or "center"
    end

    -- Repeating
    if self.type == "button" or self.type == "toggle" or self.type == "input" then
        self.dorepeat = properties.dorepeat or (self.type == "input")
        self.repeatdelay = properties.repeatdelay or 0.5
        self.repeatfrequency = properties.repeatfrequency or 0.05
    end

    -- Toggles only
    if self.type == "toggle" then
        self.values = properties.values or false
    end

    -- Input only
    if self.type == "input" then
        self.placeholder = properties.placeholder or false
        self.maxcharacters = properties.maxcharacters or false

        self.allowedcharacters = properties.allowedcharacters or "abcdefghijklmnopqrstuvwxyz 0123456789.,:;_-!?\"'/\\^*()[]%<>+=#|`{}~"
        local allow = {}
        for i = 1, #self.allowedcharacters do
            allow[i] = string.sub(self.allowedcharacters, i, i)
        end
        self.allowedcharacters = deepcopy(allow)

        self.scrollx = 0
        self.cursor, self.selecter = #self.text, false -- cursor pos, selector pos {start, end}
        self.cursortimer = 0
    end

    -- Scrollbar only
    if self.type == "scroll" then
        self.dir = properties.dir or "hor"
        self.limit = properties.limit or {0, 100, 0, 1} -- min, max, decimal place, precision
        self.gloablscroll = properties.gloablscroll or false
        self.value = properties.value or self.limit[1]
        self.unpressfunc = properties.unpressfunc or false

        self.displayvalue = false
        self.bx, self.by, self.bw, self.bh = 0, 0, self.w, self.h
        if self.dir == "hor" then
            self.displayvalue = properties.displayvalue or false
            self.percentfill = properties.fill or 0.25
            if self.percentfill > 1 then
                self.percentfill = 1 / (self.w/self.percentfill)
            end
            self.bw = round(self.w*self.percentfill)
            if self.value ~= self.limit[1] then
                self.bx = self:posFromValue()
            end
        elseif self.dir == "ver" then
            self.percentfill = properties.fill or 0.25
            if self.percentfill > 1 then
                self.percentfill = 1 / (self.h/self.percentfill)
            end
            self.bh = round(self.h*self.percentfill)
            if self.value ~= self.limit[1] then
                self.by = self:posFromValue()
            end
        end
    end

    -- Dropdown only
    if self.type == "dropdown" then
        self.collapsed = true
        if properties.collapsed == false then self.collapsed = false end
        self.autoclose = true
        if properties.autoclose == false then self.autoclose = false end
        self.displayvalue = true
        if properties.displayvalue == false then self.displayvalue = false end
        self.initfunc = properties.initfunc or false

        self.vh = position.valueh or defaultheight
        self.values = deepcopy(properties.values)
        self.value = properties.value or 1

        self.elements = {}
        local y = self.y+self.h
        for i, v in pairs(self.values) do
            local p = self:runFunction(self.initfunc, {i,v}) or {}
            local style = p.style or false
            local gui = Gui:new(
                {
                    type="optionbutton", x=self.x, y=y, w=self.w, h=self.vh, margin=p.margin, marginx=p.marginx, marginy=p.marginy
                },
                {
                    text=v, textallignx=p.textallignx, textalligny=p.textalligny, image=p.image, quad=p.quad, basequad=p.basequad, imageallignx=p.imageallignx, imagealligny=p.imagealligny,
                    func=function(s) s.parent:changeState(s.index); s.parent:realign() end
                },
                style
            )
            gui.parent, gui.index = self, i
            self.elements[i] = gui

            y = y + gui.h
        end
        self:changeState(self.value)
        self:updaterange()
    end

    if style.buttonimg then
        self.buttonimg = style.buttonimg
        self.buttonquads = style.buttonquads
        self.buttoncornersize = style.buttoncornersize

        self.buttonbatches = {}
        if self.type == "scroll" then
            self.buttonbatches["normal"] = self:generateSpriteBatch("normal", self.bw, self.bh)
            self.buttonbatches["high"]   = self:generateSpriteBatch("high", self.bw, self.bh)
            self.buttonbatches["press"]  = self:generateSpriteBatch("press", self.bw, self.bh)
            self.buttonbatches["black"] =  self:generateSpriteBatch("black", self.w, self.h)
        else
            self.buttonbatches["normal"] = self:generateSpriteBatch("normal", self.w, self.h)
            self.buttonbatches["high"]   = self:generateSpriteBatch("high", self.w, self.h)
            self.buttonbatches["press"]  = self:generateSpriteBatch("press", self.w, self.h)
        end

        self.backcolor = {normal={1,1,1}, high={1,1,1}, press={1,1,1}}
        self.linecolor = {normal={1,1,1}, high={1,1,1}, press={1,1,1}}
    else
        self.backcolor = style.backcolor
        self.linecolor = style.linecolor
    end
    self.textcolor = style.textcolor
    self.imagecolor = style.imagecolor
end

function Gui:generateSpriteBatch(n, w, h)
    local cs = self.buttoncornersize
    local inw, inh = w-(cs*2), h-(cs*2)
    local spb = love.graphics.newSpriteBatch(self.buttonimg, 9)
    spb:add(self.buttonquads[n].top.left,     0,      0,      0,  1,   1)
    spb:add(self.buttonquads[n].top.mid,      cs,     0,      0,  inw, 1)
    spb:add(self.buttonquads[n].top.right,    cs+inw, 0,      0,  1,   1)
    spb:add(self.buttonquads[n].mid.left,     0,      cs,     0,  1,   inh)
    spb:add(self.buttonquads[n].mid.mid,      cs,     cs,     0,  inw, inh)
    spb:add(self.buttonquads[n].mid.right,    cs+inw, cs,     0,  1,   inh)
    spb:add(self.buttonquads[n].bottom.left,  0,      cs+inh, 0,  1,   1)
    spb:add(self.buttonquads[n].bottom.mid,   cs,     cs+inh, 0,  inw, 1)
    spb:add(self.buttonquads[n].bottom.right, cs+inw, cs+inh, 0,  1,   1)
    return spb
end

function Gui:updaterange()
    if self.type == "dropdown" then
        local clopsed = self.collapsed
        if not self.collapsed then
            self.collapsed = true
            self:realign()
        end

        self.closedy, self.openy = self.y, self.y
        self.offy = 0
        self.scroll = false
        if self.h+(self.vh*#self.elements) > HEIGHT then
            self.openy = 0
            local gui = Gui:new(
                {
                    type="scroll", x=self.x+self.w, y=self.openy+self.h, w=10, h=HEIGHT-self.h
                },
                {
                    dir="ver", limit={0,(#self.elements*self.vh)-(HEIGHT-self.h),0,self.vh/2}, fill=(HEIGHT-self.h)/(#self.elements*self.vh),
                    func=function(s) self.offy = s.value; s.parent:realign(true) end, gloablscroll=true
                },
                self.rawstyle
            )
            gui.parent = self
            self.scroll = gui
        elseif self.y+self.h+(self.vh*#self.elements) > HEIGHT then
            self.openy = HEIGHT-self.h-(self.vh*#self.elements)
        end

        if not clopsed then
            self.collapsed = false
            self:realign()
        end
    end
end

function Gui:update(dt)
    if self.repeating then
        self.repeating.timer = self.repeating.timer + dt
        if self.repeating.timer > self.repeatdelay then
            self.repeating.timer = self.repeating.timer - self.repeatfrequency
            self.repeating.func(self, unpack(self.repeating.args))
        end
    end
    if self.type == "input" then
        if self.selecter and self.selecter[3] == "high" then
            local s = self:getCursor(getX(),getY())
            if s then self.selecter[2] = s end
        end
        self.cursortimer = self.cursortimer + dt
    end
    if self.type == "scroll" and self.holding then
        if self.dir == "hor" then
            self.bx = math.max(0, math.min(getX()-self.x-self.holding, self.w-self.bw))
        elseif self.dir == "ver" then
            self.by = math.max(0, math.min(getY()-self.y-self.holding, self.h-self.bh))
        end
        local oldval = self.value
        self.value = self:valueFromPos()
        if self.value ~= oldval then
            self:runFunction(self.func, self.args)
        end
    end
    if self.type == "dropdown" and self.scroll and (not self.collapsed) then
        self.scroll:update(dt)
    end
end

function Gui:draw()
    if self.secret then
        return
    end
    if self.x+self.w < 0 or self.x > WIDTH or self.y+self.h < 0 or self.y > HEIGHT then
        return
    end

    local backc, linec, textc, imagec = self.backcolor, self.linecolor, self.textcolor, self.imagecolor
    local color = self:getColor()

    if self.type == "dropdown" and (not self.collapsed) then
        local y = self.y+self.h
        for i, v in pairs(self.elements) do
            v:draw()
        end
        if self.scroll then
            self.scroll:draw()
        end
    end
    if self.type ~= "display" and self.type ~= "scroll" then
        if self.buttonimg then
            love.graphics.setColor(1,1,1)
            love.graphics.draw(self.buttonbatches[color], self.x, self.y)
        else    
            self:drawbox(linec[color], backc[color]) 
        end
    end
    if self.type == "display" or self.type == "button" or self.type == "toggle" or self.type == "dropdown" or self.type == "optionbutton" then
        if self.type == "optionbutton" then
            if self.parent and self.index == self.parent.value then
                color = "press"
            elseif color == "normal" then
                color = "gray"
            end
        end
        if self.text then
            self:drawtext(self.state, self.text, self.textallignx, self.textalligny, 0, 0, textc[color])
        end
        if self.image then
            self:drawimg(self.state, self.image, self.quad, self.basequad, self.imageallignx, self.imagealligny, 0, 0, imagec[color])
        end
    elseif self.type == "input" and self.text then
        local text, placeholder = self.text, false
        local itextcolor = textc[color]
        if self.text == "" and self.placeholder then
            text, placeholder = self.placeholder, true
            itextcolor = textc["gray"]
        end

        love.graphics.setScissor((self.x+self.marginx-1)*SCALE, (self.y+self.marginy)*SCALE, (self.w+1-self.marginx*2)*SCALE, (self.h-(self.marginy*2))*SCALE)
        if self.inputting then
            self:drawtext(1, text, "left", "top", -self.scrollx, 0, itextcolor)
            if (not placeholder) then
                if self.cursortimer*2 % 2 >= 1 then
                    local cx = self:getCursorPos(self.cursor)
                    self:drawboxexact(cx, self.y+self.marginy, 1, self:height(""), itextcolor)
                end
                if self.selecter then
                    local textcolortrans = {itextcolor[1],itextcolor[2],itextcolor[3],155} -- good for her!
                    local selection = {self.selecter[1],self.selecter[2]}
                    table.sort(selection)
                    local cs, ce = self:getCursorPos(selection[1]), self:getCursorPos(selection[2])
                    self:drawboxexact(cs+1, self.y+self.marginy, ce-cs-1, self:height(""), textcolortrans)
                end
            end
        else
            self:drawtext(1, text, self.textallignx, self.textalligny, 0, 0, itextcolor)
        end
        love.graphics.setScissor()
    elseif self.type == "scroll" then
        local text = tostring(self.value)
        local textw = self:width(text)
        if self.buttonimg then
            love.graphics.setColor(1,1,1)
            love.graphics.draw(self.buttonbatches["black"], self.x, self.y)
        else    
            self:drawbox(backc["normal"])
        end
        if self.displayvalue then
            if textw+(self.marginx*2) <= self.w-self.bx-self.bw then
                self:drawtextexact(self.x+self.bx+self.bw, self.y, textw, self.h, 1, text, "left", "center", 0, 0, textc["gray"])
            else
                self:drawtextexact(self.x+self.bx-textw, self.y, textw, self.h, 1, text, "right", "center", 0, 0, textc["gray"])
            end
        end
        if self.buttonimg then
            love.graphics.setColor(1,1,1)
            love.graphics.draw(self.buttonbatches[color], self.x+self.bx, self.y+self.by)
        else    
            self:drawboxexact(self.x+self.bx, self.y+self.by, self.bw, self.bh, linec[color], backc[color])
        end
    end

    --[[if love.keyboard.isDown("p") then
        self:drawbox({1,0.4,0.4}, {0,0,0,0})
        if self.type == "input" then
            self:drawboxexact(self.x+self.marginx, self.y+self.marginy, self.w-(self.marginx*2), self.h-(self.marginy*2), {0.4,1,0.4}, {0,0,0,0})
        elseif self.type == "scroll" then
            self:drawboxexact(self.x+self.bx, self.y+self.by, self.bw, self.bh, {0.4,0.4,1}, {0,0,0,0})
        end
    end]]
end

function Gui:click(x, y, button)
    if button ~= 1 then
        return false
    end
    local touching = self:getHighlight(x,y)
    if touching then
        if (self.type == "button" or self.type == "toggle" or self.type == "optionbutton") and (self.repeating or (not self.pressed)) then
            if self.type == "optionbutton" and self.parent then
                self.parent.value = self.index
                self.parent:runFunction(self.parent.func, self.parent.args)
            end
            playsound(Clicksound)
            self:changeState()
            self:runFunction(self.func, self.args)
            self.pressed = true
            if self.dorepeat and (not self.repeating) then
                self.repeating = {timer=0, func=self.click, args={x, y, button}}
            end
            return true
        elseif self.type == "input" then
            self.cursortimer = 0.5
            if not self.inputting then
                self.cursor = #self.text
                self.originaltext = self.text
                self.inputting = true
                if GUI_INPUTTING then
                    GUI_INPUTTING:quitInputting()
                end
                GUI_INPUTTING = self
            else
                self.cursor = self:getCursor(x, y)
                self.selecter = {self.cursor, self.cursor, "high"}
                self:cursorScroll()
            end
            return true
        elseif self.type == "scroll" and touching == "head" then
            if self.dir == "hor" then
                self.holding = x-self.x-self.bx
            elseif self.dir == "ver" then
                self.holding = y-self.y-self.by
            end
            return true
        elseif self.type == "dropdown" then
            if touching == "head" then
                self.collapsed = not self.collapsed
                self:realign()
                self:changeState(false)
                return true
            elseif touching == "body" then
                for i, v in pairs(self.elements) do
                    if v:click(x, y, button) then
                        return true
                    end
                end
            else
                if self.scroll:click(x, y, button) then
                    return true
                end
            end
        end
    else
        if self.type == "input" and self.inputting then
            self:quitInputting()
        end
        if self.type == "dropdown" and (not self.collapsed) then
            self.collapsed = true
            self:realign()
            self:changeState(false)
        end
    end
    return false
end

function Gui:realign(scroll)
    local oldy = self.y
    self.y = self.openy
    if self.collapsed then
        self.y = self.closedy
    end
    if self.y ~= oldy or scroll then
        local y = self.y+self.h-self.offy
        for i, v in pairs(self.elements) do
            v.y = y
            y = y + v.h
        end
    end
end

function Gui:unclick(x, y, button)
    if button ~= 1 then
        return false
    end
    if (self.type == "button" or self.type == "toggle" or self.type == "optionbutton") and self.pressed then
        self.pressed = false
        self.repeating = false
    elseif self.type == "input" and self.selecter then
        if self.selecter[1] == self.selecter[2] then
            self.selecter = false
        else
            self.selecter[3] = "held"
        end
    elseif self.type == "scroll" and self.holding then
        self.holding = false
        self:runFunction(self.unpressfunc) -- added in jam
    elseif self.type == "dropdown" then
        for i, v in pairs(self.elements) do
            v:unclick(x, y, button)
        end
        if self.scroll then
            self.scroll:unclick(x, y, button)
        end
    end
end

function Gui:press(key)
    if self.type == "input" and self.inputting and key ~= "lctrl" then
        local ctrl = love.keyboard.isDown("lctrl")
        local oldtext, oldcursor = self.text, self.cursor

        local selection, saveselection = false, false
        if self.selecter then
            selection = {self.selecter[1],self.selecter[2]}
            table.sort(selection)
            selection[3] = "held"
        end

        -- do key things
        if key == "escape" or key == "return" then
            if key == "escape" then
                self.text = self.originaltext
            else
                self:runFunction(self.func, self.args)
            end
            self:quitInputting()
            return
        elseif key == "left" then
            if selection then
                self.cursor = math.max(0, selection[1])
            else
                self.cursor = math.max(0, self.cursor-1)
            end
        elseif key == "right" then
            if selection then
                self.cursor = math.min(selection[2], #self.text)
            else
                self.cursor = math.min(self.cursor+1, #self.text)
            end
        elseif key == "home" or key == "pageup" then
            self.cursor = 0
        elseif key == "end" or key == "pagedown" then
            self.cursor = #self.text
        elseif ctrl then
            if selection and (key == "c" or key == "x") then
                love.system.setClipboardText(string.sub(self.text, selection[1]+1, selection[2]))
            elseif key == "v" then
                local text = love.system.getClipboardText()
                self.text = string.sub(self.text, 1, self.cursor) .. text .. string.sub(self.text, self.cursor+1, #self.text)
                self.cursor = self.cursor + #text
            elseif key == "a" then
                selection = {0, #self.text, "held"}
                saveselection = true
            end
            if selection and (key == "x" or key == "v") then
                self.text = string.sub(self.text, 1, selection[1]) .. string.sub(self.text, selection[2]+1, #self.text)
                self.cursor = self.cursor - (self.cursor-selection[1])
            end
        elseif selection and (key == "delete" or key == "backspace") then
            self.text = string.sub(self.text, 1, selection[1]) .. string.sub(self.text, selection[2]+1, #self.text)
            self.cursor = self.cursor - (self.cursor-selection[1])
        end
        if (not selection) then
            if key == "delete" then
                self.text = string.sub(self.text, 1, self.cursor) .. string.sub(self.text, self.cursor+2, #self.text)
            elseif key == "backspace" and self.cursor > 0 then
                self.text = string.sub(self.text, 1, self.cursor-1) .. string.sub(self.text, self.cursor+1, #self.text)
                self.cursor = self.cursor - 1
            end
        end
        self:cursorScroll()

        -- max
        if self.maxcharacters and #self.text > self.maxcharacters then
            self.text, self.cursor = oldtext, oldcursor
        end
        -- reset cursor time if edited
        if oldtext ~= self.text or oldcursor ~= self.cursor or saveselection then
            self.cursortimer = 0.5
        end
        self.selecter = false
        if saveselection then
            self.selecter = deepcopy(selection)
        end
        -- repeatrepeatrepeatrepeatrepeat
        if self.dorepeat and (not self.repeating) and (key == "left" or key == "right" or key == "backspace" or key == "delete") then
            self.repeating = {timer=0, func=self.press, args={key}}
        end
    end
end

function Gui:unpress(key)
    if self.type == "input" and self.repeating and self.repeating.args[1] == key then
        self.repeating = false
    end
end

function Gui:textinput(text)
    text = string.lower(text)
    if self.type == "input" and self.inputting then
        local oldtext, oldcursor = self.text, self.cursor

        local selection = false
        if self.selecter then
            selection = {self.selecter[1],self.selecter[2]}
            table.sort(selection)
            selection[3] = "held"
        end

        -- do key things
        if tablecontains(self.allowedcharacters, text) then
            if selection then
                self.text = string.sub(self.text, 1, selection[1]) .. string.sub(self.text, selection[2]+1, #self.text)
                self.cursor = self.cursor - (self.cursor-selection[1])
            end
            self.text = string.sub(self.text, 1, self.cursor) .. text .. string.sub(self.text, self.cursor+1, #self.text)
            self.cursor = self.cursor + #text
        end
        self:cursorScroll()

        -- max
        if self.maxcharacters and #self.text > self.maxcharacters then
            self.text, self.cursor = oldtext, oldcursor
        end
        -- reset cursor time if edited
        if oldtext ~= self.text or oldcursor ~= self.cursor then
            self.cursortimer = 0.5
        end
        self.selecter = false
    end
end

function Gui:scrolled(y)
    if self.type == "scroll" and (self:getHighlight(getX(), getY()) or self.gloablscroll) then
        oldval = self.value
        self.value = math.max(self.limit[1], math.min(round(self.value+((-y)*self.limit[4])), self.limit[2]))
        if self.dir == "hor" then
            self.bx = self:posFromValue()
        elseif self.dir == "ver" then
            self.by = self:posFromValue()
        end
        if self.value ~= oldval then
            self:runFunction(self.func, self.args)
        end
        self:runFunction(self.unpressfunc) -- added in jam
        return true
    end
    if self.type == "dropdown" and self.scroll and (not self.collapsed) then
        if self.scroll:scrolled(y) then
            return true
        end
    end
    return false
end

--

function Gui:changeState(index)
    if self.type == "toggle" then
        self.state = self.state + 1
        if self.state > self.states then
            self.state = 1
        end
    elseif self.type == "dropdown" then
        if index then
            self.value = index
            if self.autoclose then
                self.collapsed = true
            end
            if self.displayvalue then
                if type(self.displayvalue) == "function" then
                    self.text = self:displayvalue()
                else
                    self.text = self:getValue()
                end
            end
        end
        self.state = 1
        if self.states and self.states > 1 and (not self.collapsed) then
            self.state = 2
        end
    end
end

function Gui:getValue()
    if self.type == "toggle" then
        if self.values then
            return self.values[self.state]
        else
            return self.state
        end
    elseif self.type == "input" then
        return self.text
    elseif self.type == "scroll" then
        return self.value
    elseif self.type == "dropdown" then
        return self.values[self.value]
    elseif self.type == "optionbutton" then
        return self.index
    end
    return false
end
function Gui:getHighlight(x, y)
    if (self.type == "button" or self.type == "toggle" or self.type == "input" or self.type == "optionbutton") then
        if aabb(self.x, self.y, self.w, self.h, x, y, 1, 1) then
            return true
        end
    elseif self.type == "dropdown" then
        if aabb(self.x, self.y, self.w, self.h, x, y, 1, 1) then
            return "head"
        elseif (not self.collapsed) and aabb(self.x, self.y, self.w, self.h+(self.vh*#self.elements), x, y, 1, 1) then
            return "body"
        elseif self.scroll and aabb(self.x+self.w, self.y+self.h, 10, HEIGHT-self.h, x, y, 1, 1) then
            return "scroll"
        end
    elseif self.type == "scroll" then
        if aabb(self.x+self.bx, self.y+self.by, self.bw, self.bh, x, y, 1, 1) then
            return "head"
        elseif aabb(self.x, self.y, self.w, self.h, x, y, 1, 1) then
            return "body"
        end
    end
    return false
end
function Gui:getColor(x,y)
    x, y = x or getX(), y or getY()
    local touching = self:getHighlight(x,y)
    if self.pressed or self.holding then
        return "press"
    end
    if (touching == true or touching == "head") or self.inputting then
        return "high"
    end
    return "normal"
end

function Gui:runFunction(func,args)
    if not func then
        return false
    end
    if args then
        return func(self, unpack(args))
    else
        return func(self)
    end
    return false
end

-- Input
function Gui:quitInputting()
    self.inputting = false
    self.cursor, self.selecter = false, false
    GUI_INPUTTING = nil
end

function Gui:getCursor(x, y)
    if self:getHighlight(x, y) then
        for c = 0, #self.text do
            if x-(self.x+self.marginx-1)+self.scrollx <= self:width(string.sub(self.text, 1, c))+(self:width(string.sub(self.text, c+1, c+1))/2) then
                return c
            end
        end
        return #self.text
    end
    return false
end
function Gui:getCursorPos(c)
    return self.x+self.marginx+self:width(string.sub(self.text, 1, c))-self.scrollx-1
end
function Gui:cursorScroll()
    self.scrollx = math.max(0, round(self:width(string.sub(self.text, 1, self.cursor)) - self.w*0.9))
end

-- Slider
function Gui:valueFromPos()
    local percent
    if self.dir == "hor" then
        percent = ((100/(self.w-self.bw))*self.bx)/100
    elseif self.dir == "ver" then
        percent = ((100/(self.h-self.bh))*self.by)/100
    end
    local value = self.limit[1] + ((self.limit[2]-self.limit[1])*percent)
    if self.limit[3] == 0 then
        return round(value)
    else
        return round(value*(10^self.limit[3]))/(10^self.limit[3])
    end
end
function Gui:posFromValue()
    if self.dir == "hor" then
        return ((self.w-self.bw)/100) * ((self.value-self.limit[1]) / ((self.limit[2]-self.limit[1])/100))
    elseif self.dir == "ver" then
        return ((self.h-self.bh)/100) * ((self.value-self.limit[1]) / ((self.limit[2]-self.limit[1])/100))
    end
end

--

function Gui:getAllignX(x, w, contw, allignx)
    local newx = x
    if allignx == "left" then
        newx = x+self.marginx
    elseif allignx == "right" then
        newx = x+w-contw-self.marginx
    elseif allignx == "center" then
        newx = round(x+((w/2)-(contw/2)))
    end
    return newx
end
function Gui:getAllignY(y, h, conth, alligny)
    local newy = y
    if alligny == "top" then
        newy = y+self.marginy
    elseif alligny == "bottom" then
        newy = y+h-conth-self.marginy
    elseif alligny == "center" then
        newy = round(y+((h/2)-(conth/2)))
    end
    return newy
end

function Gui:width(text)
    return getFontWidth(text)
end
function Gui:height(text)
    local split = text:split("\n")
    return #split*getFontHeight()-getFontSpacing()
end

function Gui:drawbox(linecolor, backcolor)
    self:drawboxexact(self.x, self.y, self.w, self.h, linecolor, backcolor)
end
function Gui:drawboxexact(x, y, w, h, linecolor, backcolor)
    if backcolor then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(linecolor)
        love.graphics.rectangle("line", x+1, y+1, w-2, h-2)
        love.graphics.setColor(backcolor)
        love.graphics.rectangle("fill", x+1, y+1, w-2, h-2)
    else
        love.graphics.setColor(linecolor)
        love.graphics.rectangle("fill", x, y, w, h)
    end
end

function Gui:drawtext(state, text, textax, textay, textox, textoy, textcolor)
    self:drawtextexact(self.x, self.y, self.w, self.h, state, text, textax, textay, textox, textoy, textcolor)
end
function Gui:drawtextexact(x, y, w, h, state, text, textax, textay, textox, textoy, textcolor)
    text = text
    if state and type(text) == "table" then
        text = text[state]
    end

    love.graphics.setColor(textcolor)
    local dx, dy = self:getAllignX(x, w, self:width(text), textax), self:getAllignY(y, h, self:height(text), textay)
    love.graphics.print(text, dx+textox, dy+textoy)
end

function Gui:drawimg(state, image, quad, basequad, imageax, imageay, imageox, imageoy, imagecolor)
    self:drawimgexact(self.x, self.y, self.w, self.h, state, image, quad, basequad, imageax, imageay, imageox, imageoy, imagecolor)
end
function Gui:drawimgexact(x, y, w, h, state, image, quad, basequad, imageax, imageay, imageox, imageoy, imagecolor)
    image, quad = image, quad
    if state and type(image) == "table" then
        image = image[state]
    end
    if state and type(quad) == "table" then
        quad = quad[state]
        if not quad then
            return
        end
        if basequad then
            quad = basequad[quad]
        end
    end

    love.graphics.setColor(imagecolor)
    if quad then
        _, __, imagew, imageh = quad:getViewport()
        local dx, dy = self:getAllignX(x, w, imagew, imageax), self:getAllignY(y, h, imageh, imageay)
        love.graphics.draw(image, quad, dx+imageox, dy+imageoy)
    else
        imagew, imageh = image:getWidth(), image:getHeight()
        local dx, dy = self:getAllignX(x, w, imagew, imageax), self:getAllignY(y, h, imageh, imageay)
        love.graphics.draw(image, dx+imageox, dy+imageoy)
    end
end