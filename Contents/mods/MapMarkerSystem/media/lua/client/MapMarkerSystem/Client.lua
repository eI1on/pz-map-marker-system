local Logger = require("MapMarkerSystem/Logger");
local FileUtils = require("ElyonLib/FileUtils");

local getTexture = getTexture;

local MapMarkerSystem = require("MapMarkerSystem/Shared");
local MapMarkerManager = require("MapMarkerSystem/MapMarkerManager");

MapMarkerSystem.Client = {};
MapMarkerSystem.Client.ClientCommands = {};

local textureCache = {};

local function getCachedTexture(texturePath)
    if not textureCache[texturePath] then
        local texture = getTexture(texturePath);
        if not texture then return nil; end
        textureCache[texturePath] = texture;
    end
    return textureCache[texturePath];
end


local MIN_ZOOM_SCALE = 360.03494;
local MAX_ZOOM_SCALE = 0.043949578;
local LOG_MIN_SCALE = 2.55634464941;  -- precomputed math.log(MIN_ZOOM_SCALE)
local LOG_MAX_SCALE = -1.35704529063; -- precomputed math.log(MAX_ZOOM_SCALE)
local LOG_SCALE_RANGE = LOG_MAX_SCALE - LOG_MIN_SCALE;

local zoomCache = {};
function MapMarkerSystem.normalizeZoomScale(worldScale)
    if zoomCache[worldScale] then return zoomCache[worldScale]; end
    local logCurrentScale = math.log(worldScale);
    local normalizedZoom = math.floor(
        ((logCurrentScale - LOG_MIN_SCALE) / LOG_SCALE_RANGE) * 100
    );
    normalizedZoom = (normalizedZoom < 0) and 0 or ((normalizedZoom > 100) and 100 or normalizedZoom);
    zoomCache[worldScale] = normalizedZoom;
    return normalizedZoom;
end

function MapMarkerSystem.calculateScaledMarkerSize(worldScale, baseScale)
    local THRESHOLD_SCALE = 0.2;
    local MULTIPLIER_FACTOR = 0.1;
    local targetScale = (worldScale <= THRESHOLD_SCALE) and worldScale or
        (THRESHOLD_SCALE + (worldScale * MULTIPLIER_FACTOR - THRESHOLD_SCALE) * MULTIPLIER_FACTOR);
    return baseScale * targetScale;
end

---@param self ISWorldMap|ISMiniMapInner
---@param marker table
function MapMarkerSystem.renderTextureMarker(self, marker)
    local api = self.javaObject:getAPI();
    if not api then return; end

    local texture = getCachedTexture(marker.texturePath);
    if not texture then return; end

    local worldScale = api:getWorldScale();
    local zoomLevel = MapMarkerSystem.normalizeZoomScale(worldScale);

    if zoomLevel > marker.maxZoomLevel then return; end

    local uiX = api:worldToUIX(marker.coordinates.center.x, marker.coordinates.center.y);
    local uiY = api:worldToUIY(marker.coordinates.center.x, marker.coordinates.center.y);

    local markerSize = marker.lockZoom and marker.scale or
        MapMarkerSystem.calculateScaledMarkerSize(worldScale, marker.scale);

    self:setStencilRect(0, 0, self.width, self.height);
    self:drawTextureScaledAspect(texture, uiX - markerSize * 0.5, uiY - markerSize * 0.5, markerSize, markerSize, 0.9,
        0.9, 0.9, 0.9);
    self:clearStencilRect();
end

---@param self ISWorldMap|ISMiniMapInner
---@param marker table
function MapMarkerSystem.renderAreaMarker(self, marker)
    if not self.javaObject then return; end
    local api = self.javaObject:getAPI();
    if not api then return; end

    local worldScale = api:getWorldScale();
    local zoomLevel = MapMarkerSystem.normalizeZoomScale(worldScale);

    if zoomLevel > marker.maxZoomLevel then return; end

    local nwX, nwY = marker.coordinates.nw.x, marker.coordinates.nw.y;
    local seX, seY = marker.coordinates.se.x, marker.coordinates.se.y;

    local neX, neY = seX, nwY;
    local swX, swY = nwX, seY;

    local uiNWX, uiNWY = api:worldToUIX(nwX, nwY), api:worldToUIY(nwX, nwY);
    local uiNEX, uiNEY = api:worldToUIX(neX, neY), api:worldToUIY(neX, neY);
    local uiSWX, uiSWY = api:worldToUIX(swX, swY), api:worldToUIY(swX, swY);
    local uiSEX, uiSEY = api:worldToUIX(seX, seY), api:worldToUIY(seX, seY);

    local absX, absY = self:getAbsoluteX(), self:getAbsoluteY();
    uiNWX, uiNWY = uiNWX + absX, uiNWY + absY;
    uiNEX, uiNEY = uiNEX + absX, uiNEY + absY;
    uiSWX, uiSWY = uiSWX + absX, uiSWY + absY;
    uiSEX, uiSEY = uiSEX + absX, uiSEY + absY;

    local function drawLine(x1, y1, x2, y2, r, g, b, a)
        local thickness = 5;
        local dx, dy = x2 - x1, y2 - y1;
        local angle = math.atan2(dy, dx);

        local offsetX = math.sin(angle) * thickness / 2;
        local offsetY = math.cos(angle) * thickness / 2;

        local x1Top, y1Top = x1 + offsetX, y1 - offsetY;
        local x1Bottom, y1Bottom = x1 - offsetX, y1 + offsetY;
        local x2Top, y2Top = x2 + offsetX, y2 - offsetY;
        local x2Bottom, y2Bottom = x2 - offsetX, y2 + offsetY;

        self.javaObject:DrawTexture(nil, x1Top, y1Top, x2Top, y2Top, x2Bottom, y2Bottom, x1Bottom, y1Bottom, r, g, b, a);
    end

    self:setStencilRect(0, 0, self.width, self.height);
    if marker.name then
        self:drawText(marker.name, uiNWX + 10, uiNWY - 15, 0, 0, 0, 1, UIFont.Small);
    end

    drawLine(uiNWX, uiNWY, uiNEX, uiNEY, marker.color.r, marker.color.g, marker.color.b, 1);
    drawLine(uiNEX, uiNEY, uiSEX, uiSEY, marker.color.r, marker.color.g, marker.color.b, 1);
    drawLine(uiSEX, uiSEY, uiSWX, uiSWY, marker.color.r, marker.color.g, marker.color.b, 1);
    drawLine(uiSWX, uiSWY, uiNWX, uiNWY, marker.color.r, marker.color.g, marker.color.b, 1);
    self:clearStencilRect();
end

---@param self ISWorldMap|ISMiniMapInner
---@param marker table
function MapMarkerSystem.renderRectangleMarker(self, marker)
    local api = self.javaObject:getAPI();
    if not api then return; end

    local worldScale = api:getWorldScale();
    local zoomLevel = MapMarkerSystem.normalizeZoomScale(worldScale);

    if zoomLevel > marker.maxZoomLevel then return; end

    local uiX = api:worldToUIX(marker.coordinates.center.x, marker.coordinates.center.y);
    local uiY = api:worldToUIY(marker.coordinates.center.x, marker.coordinates.center.y);

    local markerWidth, markerHeight;
    if marker.lockZoom then
        markerWidth = marker.coordinates.width * marker.scale;
        markerHeight = marker.coordinates.height * marker.scale;
    else
        local targetScale = MapMarkerSystem.calculateScaledMarkerSize(worldScale, marker.scale);
        markerWidth = marker.coordinates.width * targetScale;
        markerHeight = marker.coordinates.height * targetScale;
    end

    local halfWidth = markerWidth / 2;
    local halfHeight = markerHeight / 2;

    local borderColor = {
        r = math.max(0, marker.color.r - 0.3),
        g = math.max(0, marker.color.g - 0.3),
        b = math.max(0, marker.color.b - 0.3)
    };

    self:setStencilRect(0, 0, self.width, self.height);
    self:drawRect(uiX - halfWidth, uiY - halfHeight, markerWidth, markerHeight, marker.color.a, marker.color.r,
        marker.color.g, marker.color.b);
    self:drawRectBorder(uiX - halfWidth, uiY - halfHeight, markerWidth, markerHeight, 1, borderColor.r, borderColor.g, borderColor.b);
    if marker.name then
        local textHeight = getTextManager():MeasureStringY(UIFont.Small, marker.name);
        self:drawText(marker.name, uiX + halfWidth + 5, uiY - textHeight / 2, 0, 0, 0, 1, UIFont.Small);
    end
    self:clearStencilRect();
end

MapMarkerSystem.ISWorldMap_prerender = ISWorldMap.prerender;
function ISWorldMap:prerender()
    local markers = MapMarkerSystem.MapMarkers;
    if markers then
        for i = 1, #markers do
            local marker = markers[i];
            if marker.isEnabled then
                if marker.markerType == "texture" then
                    MapMarkerSystem.renderTextureMarker(self, marker)
                elseif marker.markerType == "rectangle" then
                    MapMarkerSystem.renderRectangleMarker(self, marker)
                elseif marker.markerType == "area" then
                    MapMarkerSystem.renderAreaMarker(self, marker)
                end
            end
        end
    end
    MapMarkerSystem.ISWorldMap_prerender(self)
end

MapMarkerSystem.ISMiniMapInner_prerender = ISMiniMapInner.prerender;
function ISMiniMapInner:prerender()
    local markers = MapMarkerSystem.MapMarkers;
    if markers then
        for i = 1, #markers do
            local marker = markers[i];
            if marker.isEnabled then
                if marker.markerType == "texture" then
                    MapMarkerSystem.renderTextureMarker(self, marker);
                elseif marker.markerType == "rectangle" then
                    MapMarkerSystem.renderRectangleMarker(self, marker);
                elseif marker.markerType == "area" then
                    MapMarkerSystem.renderAreaMarker(self, marker);
                end
            end
        end
    end
    MapMarkerSystem.ISMiniMapInner_prerender(self);
end

local doCommand = false;
local function sendCommand()
    if doCommand then
        MapMarkerSystem.MapMarkers = MapMarkerSystem.Shared.RequestMarkers();
        Events.OnTick.Remove(sendCommand);
    end
    doCommand = true;
end
Events.OnTick.Add(sendCommand);


function MapMarkerSystem.Client.ClientCommands.LoadMapMarkers(args)
    if type(args) ~= "table" then args = {}; end
    MapMarkerSystem.MapMarkers = args;

    if MapMarkerManager.instance then
        MapMarkerManager.instance:populateMarkersList(args);
    end
end

function MapMarkerSystem.Client.ClientCommands.onServerCommand(module, command, args)
    if module ~= "MapMarkerSystem" then return; end
    if MapMarkerSystem.Client.ClientCommands[command] then
        MapMarkerSystem.Client.ClientCommands[command](args);
    end
end

Events.OnServerCommand.Add(MapMarkerSystem.Client.ClientCommands.onServerCommand);
