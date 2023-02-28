-- MADE BY AIDAN
-- A_Camera - a lightweight, simple camera system.
-- Requires: A_Utils

Camera = Class("_camera")

function Camera:initialize()
    self.sx, self.sy, self.ex, self.ey = 0, 0, WIDTH, HEIGHT
    self.x, self.y = 0, 0
    self.bx, self.by, self.bw, self.bh = 0, 0, WIDTH, HEIGHT
    self.smoothx, self.smoothy = 3, 3
    self.staticx, self.staticy = false, false
end

function Camera:set()
    love.graphics.push()
    love.graphics.translate(self.bx-(round(self.x*SCALE)/SCALE), self.by-(round(self.y*SCALE)/SCALE))
    love.graphics.setScissor(self.bx*SCALE, self.by*SCALE, self.bw*SCALE, self.bh*SCALE)
end
function Camera:unset()
    love.graphics.setScissor()
    love.graphics.pop()
end

function Camera:limit()
    self.x = math.max(self.sx,math.min(self.x, (self.ex-self.bw)))
    self.y = math.max(self.sy,math.min(self.y, (self.ey-self.bh)))
end
function Camera:setBounds(sx,sy,ex,ey)
    self.sx, self.sy, self.ex, self.ey = sx, sy, ex, ey
    self:limit()
end
function Camera:setPosition(x, y)
    if not self.staticx then
        self.x = x or self.x
    end
    if not self.staticy then
        self.y = y or self.y
    end
    self:limit()
end
function Camera:setView(x, y, w, h)
    self.bx, self.by, self.bw, self.bh = x or self.bx, y or self.by, w or self.w, h or self.h
    self:limit()
end
function Camera:setSmoothing(smoothx, smoothy)
    self.smoothx, self.smoothy = smoothx or self.smoothx, smoothy or self.smoothy
end
function Camera:setStatic(staticx, staticy)
    self.staticx, self.staticy = staticx or self.staticx, staticy or self.staticy
end

function Camera:focus(x,y,w,h,dt)
    local newx, newy = x+(w/2)-(self.bw/2), y+(h/2)-(self.bh/2)
    if not self.staticx then
        self.x = lerp(self.x, newx, self.smoothx, dt)
    end
    if not self.staticy then
        self.y = lerp(self.y, newy, self.smoothy, dt)
    end
    self:limit()
end
function Camera:forcefocus(x,y,w,h,dt)
    local newx, newy = x+(w/2)-(self.bw/2), y+(h/2)-(self.bh/2)
    if not self.staticx then
        self.x = newx
    end
    if not self.staticy then
        self.y = newy
    end
    self:limit()
end

function Camera:worldToScreen(x,y,r) -- r: round
    if r then
        return round(x-self.x), round(y-self.y)
    else
        return x-self.x, y-self.y
    end
end
function Camera:screenToWorld(x,y,r) -- r: round
    if r then
        return round(x+self.x), round(y+self.y)
    else
        return x+self.x, y+self.y
    end
end