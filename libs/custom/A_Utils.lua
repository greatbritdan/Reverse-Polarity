-- MADE BY AIDAN
-- A_Utils - a small group of common support functions.

-- GENERAL --
function round(num)
    return math.floor(num+0.5)
end
function snap(num, by)
    return round(num/by)*by
end
function lerp(a, b, x, dt)
    return a + (b - a) * (1.0 - math.exp(-x * dt))
end
function aabb(ax, ay, awidth, aheight, bx, by, bwidth, bheight)
	return ax+awidth > bx and ax < bx+bwidth and ay+aheight > by and ay < by+bheight
end

-- MOUSE --
function getX()
    return math.floor(love.mouse.getX()/SCALE)
end
function getY()
    return math.floor(love.mouse.getY()/SCALE)
end
function getXY()
    return getX(), getY()
end

-- FONTS --
function newFont(name, path, glyphs, spacingx, spacingy)
    -- generate y spacing because love doens't have that lol
    local oid = love.image.newImageData(path)
    local id = love.image.newImageData(oid:getWidth(), oid:getHeight()+spacingy)
    id:paste(oid, 0, 0, 0, 0, oid:getWidth(), oid:getHeight())

    ENV.fonts[name] = { font=love.graphics.newImageFont(id, glyphs, spacingx), glyphs=glyphs, spacingx=spacingx, spacingy=spacingy }
    return name
end
function setFont(name)
    ENV.font = name
    love.graphics.setFont(ENV.fonts[name].font)
end
function getFontSpacing()
    return ENV.fonts[ENV.font].spacingy
end
function getFontGlyphs()
    return ENV.fonts[ENV.font].glyphs
end
function getFontWidth(text)
    return ENV.fonts[ENV.font].font:getWidth(text)
end
function getFontHeight()
    return ENV.fonts[ENV.font].font:getHeight()
end

-- IMAGES --
function loadsprites(path, xquads, yquads, xquadnames, yquadnames)
    local img = love.graphics.newImage(path .. ".png")
    if (xquads == 1 and yquads == 1) or ((not xquads) and (not yquads)) then
        return img, false
    end
    local imgw, imgh = img:getWidth(), img:getHeight()
    local quadw, quadh = imgw/xquads, imgh/yquads
    if quadw % 1 ~= 0 or quadh % 1 ~= 0 then
        return img, false
    end

    local quads = {}
    if yquads > 1 then
        if xquads > 1 then
            for x = 1, xquads do
                local xn = x
                if xquadnames and xquadnames[x] then
                    xn = xquadnames[x]
                end
                quads[xn] = {}
                for y = 1, yquads do
                    local yn = y
                    if yquadnames and yquadnames[y] then
                        yn = yquadnames[y]
                    end
                    quads[xn][yn] = love.graphics.newQuad((x-1)*quadw, (y-1)*quadh, quadw, quadh, imgw, imgh)
                end
            end
        else
            for y = 1, yquads do
                local yn = y
                if yquadnames and yquadnames[y] then
                    yn = yquadnames[y]
                end
                quads[yn] = love.graphics.newQuad(0, (y-1)*quadh, imgw, quadh, imgw, imgh)
            end
        end
    elseif xquads > 1 then
        for x = 1, xquads do
            local xn = x
            if xquadnames and xquadnames[x] then
                xn = xquadnames[x]
            end
            quads[xn] = love.graphics.newQuad((x-1)*quadw, 0, quadw, imgh, imgw, imgh)
        end
    end
    return img, quads
end

-- SAVE AND LOAD --

function loadsavefile(path, savequery)
    if not love.filesystem.getInfo(path .. ".json") then
        return false
    end
    savequery = savequery or ENV.savequery
    local json = love.filesystem.read(path .. ".json")
    local data = JSON:decode(json)
    for name, v in pairs(savequery) do
        if data[name] ~= nil then
            local newval = validatesavefileentry(v, data[name])
            if v.scope == "env" then
                ENV[v.var] = newval
            elseif v.scope == "global" then
                _G[v.var] = newval
            elseif v.scope == "global_table" and _G[v.var] and type(_G[v.var]) == "table" then
                _G[v.var][v.index] = newval
            end
        end
    end
end

function savesavefile(path, savequery)
    savequery = savequery or ENV.savequery
    local data = {}
    for name, v in pairs(savequery) do
        if v.scope == "env" and ENV[v.var] then
            data[name] = validatesavefileentry(v, ENV[v.var])
        elseif v.scope == "global" and (_G[v.var] ~= nil) then
            data[name] = validatesavefileentry(v, _G[v.var])
        elseif v.scope == "global_table" and _G[v.var] and _G[v.var][v.index] then
            data[name] = validatesavefileentry(v, _G[v.var][v.index])    
        end
        if data[name] == nil then
            data[name] = v.default
        end
    end
    local json = JSON:encode_pretty(data)
    love.filesystem.write(path .. ".json", json)
end

function validatesavefileentry(v, val)
    if v.type == "boolean" then
        if val == true or val == "true" then
            return true
        end
        return false
    elseif v.type == "number" then
        if type(val) == "number" then
            local min, max = v.min or -math.huge, v.max or math.huge
            val = math.min(math.max(min, val), max)
            if v.snap then
                val = snap(val, v.snap)
            end
            return val
        end
        return nil
    end
    return val
end

-- TYPES --
function tablecontains(table, name)
    for i = 1, #table do
        if table[i] == name then
            return i
        end
    end
    return false
end

function string:split(d)
	local data = {}
	local from, to = 1, string.find(self, d)
	while to do
		table.insert(data, string.sub(self, from, to-1))
		from = to+d:len()
		to = string.find(self, d, from)
	end
	table.insert(data, string.sub(self, from))
	return data
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- PRINT --
wnf_print = print
function print(...)
    local vals = {...}
    local outvals = {}
    for i, t in pairs(vals) do
        if type(t) == "table" then
            outvals[i] = tabletostring(t)
        elseif type(t) == "function" then
            outvals[i] = "function()"
        else
            outvals[i] = tostring(t)
        end
    end
    wnf_print(unpack(outvals))
end

function tabletostring(t)
    local array = true
    local ai = 0
    local outtable = {}
    for i, v in pairs(t) do
        if type(v) == "table" then
            outtable[i] = tabletostring(v)
        elseif type(v) == "function" then
            outtable[i] = "function()"
        else
            outtable[i] = tostring(v)
        end

        ai = ai + 1
        if t[ai] == nil then
            array = false
        end
    end
    local out = ""
    if array then
        out = "[" .. table.concat(outtable,",") .. "]"
    else
        for i, v in pairs(outtable) do
            out = string.format("%s%s: %s, ", out, i, v)
        end
        out = "{" .. out .. "}"
    end
    return out
end