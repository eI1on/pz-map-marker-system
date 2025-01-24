local Globals = require("Starlit/Globals");
local Logger = require("MapMarkerSystem/Logger");

local MapMarkerSystem = require("MapMarkerSystem/Shared");
MapMarkerSystem.Server = {};
MapMarkerSystem.Server.ServerCommands = {};


--------------------------------------------------
-- LOGGING ACTIONS ON SERVER
--------------------------------------------------
function MapMarkerSystem.Server.writeLog(packet)
    writeLog(packet.loggerName, packet.logText);
end

local function formatMarkerInfo(marker)
    local info = string.format("[Name: %s] [Type: %s] [Enabled: %s]",
        marker.name or "N/A",
        marker.markerType or "N/A",
        marker.isEnabled and "Yes" or "No"
    );

    if marker.coordinates then
        if marker.markerType == "texture" then
            info = info .. string.format(" [Center: (%d, %d)] [Scale: %d] [Texture: %s]",
                marker.coordinates.center.x or "-1",
                marker.coordinates.center.y or "-1",
                marker.scale or 1,
                marker.texturePath or "N/A"
            );
        elseif marker.markerType == "rectangle" then
            info = info .. string.format(" [Center: (%d, %d)] [Width: %d] [Height: %d]",
                marker.coordinates.center.x or "-1",
                marker.coordinates.center.y or "-1",
                marker.coordinates.width or "0",
                marker.coordinates.height or "0"
            );
        elseif marker.markerType == "area" then
            info = info .. string.format(" [NW: (%d, %d)] [SE: (%d, %d)]",
                marker.coordinates.nw.x or "-1",
                marker.coordinates.nw.y or "-1",
                marker.coordinates.se.x or "-1",
                marker.coordinates.se.y or "-1"
            );
        end
    end

    return info;
end

--------------------------------------------------
-- PUSHING UPDATES TO CLIENTS
--------------------------------------------------
function MapMarkerSystem.Server.PushUpdateToAll(mapMarkers)
    if Globals.isServer then
        sendServerCommand("MapMarkerSystem", "LoadMapMarkers", mapMarkers);
    else
        MapMarkerSystem.MapMarkers = mapMarkers;
    end
end

function MapMarkerSystem.Server.PushUpdateToPlayer(player, mapMarkers)
    if Globals.isServer then
        sendServerCommand(player, "MapMarkerSystem", "LoadMapMarkers", mapMarkers);
    else
        MapMarkerSystem.MapMarkers = mapMarkers;
    end
end

--------------------------------------------------
-- SERVER COMMAND HANDLERS
--------------------------------------------------
function MapMarkerSystem.Server.ServerCommands.LoadMapMarkers(player, args)
    local mapMarkers = MapMarkerSystem.Shared.RequestMarkers();
    if args.toAll then
        MapMarkerSystem.Server.PushUpdateToAll(mapMarkers);
    else
        MapMarkerSystem.Server.PushUpdateToPlayer(player, mapMarkers);
    end
end

---@param player IsoPlayer
---@param args table
function MapMarkerSystem.Server.ServerCommands.AddMapMarker(player, args)
    local mapMarkers = MapMarkerSystem.Shared.RequestMarkers();
    local newMapMarker = args.newMapMarker;
    table.insert(mapMarkers, newMapMarker);
    MapMarkerSystem.Server.PushUpdateToAll(mapMarkers);

    local logText = string.format(
        "[Admin: %s] [SteamID: %s] [Role: %s] Added Marker: %s",
        tostring(player:getUsername() or "Unknown"),
        tostring(player:getSteamID() or "0"),
        tostring(player:getAccessLevel() or "None"),
        tostring(formatMarkerInfo(newMapMarker))
    );
    MapMarkerSystem.Server.writeLog({ loggerName = "admin", logText = logText });
end

function MapMarkerSystem.Server.ServerCommands.RemoveMapMarker(player, args)
    local mapMarkers = MapMarkerSystem.Shared.RequestMarkers();
    local selectedIdx = args.selectedIdx;
    local removedMarker = table.remove(mapMarkers, selectedIdx);
    MapMarkerSystem.Server.PushUpdateToAll(mapMarkers);

    local logText = string.format(
        "[Admin: %s] [SteamID: %s] [Role: %s] Removed Marker: %s",
        tostring(player:getUsername() or "Unknown"),
        tostring(player:getSteamID() or "0"),
        tostring(player:getAccessLevel() or "None"),
        tostring(formatMarkerInfo(removedMarker))
    )
    MapMarkerSystem.Server.writeLog({ loggerName = "admin", logText = logText })
end

-- Edit zone data
local function navigateOrCreateTable(tbl, path)
    local current = tbl;
    for key in string.gmatch(path or "", "([^%.]+)") do
        if not current[key] then current[key] = {}; end
        current = current[key];
    end
    return current;
end

function MapMarkerSystem.Server.ServerCommands.EditMarkerData(player, args)
    local mapMarkers = MapMarkerSystem.Shared.RequestMarkers();

    local dataSelected = args.selectedIdx;
    local selectedMapMarker = mapMarkers[dataSelected];
    local newKey = args.newKey;
    local newValue = args.newValue;

    if not selectedMapMarker then
        Logger:error("selectedMapMarker not found dataSelected = %s", dataSelected);
        return;
    end

    local parentTablePath, finalKey = string.match(newKey, "^(.*)%.([^%.]+)$");
    local modifying = parentTablePath and navigateOrCreateTable(selectedMapMarker, parentTablePath) or selectedMapMarker;

    if not modifying then
        Logger:error("Could not find the table to modify: selectedMapMarker = %s, parentTablePath = %s",
            selectedMapMarker, parentTablePath);
        return;
    end

    local modifyingKey = finalKey or newKey;

    if newValue == nil then
        if modifying[modifyingKey] ~= nil then
            modifying[modifyingKey] = nil;
        end
    else
        modifying[modifyingKey] = tonumber(newValue) or newValue;
    end

    MapMarkerSystem.Server.PushUpdateToAll(mapMarkers);

    if newKey == "isEnabled" then
        local logText = string.format(
            "[Admin: %s] [SteamID: %s] [Role: %s] Updated Marker: %s [Updated Field: %s -> %s]",
            tostring(player:getUsername() or "Unknown"),
            tostring(player:getSteamID() or "0"),
            tostring(player:getAccessLevel() or "None"),
            tostring(formatMarkerInfo(selectedMapMarker)),
            tostring(newKey or "nil"),
            tostring(newValue or "nil")
        );
        MapMarkerSystem.Server.writeLog({ loggerName = "admin", logText = logText });
    end
end

function MapMarkerSystem.Server.onClientCommand(module, command, player, args)
    if module ~= "MapMarkerSystem" then return; end
    if MapMarkerSystem.Server.ServerCommands[command] then
        MapMarkerSystem.Server.ServerCommands[command](player, args);
    end
end

Events.OnClientCommand.Add(MapMarkerSystem.Server.onClientCommand);
