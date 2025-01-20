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

function MapMarkerSystem.render(self, scale, texturePath, x, y)
    local api = self.javaObject:getAPI();
    if api then
        local texture = getCachedTexture(texturePath);
        if not texture then return; end

        local uiX = api:worldToUIX(x, y);
        local uiY = api:worldToUIY(x, y);
        local worldScale = api:getWorldScale();
        local thresholdScale = 0.2;
        local multiplierFactor = 0.1;
        local targetScale = (worldScale <= thresholdScale) and worldScale or
            (thresholdScale + (worldScale * multiplierFactor - thresholdScale) * multiplierFactor);
        local markerSize = scale * targetScale;

        self:setStencilRect(0, 0, self.width, self.height);
        self:drawTextureScaledAspect(texture, uiX - markerSize * 0.5, uiY - markerSize * 0.5, markerSize, markerSize, 0.9,
            0.9, 0.9, 0.9);
        self:clearStencilRect();
    end
end

MapMarkerSystem.ISWorldMap_prerender = ISWorldMap.prerender;
---@diagnostic disable-next-line: duplicate-set-field
function ISWorldMap:prerender()
    local markers = MapMarkerSystem.MapMarkers;
    if markers then
        for i = 1, #markers do
            local marker = markers[i];
            if marker.isEnabled then
                MapMarkerSystem.render(self, marker.scale, marker.texturePath, marker.coordinates.x,
                    marker.coordinates.y);
            end
        end
    end
    MapMarkerSystem.ISWorldMap_prerender(self);
end

MapMarkerSystem.ISMiniMapInner_prerender = ISMiniMapInner.prerender;
function ISMiniMapInner:prerender()
    local markers = MapMarkerSystem.MapMarkers;
    if markers then
        for i = 1, #markers do
            local marker = markers[i];
            if marker.isEnabled then
                MapMarkerSystem.render(self, marker.scale - 100, marker.texturePath, marker.coordinates.x,
                    marker.coordinates.y);
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
