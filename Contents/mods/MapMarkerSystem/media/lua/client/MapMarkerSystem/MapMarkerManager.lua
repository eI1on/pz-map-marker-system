local Globals = require("Starlit/Globals");
local Logger = require("MapMarkerSystem/Logger");
local MapMarkerSystem = require("MapMarkerSystem/Shared");
local AddMarkerModal = require("MapMarkerSystem/AddMarkerModal");

local MapMarkerManager = ISPanel:derive("MapMarkerManager");
MapMarkerManager.instance = nil;

local CONST = {
    PADDING = 10,
    ELEMENT_HEIGHT = 20,
    WINDOW_WIDTH = 300,
    WINDOW_HEIGHT = 500,
    LABEL_WIDTH = 80,
    ENTRY_WIDTH = 200,
    NUMBER_ENTRY_WIDTH = 50,
    SECTION_SPACING = 10,
    ITEM_SPACING = 5,
    BORDER_COLOR = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
    BACKGROUND_COLOR = { r = 0.1, g = 0.1, b = 0.1, a = 0.75 },
    BTTN_WIDTH = 110,
    BTTN_HEIGHT = 25,
};

function MapMarkerManager:new(x, y, width, height, playerObj)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    if y == 0 then
        o.y = o:getMouseY() - (CONST.WINDOW_HEIGHT / 2);
        o:setY(o.y)
    end
    if x == 0 then
        o.x = o:getMouseX() - (CONST.WINDOW_WIDTH / 2);
        o:setX(o.x)
    end

    o.borderColor     = CONST.BORDER_COLOR;
    o.backgroundColor = CONST.BACKGROUND_COLOR;
    o.width           = CONST.WINDOW_WIDTH;
    o.height          = CONST.WINDOW_HEIGHT;
    o.playerObj       = playerObj;
    o.playerNum       = playerObj and playerObj:getPlayerNum() or -1;
    o.moveWithMouse   = true;
    o.anchorLeft      = true;
    o.anchorRight     = true;
    o.anchorTop       = true;
    o.anchorBottom    = true;
    o.resizable       = false;

    return o
end

function MapMarkerManager:initialise()
    ISPanel.initialise(self);
    self:createChildren();
end

function MapMarkerManager:createChildren()
    local x = CONST.PADDING;
    local y = CONST.PADDING;

    -- Header Section
    local headerX = (self.width - getTextManager():MeasureStringX(UIFont.Large, getText("IGUI_MMS_MapMarkerSystem"))) / 2;
    self.headerLabel = ISLabel:new(headerX, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_MapMarkerSystem"), 1, 1, 1, 1,
        UIFont.Large, true);
    self.headerLabel:initialise();
    self:addChild(self.headerLabel);
    y = y + CONST.ELEMENT_HEIGHT + CONST.SECTION_SPACING * 2;

    -- Action Buttons Row
    self.addMarkerBtn = ISButton:new(x, y, CONST.BTTN_WIDTH, CONST.BTTN_HEIGHT, getText("IGUI_MMS_AddMarker"), self,
        MapMarkerManager.onClickBttn);
    self.addMarkerBtn.internal = "ADDMARKER";
    self.addMarkerBtn:initialise();
    self.addMarkerBtn:instantiate();
    self.addMarkerBtn:setFont(UIFont.Medium);
    self.addMarkerBtn:setWidthToTitle(CONST.BTTN_WIDTH, false);
    self:addChild(self.addMarkerBtn);

    y = y + CONST.BTTN_HEIGHT + CONST.ITEM_SPACING;

    self.teleportBtn = ISButton:new(x, y, CONST.BTTN_WIDTH, CONST.BTTN_HEIGHT, getText("IGUI_MMS_Teleport"), self,
        MapMarkerManager.onClickBttn);
    self.teleportBtn.internal = "TELEPORT";
    self.teleportBtn:initialise();
    self.teleportBtn:instantiate();
    self.teleportBtn:setFont(UIFont.Medium);
    self.teleportBtn:setWidthToTitle(CONST.BTTN_WIDTH, false);
    self:addChild(self.teleportBtn);

    self.deleteMarkerBtn = ISButton:new(self.width - CONST.BTTN_WIDTH - CONST.PADDING, y, CONST.BTTN_WIDTH,
        CONST.BTTN_HEIGHT, getText("IGUI_MMS_Delete"), self, MapMarkerManager.onClickBttn);
    self.deleteMarkerBtn.internal = "DELETEMARKER";
    self.deleteMarkerBtn:initialise();
    self.deleteMarkerBtn:instantiate();
    self.deleteMarkerBtn:setFont(UIFont.Medium);
    -- self.deleteMarkerBtn:setWidthToTitle(CONST.BTTN_WIDTH, false);
    self:addChild(self.deleteMarkerBtn);
    y = y + CONST.BTTN_HEIGHT + CONST.SECTION_SPACING;

    -- Markers List (taking about 50% of remaining height)
    local remainingHeight = CONST.WINDOW_HEIGHT - y - CONST.BTTN_HEIGHT - CONST.PADDING;
    local listHeight = math.floor(remainingHeight * 0.5);
    self.markersList = ISScrollingListBox:new(x, y, CONST.WINDOW_WIDTH - (CONST.PADDING * 2), listHeight);
    self.markersList:initialise();
    self.markersList:instantiate();
    self.markersList:setFont(UIFont.Medium, 7);
    self.markersList.doDrawItem = self.drawMapMarkersListItem;
    self.markersList.onMouseDown = self.onMouseDownMapMarkersList
    self.markersList.drawBorder = true;
    self.markersList.backgroundColor = CONST.BACKGROUND_COLOR;
    self:addChild(self.markersList);
    y = y + listHeight + CONST.SECTION_SPACING;

    -- Selected Marker Details Section
    -- Name
    self.nameLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Name"), 1, 1, 1, 1, UIFont.Medium, true);
    self.nameLabel:initialise();
    self:addChild(self.nameLabel);

    self.markerName = ISTextEntryBox:new("", x + CONST.LABEL_WIDTH, y, CONST.ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.markerName:initialise();
    self.markerName:instantiate();
    self.markerName.onTextChange = self.onMarkerNameInputChange;
    self:addChild(self.markerName);
    y = y + CONST.ELEMENT_HEIGHT + CONST.ITEM_SPACING;

    -- Location
    self.locationLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Location"), 1, 1, 1, 1, UIFont.Medium,
        true);
    self.locationLabel:initialise();
    self:addChild(self.locationLabel);
    y = y + CONST.ELEMENT_HEIGHT + 5;

    -- Coordinates
    local coordStartX = x + CONST.LABEL_WIDTH;
    self.xLabel = ISLabel:new(coordStartX, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_xCoord"), 1, 1, 1, 1, UIFont
        .Medium, true);
    self.xLabel:initialise();
    self:addChild(self.xLabel);

    self.xEntryBox = ISTextEntryBox:new("", coordStartX + 25, y, CONST.NUMBER_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.xEntryBox:initialise();
    self.xEntryBox:instantiate();
    self.xEntryBox.coordType = "x";
    self.xEntryBox.onTextChange = self.onCoordsInputChange;
    self.xEntryBox:setOnlyNumbers(true);
    self:addChild(self.xEntryBox);

    self.yLabel = ISLabel:new(coordStartX + CONST.NUMBER_ENTRY_WIDTH + 35, y, CONST.ELEMENT_HEIGHT,
        getText("IGUI_MMS_yCoord"), 1, 1, 1, 1,
        UIFont.Medium, true);
    self.yLabel:initialise();
    self:addChild(self.yLabel);

    self.yEntryBox = ISTextEntryBox:new("", self.yLabel:getRight() + 5, y, CONST.NUMBER_ENTRY_WIDTH, CONST
        .ELEMENT_HEIGHT);
    self.yEntryBox:initialise();
    self.yEntryBox:instantiate();
    self.yEntryBox.coordType = "y";
    self.yEntryBox.onTextChange = self.onCoordsInputChange;
    self.yEntryBox:setOnlyNumbers(true);
    self:addChild(self.yEntryBox);
    y = y + CONST.ELEMENT_HEIGHT + CONST.ITEM_SPACING;

    -- Scale
    self.scaleLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Scale"), 1, 1, 1, 1, UIFont.Medium, true);
    self.scaleLabel:initialise();
    self:addChild(self.scaleLabel);

    self.scaleEntryBox = ISTextEntryBox:new("", x + CONST.LABEL_WIDTH, y, CONST.NUMBER_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.scaleEntryBox:initialise();
    self.scaleEntryBox:instantiate();
    self.scaleEntryBox.onTextChange = self.onScaleInputChange;
    self.scaleEntryBox:setOnlyNumbers(true);
    self:addChild(self.scaleEntryBox);
    y = y + CONST.ELEMENT_HEIGHT + CONST.ITEM_SPACING;

    -- Toggle Section
    self.boolOptions = ISTickBox:new(x, y, CONST.ENTRY_WIDTH, CONST.ELEMENT_HEIGHT, "", self,
        MapMarkerManager.onBoolOptionsChange);
    self.boolOptions:initialise();
    self.boolOptions:addOption(getText("IGUI_MMS_Enabled"));
    self.boolOptions:setFont(UIFont.Medium);
    self.boolOptions:setWidthToFit();
    self.boolOptions.changeOptionMethod = self.onTickBoxMapMarkerOptions;
    self.boolOptions.changeOptionTarget = self;
    self:addChild(self.boolOptions);
    y = y + CONST.ELEMENT_HEIGHT + CONST.ITEM_SPACING;

    -- Texture
    self.textureLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Texture"), 1, 1, 1, 1, UIFont.Medium,
        true);
    self.textureLabel:initialise();
    self:addChild(self.textureLabel);

    self.textureEntryBox = ISTextEntryBox:new("", x + CONST.LABEL_WIDTH, y, CONST.ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.textureEntryBox:initialise();
    self.textureEntryBox:instantiate();
    self.textureEntryBox.onTextChange = self.onTextureInputChange;
    self:addChild(self.textureEntryBox);

    -- Close Button at the bottom right
    self.closeBtn = ISButton:new(self.width - CONST.BTTN_WIDTH - CONST.PADDING,
        CONST.WINDOW_HEIGHT - CONST.BTTN_HEIGHT - CONST.PADDING,
        CONST.BTTN_WIDTH, CONST.BTTN_HEIGHT, getText("IGUI_MMS_Close"), self, MapMarkerManager.onClickBttn);
    self.closeBtn.internal = "CLOSE";
    self.closeBtn:initialise();
    self.closeBtn:instantiate();
    self.closeBtn:setFont(UIFont.Medium);
    self.closeBtn:setWidthToTitle(CONST.BTTN_WIDTH, false);
    self:addChild(self.closeBtn);

    self.refresh = 3;
end

function MapMarkerManager:prerender()
    ISPanel.prerender(self);

    if self.refresh and self.refresh > 0 then
        self.refresh = self.refresh - 1;
        if self.refresh <= 0 then
            self:populateElements();
        end
    end
end

function MapMarkerManager:populateElements()
    self:populateMarkersList();
end

function MapMarkerManager:populateMarkersList()
    self.markersList:clear();
    MapMarkerSystem.MapMarkers = MapMarkerSystem.Shared.RequestMarkers();
    if MapMarkerSystem.MapMarkers then
        for i = 1, #MapMarkerSystem.MapMarkers do
            self.markersList:addItem(MapMarkerSystem.MapMarkers[i].name, MapMarkerSystem.MapMarkers[i]);
        end
        if #MapMarkerSystem.MapMarkers > 0 then
            self.markersList.selected = 1;
            self:populateMarkerDetails(MapMarkerSystem.MapMarkers[1]);
        end
    end
end

function MapMarkerManager:getMapMarkerIdx()
    return self.markersList and self.markersList.selected;
end

function MapMarkerManager:onTickBoxMapMarkerOptions(index, selected)
    local selectedMapMarkerIdx = self:getMapMarkerIdx();

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    mapMarkerData.isEnabled = selected;

    self.boolOptions.selected[index] = selected;

    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = self:getMapMarkerIdx(),
        newKey = "isEnabled",
        newValue = selected
    });
end

function MapMarkerManager:onMarkerNameInputChange()
    local nameVal = self:getInternalText();
    if nameVal == "" then return; end

    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx();

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end
    mapMarkerData.name = nameVal;

    sendClientCommand("MapMarkerSystem", "EditMarkerData",
        {
            selectedIdx = selectedMapMarkerIdx,
            newKey = "name",
            newValue = nameVal
        }
    );

    self.parent.markerName:setText(mapMarkerData.name);
end

function MapMarkerManager:onScaleInputChange()
    local scaleVal = self:getInternalText();
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx();

    if scaleVal == "" or not tonumber(scaleVal) then scaleVal = "-1"; end

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    mapMarkerData.scale = tonumber(scaleVal) and tonumber(scaleVal) or mapMarkerData.scale;

    sendClientCommand("MapMarkerSystem", "EditMarkerData",
        {
            selectedIdx = selectedMapMarkerIdx,
            newKey = "scale",
            newValue = mapMarkerData.scale
        }
    );
    self.parent.scaleEntryBox:setText(tostring(mapMarkerData.scale));
end

local function textureExists(texture)
    return texture and texture ~= "" and getTexture(texture) or nil;
end

function MapMarkerManager:onTextureInputChange()
    local textureVal = self:getInternalText();
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx();

    if not textureExists(textureVal) then return; end

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end
    mapMarkerData.texturePath = textureVal;

    sendClientCommand("MapMarkerSystem", "EditMarkerData",
        {
            selectedIdx = selectedMapMarkerIdx,
            newKey = "texturePath",
            newValue = textureVal
        }
    );

    self.parent.textureEntryBox:setText(mapMarkerData.texturePath);
end

function MapMarkerManager:onCoordsInputChange()
    local coordVal = self:getInternalText();
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx();

    if coordVal == "" or not tonumber(coordVal) then
        coordVal = "-1";
    end

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    mapMarkerData.coordinates = mapMarkerData.coordinates or {};
    mapMarkerData.coordinates[self.coordType] = tonumber(coordVal);

    self.parent:validateCoords(mapMarkerData);
end

function MapMarkerManager:validateCoords(mapMarkerData)
    if not mapMarkerData.coordinates then return; end

    local x = mapMarkerData.coordinates.x or -1;
    local y = mapMarkerData.coordinates.y or -1;

    if x == -1 or y == -1 then return; end

    local selectedMapMarkerIdx = self:getMapMarkerIdx();
    sendClientCommand("MapMarkerSystem", "EditMarkerData",
        {
            selectedIdx = selectedMapMarkerIdx,
            newKey = "coordinates.x",
            newValue = x
        }
    );
    sendClientCommand("MapMarkerSystem", "EditMarkerData",
        {
            selectedIdx = selectedMapMarkerIdx,
            newKey = "coordinates.y",
            newValue = y
        }
    );

    self.xEntryBox:setText(tostring(x));
    self.yEntryBox:setText(tostring(y));
end

function MapMarkerManager:populateMarkerDetails(markerData)
    if not markerData then
        self.markerName:setText("");
        self.xEntryBox:setText("");
        self.yEntryBox:setText("");
        self.scaleEntryBox:setText("");
        self.boolOptions:setSelected(1, false);
        self.textureEntryBox:setText("");
    else
        self.markerName:setText(markerData.name or "");
        self.xEntryBox:setText(tostring(markerData.coordinates.x or ""));
        self.yEntryBox:setText(tostring(markerData.coordinates.y or ""));
        self.scaleEntryBox:setText(tostring(markerData.scale or ""));
        self.boolOptions:setSelected(1, markerData.isEnabled or false);
        self.textureEntryBox:setText(markerData.texturePath or "");
    end
end

function MapMarkerManager:drawMapMarkersListItem(y, item, alt)
    if not item.height then item.height = self.itemheight; end

    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), item.height - 1, 0.3, 0.7, 0.35, 0.15);
    end

    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g,
        self.borderColor.b);

    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2;

    local markerData = item.item;
    local textColor = { r = 0.9, g = 0.9, b = 0.9 };
    if markerData.isEnabled then
        textColor = { r = 0.2, g = 0.8, b = 0.2 };
    else
        textColor = { r = 0.8, g = 0.2, b = 0.2 };
    end

    self:drawText(markerData.name, 15, y + itemPadY, textColor.r, textColor.g, textColor.b, 0.9, self.font);

    local coordsText = string.format("(%d, %d)", markerData.coordinates.x or 0, markerData.coordinates.y or 0);
    local coordsWidth = getTextManager():MeasureStringX(self.font, coordsText);
    local coordsX = self:getWidth() - 15 - coordsWidth;
    self:drawText(coordsText, coordsX, y + itemPadY, 0.7, 0.7, 0.7, 0.9, self.font);

    return y + item.height;
end

function MapMarkerManager:onMouseDownMapMarkersList(x, y)
    if self.items and #self.items == 0 then return; end
    local row = self:rowAt(x, y);

    if row > #self.items then row = #self.items; end
    if row < 1 then row = 1; end

    local item = self.items[row].item;

    getSoundManager():playUISound("UISelectListItem");
    self.selected = row;
    if self.onmousedown then
        self.onmousedown(self.target, item);
    end

    self.parent:populateMarkerDetails(item);
end

function MapMarkerManager:close()
    self:setVisible(false);
    self:removeFromUIManager();
    MapMarkerManager.instance = nil;
end

function MapMarkerManager:onClickBttn(button)
    if button.internal == "CLOSE" then
        self:close();
    elseif button.internal == "TELEPORT" then
        if not self.playerObj then return; end
        local selectedMapMarkerIdx = self:getMapMarkerIdx();
        local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
        if not selectedMapMarkerIdx or not mapMarkerData then return; end

        self.playerObj:setX(mapMarkerData.coordinates.x);
        self.playerObj:setY(mapMarkerData.coordinates.y);
        self.playerObj:setZ(0.0);
        self.playerObj:setLx(mapMarkerData.coordinates.x);
        self.playerObj:setLy(mapMarkerData.coordinates.y);
    elseif button.internal == "DELETEMARKER" then
        local selectedMapMarkerIdx = self:getMapMarkerIdx();
        if not selectedMapMarkerIdx or not MapMarkerSystem.MapMarkers[selectedMapMarkerIdx] then return; end
        sendClientCommand("MapMarkerSystem", "RemoveMapMarker", { selectedIdx = selectedMapMarkerIdx });
        self.markersList.selected = 0;
        self.refresh = 3;
    elseif button.internal == "ADDMARKER" then
        local modal = AddMarkerModal:new(0, 0, 300, 200, getText("IGUI_MMS_AddMarker"), "", self,
            self.onAddMapMarker, self.playerNum);
        modal:initialise();
        modal:addToUIManager();
    end
end

function MapMarkerManager:onAddMapMarker(target, newMapMarker)
    if target.internal ~= "OK" then return; end
    if not newMapMarker then return; end
    sendClientCommand("MapMarkerSystem", "AddMapMarker", { newMapMarker = newMapMarker });
    self.markersList:addItem(newMapMarker.name, newMapMarker);
    self.refresh = 3;
end

function MapMarkerManager.openPanel()
    local x = getCore():getScreenWidth() / 1.5;
    local y = getCore():getScreenHeight() / 6;
    if MapMarkerManager.instance == nil then
        local window = MapMarkerManager:new(x, y, CONST.WINDOW_WIDTH, CONST.WINDOW_HEIGHT, getPlayer());
        window:initialise();
        window:addToUIManager();
        MapMarkerManager.instance = window;
    else
        MapMarkerManager.instance:close();
    end
end

local ISDebugMenu_setupButtons = ISDebugMenu.setupButtons;
---@diagnostic disable-next-line: duplicate-set-field
function ISDebugMenu:setupButtons()
    MapMarkerSystem.MapMarkers = MapMarkerSystem.Shared.RequestMarkers();
    self:addButtonInfo(getText("IGUI_MMS_MapMarkerSystem"), function() MapMarkerManager.openPanel() end, "MAIN");
    ISDebugMenu_setupButtons(self);
end

local ISAdminPanelUI_create = ISAdminPanelUI.create;
---@diagnostic disable-next-line: duplicate-set-field
function ISAdminPanelUI:create()
    ISAdminPanelUI_create(self);
    local fontHeight = getTextManager():getFontHeight(UIFont.Small);
    local btnWid = 150;
    local btnHgt = math.max(25, fontHeight + 3 * 2);
    local btnGapY = 5;

    local lastButton = self.children[self.IDMax - 1];
    lastButton = lastButton.internal == "CANCEL" and self.children[self.IDMax - 2] or lastButton;

    MapMarkerSystem.MapMarkers = MapMarkerSystem.Shared.RequestMarkers();

    self.showMapMarkerSystem = ISButton:new(lastButton.x, lastButton.y + btnHgt + btnGapY, btnWid, btnHgt,
        getText("IGUI_MMS_MapMarkerSystem"), self, MapMarkerManager.openPanel);
    self.showMapMarkerSystem.internal = "";
    self.showMapMarkerSystem:initialise();
    self.showMapMarkerSystem:instantiate();
    self.showMapMarkerSystem.borderColor = self.buttonBorderColor;
    self:addChild(self.showMapMarkerSystem);
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if not player then return; end

    local hasAccess = false;
    if Globals.isSingleplayer then
        hasAccess = true;
    elseif Globals.isClient then
        -- hasAccess = isAdmin();
    end

    if Globals.isDebug then hasAccess = true; end

    if hasAccess then
        context:addOptionOnTop(
            getText("IGUI_MMS_MapMarkerSystem"), worldobjects,
            function()
                MapMarkerManager.openPanel();
            end
        );
    end
end

Events.OnFillWorldObjectContextMenu.Remove(onFillWorldObjectContextMenu);
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu);

return MapMarkerManager;
