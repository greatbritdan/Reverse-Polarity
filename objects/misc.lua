P_DISABLE = Class("disable") -- unused

function P_DISABLE:initialize(map, x, y, w, h)
    self.map = map
    self.x, self.y, self.w, self.h = x, y, w, h
end

function P_DISABLE:update(dt)
    local cols = collidecheck(self.map, self, {"player"})
    if #cols > 0 then
        local v = cols[1][2]
        v.nomagnet = true
    end
end

--

P_TEXT = Class("text")

function P_TEXT:initialize(map, x, y, text, id)
    self.map = map
    self.x, self.y = x+8, y+4

    self.id = id -- for anims
    self.text, self.alpha = self:sub(text), 1
    self.anim, self.animnewtext = false, false
end

function P_TEXT:update(dt)
    if self.anim == "show" then
        self.alpha = self.alpha + dt*2
        if self.alpha >= 1 then
            self.alpha = 1
            self.anim = false
        end
    elseif self.anim == "hide" then
        self.alpha = self.alpha - dt*2
        if self.alpha <= 0 then
            self.alpha = 0
            self.anim = false
        end
    elseif self.anim == "updatetext" then
        if self.text == self.animnewtext then
            self.alpha = self.alpha + dt*2
            if self.alpha >= 1 then
                self.alpha = 1
                self.anim = false
            end
        else
            self.alpha = self.alpha - dt*2
            if self.alpha <= 0 then
                self.text = self.animnewtext
            end
        end
    end
end

function P_TEXT:sub(text)
    text = text:gsub("<left>",  "<"..CONTROLS["left"]..">")
    text = text:gsub("<right>", "<"..CONTROLS["right"]..">")
    text = text:gsub("<jump>",  "<"..CONTROLS["jump"]..">")
    text = text:gsub("<rotateleft>",  "<"..CONTROLS["rotateleft"]..">")
    text = text:gsub("<rotateright>", "<"..CONTROLS["rotateright"]..">")
    return text
end

function P_TEXT:draw()
    if self.alpha == 0 then
        return
    end
    love.graphics.setColor(1,1,1,self.alpha)
    love.graphics.printf(self.text, self.x-256, self.y, 512, "center")
end

function P_TEXT:show()
    self.anim = "show"
end
function P_TEXT:hide()
    self.anim = "hide"
end
function P_TEXT:updatetext(newtext)
    self.anim = "updatetext"
    self.animnewtext = self:sub(newtext)
end

--

P_TRIGGER = Class("trigger") -- unused

function P_TRIGGER:initialize(map, x, y, w, h, id)
    self.map = map
    self.x, self.y, self.w, self.h = x, y, w, h
    self.id = id -- what triggers when overlapped
    self.disabled = false
end

function P_TRIGGER:update(dt)
    if self.disabled then
        return
    end
    local cols = collidecheck(self.map, self, {"player"})
    if #cols > 0 then
        if not cols[1][2].dead then
            triggerAnim(self.id)
            self.disabled = true
        end
    end
end