local defaultMarkers = {};

defaultMarkers = {
    textureType = {
        name = "Texture_Marker",
        markerType = "texture",
        isEnabled = true,
        coordinates = {
            center = { x = -1, y = -1 }, -- Center
        },
        texturePath = "media/ui/quest1.png",
        scale = 1,
        lockZoom = false,   -- Prevents marker scaling with zoom
        maxZoomLevel = 100, -- Marker appears at 100% zoom or lower
    },
    rectangleType = {
        name = "Rectangle_Marker",
        markerType = "rectangle",
        isEnabled = true,
        coordinates = {
            center = { x = -1, y = -1 }, -- Center coordinate
            width = 100,                 -- Width of the rectangle
            height = 100                 -- Height of the rectangle
        },
        color = {
            r = 1.0,
            g = 1.0,
            b = 1.0,
            a = 1.0
        },
        scale = 1,
        lockZoom = true,
        maxZoomLevel = 100
    },
    areaType = {
        name = "Area_Marker",
        markerType = "area",
        isEnabled = true,
        coordinates = {
            nw = { x = -1, y = -1 }, -- Northwest corner
            se = { x = -1, y = -1 }  -- Southeast corner
        },
        color = {
            r = 1.0,
            g = 1.0,
            b = 1.0,
            a = 1.0
        },
        maxZoomLevel = 100
    }
};

return defaultMarkers;
