EFFECT = Class("effect")

function EFFECT:initialize(t, x, y)
    self.x, self.y = x, y
    self.vx, self.vy = 0, 0

    --self.dirx, self.diry = (math.random(1,2)*2)-3, (math.random(1,2)*2)-3 -- 1 or -1 (there is probbably a better way to do this)
    if t == "dustl" or t == "dustr" or t == "dustu" or t == "dustd" then
        local group = "dust"..math.random(1,2)
        self.frames = {group=group, frames={1,2,3,4}, frame=1, time=0.15, timer=0}
        self.lifetime = 0.6
        if t == "dustl" then
            self.vx = -32
        elseif t == "dustr" then
            self.vx = 32
        elseif t == "dustu" then
            self.vy = -32
        elseif t == "dustd" then
            self.vy = 32
        end
    elseif t == "spark" then
        self.frames = {group="spark", frames={1,2,3,4}, frame=1, time=0.05, timer=0}
        self.lifetime = 0.4
        self.vx, self.vy = math.random(-32,32), math.random(-32,32)
    elseif t == "brickl" or t == "brickr" then
        local group = "brick"..math.random(1,2)
        self.frames = {group=group, frames={1,2,3,4}, frame=1, time=0.15, timer=0}
        self.lifetime = 1.8
        self.gravity = 256
        if t == "brickl" then
            self.vx = -16 + math.random(-8,8)
        elseif t == "brickr" then
            self.vx = 16 + math.random(-8,8)
        end
    end
    self.color = {1,1,1,1}
    self.fade = true

    self.startlifetime = self.lifetime
end

function EFFECT:update(dt)
    -- delete
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self._delete = true
    end

    -- frames
    local f = self.frames
    if #f.frames > 1 then
        f.timer = f.timer + dt
        if f.timer >= f.time then
            f.frame = f.frame + 1
            f.timer = f.timer - f.time
            if f.frame > #f.frames then
                f.frame = 1
            end
        end
    end

    -- fading
    if self.fade then
        self.color[4] = self.color[4] - self.startlifetime*dt
    end

    -- physics
    if self.gravity then
        self.vy = self.vy + self.gravity*dt
    end
    self.x = self.x + self.vx*dt
    self.y = self.y + self.vy*dt
end

function EFFECT:draw()
    love.graphics.setColor(self.color)
    local f = self.frames
    love.graphics.draw(Effectimg, Effectquads[f.group][f.frames[f.frame]], self.x, self.y, 0, self.dirx, self.diry, 2, 2)
end