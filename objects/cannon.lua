P_CANNON = Class("cannon", P_PHYSICSOBJ)

function P_CANNON:initialize(map, x, y, dir, speed, oneside, dontdisable)
    P_PHYSICSOBJ.initialize(self, map, x, y, 16, 16, {static=true})

    self.category = "cannonball"
    self.mask = {cannonball=true}

    self.speed = speed or 32
    self.dir = dir
    self.oneside = oneside
    self.dontdisable = dontdisable or false

    self.delaytimer = 0
end

function P_CANNON:update(dt)
    if self.disable or self.shot or (not self.map:onCamera(self.x, self.y, self.w, self.h, 16, 16)) then
        return
    end
    if self.delaytimer >= 1 then
        playsound(Cannonsound)
        local cannonball = self.map:spawnObject("cannonball", self.x+3, self.y+3, {speed=self.speed, dir=self.dir, oneside=self.oneside})
        if self.dir == "up" then
            neweffect("dustl", self.x+(self.w/2), self.y)
            neweffect("dustr", self.x+(self.w/2), self.y)
        elseif self.dir == "down" then
            neweffect("dustl", self.x+(self.w/2), self.y+self.h)
            neweffect("dustr", self.x+(self.w/2), self.y+self.h)
        elseif self.dir == "left" then
            neweffect("dustu", self.x, self.y+(self.h/2))
            neweffect("dustd", self.x, self.y+(self.h/2))
        elseif self.dir == "right" then
            neweffect("dustu", self.x+self.w, self.y+(self.h/2))
            neweffect("dustd", self.x+self.w, self.y+(self.h/2))
        end
        cannonball.parent = self
        self.shot = true
    else
        self.delaytimer = self.delaytimer + dt
    end
end

function P_CANNON:draw()
    love.graphics.draw(Cannonimg, Cannonquads[self.dir], self.x, self.y)
end

function P_CANNON:childkilled(disable)
    if disable and (not self.dontdisable) then
        self.disable = true
    end
    self.shot = false
    self.delaytimer = 0
end

P_CANNONBALL = Class("cannonball", P_PHYSICSOBJ)

function P_CANNONBALL:initialize(map, x, y, dir, speed, oneside)
    P_PHYSICSOBJ.initialize(self, map, x, y, 10, 10)

    self.category = "cannonball"
    self.mask = {cannon=true}

    self.gravity = 0
    self.maxspeed = speed or 32
    self.dir = dir
    self:updatespeed()

    self.north = "none"
    self.south = "none"
    if oneside == "north" then
        self.north = "all"
    elseif oneside == "south" then
        self.south = "all"
    end

    self.autodelete = 64
end

function P_CANNONBALL:updatespeed()
    self.vx, self.vy = 0, 0
    if self.dir == "up" then
        self.vy = -self.maxspeed
    elseif self.dir == "down" then
        self.vy = self.maxspeed
    elseif self.dir == "left" then
        self.vx = -self.maxspeed
    elseif self.dir == "right" then
        self.vx = self.maxspeed
    end
end

function P_CANNONBALL:update()
    self.vx = math.min(math.max(-self.maxspeed, self.vx), self.maxspeed)
    self.vy = math.min(math.max(-self.maxspeed, self.vy), self.maxspeed)
end

function P_CANNONBALL:draw()
    local i = 1
    if self.north == "all" then i = 2 end
    if self.south == "all" then i = 3 end
    love.graphics.draw(Cannonballimg, Cannonballquads[i], self.x-1, self.y-1)
end

function P_CANNONBALL:collide(a, b, side)
    if a == "player" and (not b.dead) then
        b:die()
    end
    if a == "ground" or a == "magnet" or a == "spikes" then
        self:die()
    end
end
function P_CANNONBALL:leftcollide(a, b)
    self:collide(a, b, "left")
    if a == "player" then
        return false
    end
    return true
end
function P_CANNONBALL:rightcollide(a, b)
    self:collide(a, b, "right")
    if a == "player" then
        return false
    end
    return true
end
function P_CANNONBALL:floorcollide(a, b)
    self:collide(a, b, "floor")
    if a == "player" then
        return false
    end
    return true
end
function P_CANNONBALL:ceilcollide(a, b)
    self:collide(a, b, "ceil")
    if a == "player" then
        return false
    end
    return true
end

function P_CANNONBALL:autodeleted()
    self:die(true)
end

function P_CANNONBALL:die(silent)
    if not silent then
        playsound(Hitsound)
        neweffect("brickl", self.x+3, self.y+3)
        neweffect("brickl", self.x+3, self.y+3)
        neweffect("brickr", self.x+9, self.y+9)
        neweffect("brickr", self.x+9, self.y+9)
    end
    if self.parent then
        self.parent:childkilled(self.disable)
    end
    self._delete = true
end

function P_CANNONBALL:passivemagnet(b, data)
    self.horfriction, self.verfriction = false, false
    if data.movement == "up" or data.movement == "down" then
        self.horfriction = self.maxspeed*2.5
    else
        self.verfriction = self.maxspeed*2.5
    end
    self.dir = data.movement
end
function P_CANNONBALL:exitedmagnet(b)
    self:updatespeed() -- makes sure speed is always max speed when exiting a magnet
end