P_PLAYER = Class("player", P_PHYSICSOBJ)

function P_PLAYER:initialize(map, x, y, sleeping, movementenabled, rotationenabled)
    P_PHYSICSOBJ.initialize(self, map, x, y, 12, 16)

    self.category = "player"
    self.mask = {player=true}

    self.startx, self.starty = self.x, self.y
    self.jumping = false
    self.falling = false

    self.movementenabled = movementenabled
    self.rotationenabled = rotationenabled

    self.gravity = 384
    self.maxspeedy = 256
    self.maxwalkspeed = 128
    self.acceleration = 256
    self.jumpspeed = 200
    self.idlefriction = 64
    self.walkfriction = 8
    self.skidfriction = 256

    self.frame, self.dir, self.vdir = 1, 1, 1
    self.rot, self.rotdir, self.rottimer = 0, false, 0

    self.idletimer = 0
    self.blinktimer = 0

    self.quadcenterx = 10
    self.quadcentery = 10
    self.quadoffsetx = 6
    self.quadoffsety = 6

    self.startgravity = self.gravity
    self.north = "up"
    self.south = reverseMagnet(self.north)

    self.range = 32
    self.checktable = {"cannonball"}

    self.dead, self.deadtimer = false, 0
    self.won, self.wondir, self.wontimer = false, false, 0
    if sleeping and (not SKIPCUTSCENE) then
        self.sleeping = sleeping
        if self.sleeping then
            self.sleeptimer, self.sleepstage, self.sleepframe, self.sleepcount = 0, "start", 2, 6
        end
    end
end

function P_PLAYER:getControls(move)
    return CONTROLS[move]
end

function P_PLAYER:update(dt)
    if self.dead then
        self.deadtimer = self.deadtimer + dt
        if self.deadtimer > 1 then
            self:respawn()
        end
        if self.vx > 0 then
            self.rot = self.rot - 12*dt
        else
            self.rot = self.rot + 12*dt
        end
        return
    end

    if self.won and self.won ~= true then
        if self.wondir == "bottom" then
            self.x = lerp(self.x, self.won.x+2, 3, dt)
            self.y = lerp(self.y, self.won.y+16, 3, dt)
        elseif self.wondir == "top" then
            self.x = lerp(self.x, self.won.x+2, 3, dt)
            self.y = lerp(self.y, self.won.y-16, 3, dt)
        elseif self.wondir == "left" then
            self.x = lerp(self.x, self.won.x-12, 3, dt)
            self.y = lerp(self.y, self.won.y+2, 3, dt)
        elseif self.wondir == "right" then
            self.x = lerp(self.x, self.won.x+12, 3, dt)
            self.y = lerp(self.y, self.won.y+2, 3, dt)
        end
        self.vx, self.vy, self.horfriction, self.gravity = 0, 0, 0, false
        self.blinktimer, self.idletimer = 0, 0

        if self.wontimer then
            self.wontimer = self.wontimer + dt
            if self.wontimer > 1.5 then
                Screen:changeState("menu", {"fade", 0.5, {0,0,0}}, {"fade", 0.5, {0,0,0}})
                self.wontimer = false
            end
        end
        return
    end

    if self.sleeping then
        if self.sleepstage == "waking" and self.sleeptimer == 0 then
            triggerAnim("text|intro|hide")
        end
        self.sleeptimer = self.sleeptimer + dt
        if self.sleepstage == "start" and self.sleeptimer > 2 then
            triggerAnim("text|intro|updatetext|wake up...\n( press <jump> to wake )")
            self.sleepstage = "wake"
        elseif self.sleepstage == "wake2" and self.sleeptimer > 1 then
            triggerAnim("text|intro|updatetext|hmm, try again...\n( press <jump> to wake )")
            self.sleepstage = "wake"
        elseif self.sleepstage == "waking" then
            if self.sleepframe == 2 and self.sleeptimer > 1 then
                self.sleepframe = 3
            elseif self.sleepframe == 3 and self.sleeptimer > 2 then
                self.sleepframe = 4
            elseif self.sleepframe == 4 and self.sleeptimer > 2.2 then
                self.sleeping = false
                triggerAnim("text|intro|updatetext|( hold <left> or <right> to walk )\n( press <jump> to jump )")
            end
        end
        return
    end

    if self.jumping and self.vy > 0 then
        self.jumping = false
        self.falling = true
    end

    -- movement
    if self.movementenabled then
        local left, right = love.keyboard.isDown(self:getControls("left")), love.keyboard.isDown(self:getControls("right"))
        if (left or right) and (not RANKS.enabled) then
            self:keypressed()
        end

        -- left and right
        if left and (not right) and self.vx > -self.maxwalkspeed then
            self.vx = self.vx - self.acceleration * dt
            if self.vx < 0 then self.dir = -1 end
        elseif right and (not left) and self.vx < self.maxwalkspeed then
            self.vx = self.vx + self.acceleration * dt
            if self.vx > 0 then self.dir = 1 end
        end

        -- terminal velocity
        self.vy = math.min(math.max(-self.maxspeedy, self.vy), self.maxspeedy)

        -- frick-tion
        if (left and self.vx < 0) or (right and self.vx > 0) then
            self.horfriction = self.walkfriction
        elseif (left or right) then
            self.horfriction = self.skidfriction
        else
            self.horfriction = self.idlefriction
        end

        if (left or right) and math.abs(self.vx) > 8 and (not Walksound:isPlaying()) and (not self.jumping) and (not self.falling) then
            Walksound:setPitch(math.random(9,11)/10)
            playsound(Walksound)
        end
    end

    -- animation
    self.blinktimer = self.blinktimer + dt
    local notwalking = true
    if self.rotdir then
        self.frame = 1
    elseif self.falling then
        self.frame = 4
    elseif self.jumping then
        self.frame = 3
    else
        self.idletimer = self.idletimer + dt
        self.frame = math.ceil((self.idletimer*2)%2) -- (frame 1 > 2, per 0.5 secs)
        notwalking = false
    end
    if notwalking then
        self.idletimer = 0
    end

    -- rotation
    if self.rottimer > 0 then
        if self.rotdir == 1 then
            self.rot = self.rot + (math.pi/2)*5*dt
            self.rottimer = self.rottimer - dt
            if self.rot > 0.5 and self.rottimer <= 0.1 then
                self.rot = self.rot - (math.pi/2)
                self.north = shiftRightMagnet(self.north)
                self.south = reverseMagnet(self.north)
                self:magnetchanged()
            end
        else
            self.rot = self.rot - (math.pi/2)*5*dt
            self.rottimer = self.rottimer - dt
            if self.rot < -0.5 and self.rottimer <= 0.1 then
                self.rot = self.rot + (math.pi/2)
                self.north = shiftLeftMagnet(self.north)
                self.south = reverseMagnet(self.north)
                self:magnetchanged()
            end
        end
    elseif self.rot ~= 0 then
        self.rot = 0
        self.rotdir = false
        if self.rotdirBuffer ~= nil then
            self:rotate(self.rotdirBuffer)
            self.rotdirBuffer = nil
        end
    end

    self:magnetupdate(dt)
end

function P_PLAYER:enteredmagnet(b, data)
    if data.movement == "up" or data.movement == "down" then
        self.gravity = 0
        self.falling = true
    else
        self.horfriction = false
    end
end
function P_PLAYER:passivemagnet(b, data)
    self.vdir, self.quadoffsety = 1, 6
    if data.surface == "bottom" and data.dir == "attract" then
        self.vdir, self.quadoffsety = -1, 10
    end
end
function P_PLAYER:exitedmagnet(b)
    self.vdir, self.quadoffsety = 1, 6
    if self.gravity == 0 then
        self.gravity = self.startgravity
    end
end

function P_PLAYER:draw()
    if self.sleeping then
        love.graphics.draw(Playerextraimg, Playerextraquads[self.sleepframe], self.x+self.quadoffsetx, self.y+self.quadoffsety, 0, 1, 1, self.quadcenterx, self.quadcentery)
        return
    end
    if self.dead then
        love.graphics.draw(Playerextraimg, Playerextraquads[1], self.x+self.quadoffsetx, self.y+self.quadoffsety, self.rot, 1, 1, self.quadcenterx, self.quadcentery)
        return
    end
    
    -- body
    love.graphics.draw(Playerimg, Playerquads[self.frame]["body"], self.x+self.quadoffsetx, self.y+self.quadoffsety, 0, 1, self.vdir, self.quadcenterx, self.quadcentery)

    -- head
    local set = self.north
    if self.wasnomagnet then
        set = "o_"..set
    end
    love.graphics.draw(Playerimg, Playerquads[self.frame][set], self.x+self.quadoffsetx, self.y+self.quadoffsety, self.rot, 1, 1, self.quadcenterx, self.quadcentery)

    -- eyes
    local set = "hor"
    if self.north ~= "up" and self.north ~= "down" then
        set = "ver"
    end
    if self.blinktimer%3 > 2.9 then
        set = "b_"..set
    end
    love.graphics.draw(Playerimg, Playerquads[self.frame][set], self.x+self.quadoffsetx, self.y+self.quadoffsety, self.rot, self.dir, 1, self.quadcenterx, self.quadcentery)
end

function P_PLAYER:floorcollide(a, b)
    if self.dead or a == "cannonball" then
        return false
    end

    if a == "spikes" then
        self:die()
        return false
    elseif (not self.inmagnet) and self.falling then
        neweffect("dustl", self.x+(self.w/2), self.y+self.h)
        neweffect("dustr", self.x+(self.w/2), self.y+self.h)
    end
    self.jumping = false
    self.falling = false
    return true
end
function P_PLAYER:ceilcollide(a, b)
    if self.dead or a == "cannonball" then
        return false
    end
    return true
end
function P_PLAYER:leftcollide(a, b)
    if self.dead or a == "cannonball" then
        return false
    end
    return true
end
function P_PLAYER:rightcollide(a, b)
    if self.dead or a == "cannonball" then
        return false
    end
    return true
end

--

function P_PLAYER:keypressed(key)
    if (not self.won) and (not self.sleeping) and (not RANKS.enabled) then
        RANKS.enabled = true
    end
end

function P_PLAYER:jump()
    if self.sleeping then
        if (self.sleepstage == "wake" or self.sleepstage == "wake2") and self.vy == 0 then
            self.sleepcount = self.sleepcount - 1
            if self.sleepcount <= 0 then
                self.sleeptimer = 0
                self.sleepstage = "waking"
                self.vy = -256
            else
                self.vy = -64
                if self.sleepcount == 5 then
                    self.sleeptimer = 0
                    self.sleepstage = "wake2"
                end
            end
            playsound(Clicksound)
        end
        return
    end
    if (not self.movementenabled) or self.dead then
        return
    end
    if (not self.jumping) and (not self.falling) then
        self.vy = -self.jumpspeed
        self.jumping = true
        playsound(Jumpsound)
    end
end
function P_PLAYER:stopjump()
    if (not self.movementenabled) or self.dead then
        return
    end
    -- holding jump will make you jump higher
    if self.vy < 0 then
        self.vy = self.vy/2
    end
end

function P_PLAYER:startfall()
    self.falling = true
end

function P_PLAYER:rotate(dir)
    if (not self.rotationenabled) or self.dead then
        return
    end

    if self.rotdir then
        self.rotdirBuffer = dir
        return
    end

    self.rotdir = dir
    self.rottimer = 0.2
    if self.gravity == 0 then
        self.gravity = self.startgravity
    end
    playsound(Rotatesound)
end

--

function P_PLAYER:die()
    if INVINCE then
        return
    end
    self.dead = true
    self.horfriction = false
    if self.gravity == 0 then
        self.gravity = self.startgravity
    end
    self.vx, self.vy = self.vx*(math.random(2,12)/10), -256
    self:magnetchanged()

    playsound(Deathsound)
    for i = 1, 8 do
        neweffect("spark", self.x+(self.w/2), self.y+(self.h/2))
    end
    if RANKS.enabled then
        RANKS.deaths = RANKS.deaths + 1
    end
end
function P_PLAYER:respawn()
    self.deadtimer = 0
    self:teleport(self.startx, self.starty)
end
function P_PLAYER:teleport(x, y)
    if self.sleeping then
        self.sleeping = false
    end
    if self.dead then
        self.dead, self.rot = false, 0
    end
    self.magnet = {}
    self.vx, self.vy, self.jumping, self.falling = 0, 0, false, false
    self.x, self.y = x, y
    self.map:cameraFocus(self, true)
end

function P_PLAYER:win(v, data)
    if v then
        self.won, self.wondir = v, data.surface -- I wonder...
    else
        self.won = true
    end

    RANKS.enabled = false
    if LEVELREACHED ~= "e" then
        if self.map.level == 3 then
            LEVELREACHED = "e"
        elseif self.map.level+1 > LEVELREACHED and LEVELREACHED < 3 then
            LEVELREACHED = self.map.level+1
        end
    end
    
    WON = true
    Gamemusic:stop()
    Menumusic:stop()
    playsound(Checkpointsound)

    local top = TOPRANKS[self.map.level]
    if top.time then
        if RANKS.time < top.time then
            top.time = RANKS.time
        end
    else
        top.time = RANKS.time
    end
    if top.deaths then
        if RANKS.deaths < top.deaths then
            top.deaths = RANKS.deaths
        end
    else
        top.deaths = RANKS.deaths
    end

    savesavefile("savefile")

    if not v then
        Leveltoload = "e"
        Screen:changeState("game", {"fade", 0.5, {0,0,0}}, {"fade", 0.5, {0,0,0}})
    end
end