-- MADE BY AIDAN
-- A_Map - a lightweight, simple map loading and updating system.
-- Requires: A_Utils

Map = Class("_map")
local sti = require("libs/sti")

function Map:loadMap(path, objloadfunc)
    -- loads the map
    local map = sti(ENV.mapspath .. "/" .. path .. ".lua")

    -- map and camera
    self.map = map
    MAPWIDTH, MAPHEIGHT = map.width, map.height
    if Camera then
        self.camera = Camera:new()
        self.camera:setBounds(0, 0, MAPWIDTH*16, MAPHEIGHT*16)
    end

    self.objloadfunc = objloadfunc

    -- load layers
    local rawtiledata = {}
    self.tilelayers, self.tiles, self.tileproperties = {}, {}
    self.objectlayers, self.objects, self.unloadedobjects = {}, {}, {}
    self.imagelayers, self.images = {}, {}
    for li, layer in ipairs(map.layers) do
        if layer.visible then
            local name = layer.class
            if layer.type == "tilelayer" then -- tiles
                table.insert(self.tilelayers, name)
                rawtiledata[name] = deepcopy(layer.data)

            elseif layer.type == "objectgroup" then -- objects
                table.insert(self.objectlayers, name)
                for i, obj in pairs(layer.objects) do
                    if obj.visible then
                        self:spawnObject(obj)
                    end
                end 

            elseif layer.type == "imagelayer" then -- images (back/foregrounds)
                table.insert(self.imagelayers, name)
                self.images[name] = { layers={}, scrollfactor=1 }
                for i, v in pairs(love.filesystem.getDirectoryItems(ENV.backgroundspath .. "/" .. layer.properties.filename)) do
                    local img = love.graphics.newImage(ENV.backgroundspath .. "/" .. layer.properties.filename .. "/" .. v)
                    table.insert(self.images[name].layers, {img=img, batch={}})
                end
                if layer.properties.scrollfactor then
                    self.images[name].scrollfactor = layer.properties.scrollfactor
                end

            end
        end
    end

    -- load tilesets
    self.tilesetnames, self.tilesets = {}, {}
    for ti, tileset in pairs(map.tilesets) do
        local name = tileset.name
        table.insert(self.tilesetnames, name)
        
        local img, quads, count, size = self:loadTiles(ENV.tilespath .. "/" .. name .. ".png")
        self.tilesets[name] = {img=img, quads=quads, count=count, size=size, first=tileset.firstgid, batches={}}
        for li, layer in pairs(self.tilelayers) do
            self.tilesets[name].batches[layer] = {}
        end
    end

    -- set tiles
    for y = 1, MAPHEIGHT do
        self.tiles[y] = {}
        for x = 1, MAPWIDTH do
            self.tiles[y][x] = {}
            for li, layer in pairs(self.tilelayers) do
                local tile = rawtiledata[layer][y][x]
                if tile then
                    self:setTileG(x, y, layer, tile.gid)
                end
            end 
        end
    end

    -- generate spritebatch
    self:truegenerateSpritebatch()
end

function Map:update()
    if self.queuespritebatchupdate then
        self:truegenerateSpritebatch()
    end
end

-- draw --

function Map:drawTiles(layer)
    for ti, tileset in pairs(self.tilesetnames) do
        love.graphics.draw(self.tilesets[tileset].batches[layer], 0, 0)
    end
end
function Map:drawEntitiesColl()
    for g, _ in pairs(self.objects) do
        for i, v in pairs(self.objects[g]) do
            if v.x and v.y and v.w and v.h then
                love.graphics.rectangle("line", v.x, v.y, v.w, v.h)
            end
            if v.rx and v.ry and v.rw and v.rh then
                love.graphics.rectangle("line", v.rx, v.ry, v.rw, v.rh)
            end
        end
    end
end
function Map:drawImages(name)
    if not self.images[name] then return end
    local xscroll, yscroll = self:getCameraScroll()

    local image = self.images[name]
    for idx = 1, #image.layers do
        local bgw, bgh = image.layers[idx].img:getWidth(), image.layers[idx].img:getHeight()
        for ix = 1, math.ceil(WIDTH/bgw)+1 do
            for iy = 1, math.ceil(HEIGHT/bgh)+1 do
                -- idk what this does, it just works
                love.graphics.draw(image.layers[idx].img, ((xscroll+(math.floor(xscroll/bgw)*bgw))/(idx*image.scrollfactor+1))+((ix-1)*bgw), yscroll+((iy-1)*bgh))
            end
        end
    end
end

-- tiles --

function Map:loadTiles(path)
    local img = love.graphics.newImage(path)
    local imgw, imgh = img:getWidth(), img:getHeight()
    local xquads, yquads = imgw/16, imgh/16
    local quads = {}
    for y = 1, yquads do
        for x = 1, xquads do
            table.insert(quads, love.graphics.newQuad((x-1)*16, (y-1)*16, 16, 16, imgw, imgh))
        end
    end
    return img, quads, xquads*yquads, {xquads, yquads}
end

function Map:clearTile(x, y, layer)
    self.tiles[y][x][layer] = nil
end
function Map:setTile(x, y, layer, tilesetname, id)
    self.tiles[y][x][layer] = self.tilesets[tilesetname].first + id - 1
end
function Map:getTile(x, y, layer) -- returns tilesetname, local id
    local gid = self.tiles[y][x][layer]
    if not gid then
        return false, false
    end
    for ti, tileset in pairs(self.tilesets) do
        if tileset.first+tileset.count-1 >= gid then
            return ti, (tileset.first+tileset.count-1) - gid
        end
    end
end
function Map:setTileG(x, y, layer, id)
    self.tiles[y][x][layer] = id
end
function Map:getTileG(x, y, layer)
    return self.tiles[y][x][layer]
end

function Map:generateSpritebatch()
    self.queuespritebatchupdate = true
end
function Map:truegenerateSpritebatch()
    for ti, tileset in pairs(self.tilesetnames) do
        for li, layer in pairs(self.tilelayers) do
            self.tilesets[tileset].batches[layer] = love.graphics.newSpriteBatch(self.tilesets[tileset].img, MAPWIDTH*MAPHEIGHT)
        end
    end

    -- Ahh yes, fine pasta!
    for y = 1, MAPHEIGHT do
        for x = 1, MAPWIDTH do
            for ti, tileset in pairs(self.tilesetnames) do
                for li, layer in pairs(self.tilelayers) do
                    if self.tiles[y][x][layer] then
                        local i = self.tiles[y][x][layer] - self.tilesets[tileset].first + 1
                        if i > 0 and i <= self.tilesets[tileset].count then
                            self.tilesets[tileset].batches[layer]:add(self.tilesets[tileset].quads[i], (x-1)*16, (y-1)*16)
                        end
                    end
                end
            end
        end
    end

    self.queuespritebatchupdate = false
end

-- camera --

function Map:cameraFocus(target, force, dt)
    if not Camera then
        return
    end
    if force then
        self.camera:forcefocus(target.x, target.y, target.w, target.h)
    else
        self.camera:focus(target.x, target.y, target.w, target.h, dt)
    end
end

function Map:getCameraScroll()
    local xscroll, yscroll = 0, 0
    if self.camera then
        xscroll, yscroll = self.camera.x, self.camera.y
    elseif self.xscroll or self.yscroll then
        xscroll, yscroll = self.xscroll or 0, self.yscroll or 0
    end
    return xscroll, yscroll
end
function Map:getCameraView()
    local x, y, w, h = 0, 0, 0, 0
    if self.camera then
        x, y, w, h = self.camera.bx, self.camera.by, self.camera.bw, self.camera.bh
    elseif self.xscroll or self.yscroll then
        x, y, w, h = self.boundx or 0, self.boundy or 0, self.boundw or 0, self.boundh or 0
    end
    return x, y, w, h
end

function Map:onScreen(x, y, w, h, wl, hl) -- width leneacny, height leneancy
    wl, hl = wl or 0, hl or 0
    local xscroll, yscroll = self:getCameraScroll()
	return (x+w+wl >= xscroll and y+h+hl >= yscroll and x-wl <= xscroll+WIDTH and y-hl <= yscroll+HEIGHT)
end

function Map:onCamera(x, y, w, h, wl, hl) -- width leneacny, height leneancy
    wl, hl = wl or 0, hl or 0
    local xscroll, yscroll = self:getCameraScroll()
    local bx, by, bw, bh = self:getCameraView()
	return (x+w+wl >= xscroll and y+h+hl >= yscroll and x-wl <= xscroll+bw and y-hl <= yscroll+bh)
end

-- etc --

function Map:worldToTile(x, y)
    return math.ceil(x/16), math.ceil(y/16), math.ceil((x/16)-1)*16, math.ceil((y/16)-1)*16
end
function Map:objectToTile(x, y)
    return math.ceil((x/16)+1), math.ceil((y/16)+1)
end

function Map:spawnObject(obj, x, y, etc) -- obj or name
    local objgroup, objc
    if type(obj) == "string" then
        local visible = etc.visible or true
        obj = {class=obj, x=x, y=y, width=etc.w, height=etc.h, properties=etc, visible=visible}
    end

    objgroup, objc, unloaded = self.objloadfunc(obj)
    if objgroup and objc then
        if not self.objects[objgroup] then
            self.objects[objgroup] = {}
        end
        table.insert(self.objects[objgroup], objc)
        return objc
    end
    return false
end