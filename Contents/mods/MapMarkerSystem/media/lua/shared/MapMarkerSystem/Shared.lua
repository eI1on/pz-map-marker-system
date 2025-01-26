local Globals = require("Starlit/Globals");

local MapMarkerSystem = {};
MapMarkerSystem.Shared = {};

function MapMarkerSystem.Shared.RequestMarkers()
    if Globals.isClient then
        sendClientCommand("MapMarkerSystem", "LoadMapMarkers", { toAll = false });
    else
        MapMarkerSystem.MapMarkers = ModData.getOrCreate("MapMarkerSystem");
    end
    return MapMarkerSystem.MapMarkers;
end

MapMarkerSystem.FontList = {
    "Small",
    "Medium",
    "Large",
    "NewSmall",
    "NewMedium",
    "MediumNew",
    "NewLarge",
    "Dialogue",
    "Handwritten",
    "Intro",
    "Cred1",
    "Cred2",
    "Title",
    "MainMenu1",
    "MainMenu2",
    "Massive",
    "AutoNormLarge",
    "AutoNormMedium",
    "AutoNormSmall",
    "DebugConsole",
    "Code",
}

return MapMarkerSystem
