local Globals = require("Starlit/Globals");

local MapMarkerSystem = {};
MapMarkerSystem.Shared = {};

function MapMarkerSystem.Shared.RequestMarkers()
    if Globals.isClient then
        sendClientCommand("MapMarkerSystem", "LoadMapMarkers", { toAll = false});
    else
        MapMarkerSystem.MapMarkers = ModData.getOrCreate("MapMarkerSystem");
    end
    return MapMarkerSystem.MapMarkers;
end

return MapMarkerSystem
