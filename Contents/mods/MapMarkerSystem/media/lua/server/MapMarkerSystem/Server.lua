local Globals = require("Starlit/Globals");
local Logger = require("MapMarkerSystem/Logger");

local MapMarkerSystem = require("MapMarkerSystem/Shared");
MapMarkerSystem.Server = {};
MapMarkerSystem.Server.ServerCommands = {};


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

function MapMarkerSystem.Server.ServerCommands.AddMapMarker(player, args)
    local mapMarkers = MapMarkerSystem.Shared.RequestMarkers();
    local newMapMarker = args.newMapMarker;
    table.insert(mapMarkers, newMapMarker);
    MapMarkerSystem.Server.PushUpdateToAll(mapMarkers);
end

function MapMarkerSystem.Server.ServerCommands.RemoveMapMarker(player, args)
    local mapMarkers = MapMarkerSystem.Shared.RequestMarkers();
    local selectedIdx = args.selectedIdx;
    table.remove(mapMarkers, selectedIdx);
    MapMarkerSystem.Server.PushUpdateToAll(mapMarkers);
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
end

function MapMarkerSystem.Server.onClientCommand(module, command, player, args)
    if module ~= "MapMarkerSystem" then return; end
    if MapMarkerSystem.Server.ServerCommands[command] then
        MapMarkerSystem.Server.ServerCommands[command](player, args);
    end
end

Events.OnClientCommand.Add(MapMarkerSystem.Server.onClientCommand);
