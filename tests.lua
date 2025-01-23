local centerX = 13000
local centerY = 5000

local radius = 5000
local numMarkers = 100
local rotations = 25
local currentScale = 3500

for i = 1, numMarkers do
    local angle = (i / numMarkers) * math.pi * 2 * rotations
    local currentRadius = radius * (i / numMarkers)
    local x = math.floor(centerX + (math.cos(angle) * currentRadius))
    local y = math.floor(centerY + (math.sin(angle) * currentRadius))
    if i % 5 == 0 then
        currentScale = currentScale + 5
    end
    local newMapMarker = {
        name = "Marker_" .. string.format("%03d", i),
        coordinates = {
            x = x,
            y = y,
        },
        scale = currentScale,
        texturePath = "media/ui/quest1.png",
        isEnabled = true,
    }
    sendClientCommand("MapMarkerSystem", "AddMapMarker", { newMapMarker = newMapMarker });
end


local MapMarkerSystem = require("MapMarkerSystem/Shared");
for i = 1, #MapMarkerSystem.MapMarkers do
    sendClientCommand("MapMarkerSystem", "RemoveMapMarker", { selectedIdx = i });
end


MapMarkerSystem.MapMarkers = {
    {
        name = "Marker_1",
        coordinates = {
            x = x,
            y = y,
        },
        scale = currentScale,
        texturePath = "",
        isEnabled = true,
    }
}