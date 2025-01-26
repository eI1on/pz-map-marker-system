local Globals = require("Starlit/Globals");
local Logger = require("MapMarkerSystem/Logger");
local MapMarkerSystem = require("MapMarkerSystem/Shared");
local AddMarkerModal = require("MapMarkerSystem/AddMarkerModal");

local MapMarkerManager = ISPanel:derive("MapMarkerManager");
MapMarkerManager.instance = nil;

local CONST = {
    PADDING = 10,
    ELEMENT_HEIGHT = 25,
    WINDOW_WIDTH = 350,
    WINDOW_HEIGHT = 750,
    LABEL_WIDTH = 80,
    ENTRY_WIDTH = 200,
    NUMBER_ENTRY_WIDTH = 50,
    SECTION_SPACING = 10,
    ITEM_SPACING = 5,
    BUTTON_WIDTH = 110,
    BUTTON_HEIGHT = 25,
    FONT = {
        SMALL = UIFont.Small,
        MEDIUM = UIFont.Medium,
        LARGE = UIFont.Large
    },
    COLORS = {
        BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
        BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.75 },
        TEXT = { r = 1, g = 1, b = 1, a = 1 }
    }
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

    o.borderColor     = CONST.COLORS.BORDER;
    o.backgroundColor = CONST.COLORS.BACKGROUND;
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
    self.addMarkerBtn = ISButton:new(x, y, CONST.BUTTON_WIDTH, CONST.BUTTON_HEIGHT, getText("IGUI_MMS_AddMarker"), self,
        MapMarkerManager.onClickBttn);
    self.addMarkerBtn.internal = "ADDMARKER";
    self.addMarkerBtn:initialise();
    self.addMarkerBtn:instantiate();
    self.addMarkerBtn:setFont(UIFont.Medium);
    self.addMarkerBtn:setWidthToTitle(CONST.BUTTON_WIDTH, false);
    self:addChild(self.addMarkerBtn);
    y = y + CONST.BUTTON_HEIGHT + CONST.ITEM_SPACING;

    self.teleportBtn = ISButton:new(x, y, CONST.BUTTON_WIDTH, CONST.BUTTON_HEIGHT, getText("IGUI_MMS_Teleport"), self,
        MapMarkerManager.onClickBttn);
    self.teleportBtn.internal = "TELEPORT";
    self.teleportBtn:initialise();
    self.teleportBtn:instantiate();
    self.teleportBtn:setFont(UIFont.Medium);
    self.teleportBtn:setWidthToTitle(CONST.BUTTON_WIDTH, false);
    self:addChild(self.teleportBtn);

    self.deleteMarkerBtn = ISButton:new(self.width - CONST.BUTTON_WIDTH - CONST.PADDING, y, CONST.BUTTON_WIDTH,
        CONST.BUTTON_HEIGHT, getText("IGUI_MMS_Delete"), self, MapMarkerManager.onClickBttn);
    self.deleteMarkerBtn.internal = "DELETEMARKER";
    self.deleteMarkerBtn:initialise();
    self.deleteMarkerBtn:instantiate();
    self.deleteMarkerBtn:setFont(UIFont.Medium);
    -- self.deleteMarkerBtn:setWidthToTitle(CONST.BUTTON_WIDTH, false);
    self:addChild(self.deleteMarkerBtn);
    y = y + CONST.BUTTON_HEIGHT + CONST.SECTION_SPACING;

    -- Markers List (taking about 40% of remaining height)
    local remainingHeight = CONST.WINDOW_HEIGHT - y - CONST.BUTTON_HEIGHT - CONST.PADDING;
    local listHeight = math.floor(remainingHeight * 0.4);
    self.markersList = ISScrollingListBox:new(x, y, CONST.WINDOW_WIDTH - (CONST.PADDING * 2), listHeight);
    self.markersList:initialise();
    self.markersList:instantiate();
    self.markersList:setFont(UIFont.Medium, 7);
    self.markersList.doDrawItem = self.drawMapMarkersListItem;
    self.markersList.onMouseDown = self.onMouseDownMapMarkersList
    self.markersList.drawBorder = true;
    self.markersList.backgroundColor = CONST.COLORS.BACKGROUND;
    self:addChild(self.markersList);
    y = y + listHeight + CONST.SECTION_SPACING;

    -- Selected Marker Details Section
    -- Marker type
    self.markerTypeLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_MarkerType"), 1, 1, 1, 1,
        UIFont.Medium, true);
    self.markerTypeLabel:initialise();
    self.markerTypeLabel:instantiate();
    self:addChild(self.markerTypeLabel);

    self.markerTypeValLabel = ISLabel:new(self.markerTypeLabel:getRight() + CONST.SECTION_SPACING, y,
        CONST.ELEMENT_HEIGHT,
        "", 1, 1, 1, 1,
        UIFont.Medium, true);
    self.markerTypeValLabel:initialise();
    self.markerTypeValLabel:instantiate();
    self:addChild(self.markerTypeValLabel);
    y = self.markerTypeLabel:getBottom() + CONST.ITEM_SPACING;


    -- Name
    self.markerNameLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Name"), 1, 1, 1, 1, UIFont.Medium,
        true);
    self.markerNameLabel:initialise();
    self:addChild(self.markerNameLabel);

    self.markerNameEntryBox = ISTextEntryBox:new("", self.markerTypeValLabel:getX(), y, CONST.ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.markerNameEntryBox:initialise();
    self.markerNameEntryBox:instantiate();
    self.markerNameEntryBox:setTooltip(getText("Tooltip_MMS_MarkerName"));
    self.markerNameEntryBox.onTextChange = self.onMarkerNameInputChange;
    self:addChild(self.markerNameEntryBox);
    y = self.markerNameLabel:getBottom() + CONST.ITEM_SPACING;

    -- Toggle Section
    self.enableMarkerTickBox = ISTickBox:new(x, y, CONST.ENTRY_WIDTH, CONST.ELEMENT_HEIGHT, "", self,
        MapMarkerManager.onTickBoxEnableMarkerOption);
    self.enableMarkerTickBox:initialise();
    self.enableMarkerTickBox:addOption(getText("IGUI_MMS_EnableMarker"));
    self.enableMarkerTickBox:setFont(UIFont.Medium);
    self.enableMarkerTickBox:setWidthToFit();
    self.enableMarkerTickBox.tooltip = getText("Tooltip_MMS_EnableMarker");
    self:addChild(self.enableMarkerTickBox);
    y = self.enableMarkerTickBox:getBottom() + CONST.ITEM_SPACING;

    -- Name control
    self.enableMarkerNameTickBox = ISTickBox:new(x, y, CONST.NUMBER_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT, "", self,
        MapMarkerManager.onTickBoxEnableMarkerNameOption);
    self.enableMarkerNameTickBox:initialise();
    self.enableMarkerNameTickBox:addOption(getText("IGUI_MMS_EnableMarkerName"));
    self.enableMarkerNameTickBox:setFont(UIFont.Medium);
    self.enableMarkerNameTickBox:setWidthToFit();
    self.enableMarkerNameTickBox.tooltip = getText("Tooltip_MMS_EnableMarkerName");
    self:addChild(self.enableMarkerNameTickBox);
    y = self.enableMarkerNameTickBox:getBottom() + CONST.ITEM_SPACING;


    self.markerNameFontLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_MarkerFontName"), 1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.markerNameFontLabel:initialise();
    self.markerNameFontLabel:instantiate();
    self:addChild(self.markerNameFontLabel);
    self.markerNameFontComboBox = ISComboBox:new(self.markerTypeValLabel:getX(), y, CONST.NUMBER_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.markerNameFontComboBox.font = UIFont.Small;
    self.markerNameFontComboBox:initialise();
    self.markerNameFontComboBox:instantiate();
    self.markerNameFontComboBox:setWidthToOptions(150);
    self.markerNameFontComboBox.onChange = self.onChangeMarkerNameFont;
    self.markerNameFontComboBox.target = self;
    self:addChild(self.markerNameFontComboBox);

    for i = 1, #MapMarkerSystem.FontList do
        self.markerNameFontComboBox:addOption(MapMarkerSystem.FontList[i]);
    end
    y = self.markerNameFontLabel:getBottom() + CONST.ITEM_SPACING;


    self.colorLabelMarkerName = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_MarkerNameColor"), 1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.colorLabelMarkerName:initialise();
    self.colorLabelMarkerName:instantiate();
    self:addChild(self.colorLabelMarkerName);
    self.colorPickerMarkerNameButton = ISButton:new(self.markerTypeValLabel:getX(), y, CONST.NUMBER_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT, "", self, self.onPressedColorPickerMarkerNameBttn);
    self.colorPickerMarkerNameButton:initialise();
    self.colorPickerMarkerNameButton:instantiate();
    self.colorPickerMarkerNameButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 };
    self.colorPickerMarkerNameButton:setTooltip(getText("Tooltip_MMS_MarkerNameColorPicker"));
    self:addChild(self.colorPickerMarkerNameButton);

    self.colorPickerMarkerName = ISColorPicker:new(0, 0)
    self.colorPickerMarkerName:initialise()
    self.colorPickerMarkerName.pickedTarget = self
    self.colorPickerMarkerName.resetFocusTo = self
    self.currentColorMarkerName = ColorInfo.new(1, 1, 1, 1);
    self.colorPickerMarkerName:setInitialColor(self.currentColorMarkerName);
    self.colorPickerMarkerName:addToUIManager();
    self.colorPickerMarkerName:setVisible(false);
    self.colorPickerMarkerName.otherFct = true;
    self.colorPickerMarkerName.parent = self;
    y = self.colorLabelMarkerName:getBottom() + CONST.ITEM_SPACING;

    self.scaleNameLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_MarkerNameScale"), 1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.scaleNameLabel:initialise();
    self.scaleNameLabel:instantiate();
    self.scaleNameEntryBox = ISTextEntryBox:new("1", self.markerTypeValLabel:getX(), y, CONST.NUMBER_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.scaleNameEntryBox:initialise();
    self.scaleNameEntryBox:instantiate();
    self.scaleNameEntryBox.onTextChange = self.onScaleInputChange;
    self.scaleNameEntryBox.scaleType = "scaleName";
    -- self.scaleNameEntryBox:setOnlyNumbers(true);
    self.scaleNameEntryBox:setTooltip(getText("Tooltip_MMS_NameScale"));
    self:addChild(self.scaleNameLabel);
    self:addChild(self.scaleNameEntryBox);
    y = self.scaleNameLabel:getBottom() + CONST.ITEM_SPACING;


    -- Coordinates (NW/Center)
    self.locationLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Location"), 1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.locationLabel:initialise();
    self.locationLabel:instantiate();
    self:addChild(self.locationLabel);

    self.nwXLabel = ISLabel:new(self.markerTypeValLabel:getX(), y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_xCoord", "1"),
        1, 1, 1, 1, CONST.FONT.MEDIUM, true);
    self.nwXLabel:initialise();
    self.nwXLabel:instantiate();
    self:addChild(self.nwXLabel);
    self.nwXEntryBox = ISTextEntryBox:new("", self.nwXLabel:getRight() + CONST.ITEM_SPACING / 2, y,
        CONST.NUMBER_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.nwXEntryBox:initialise();
    self.nwXEntryBox:instantiate();
    self.nwXEntryBox.coordType = "x1";
    self.nwXEntryBox.onTextChange = self.onCoordsInputChange;
    self.nwXEntryBox:setOnlyNumbers(true);
    self:addChild(self.nwXEntryBox);

    self.nwYLabel = ISLabel:new(self.nwXEntryBox:getRight() + CONST.ITEM_SPACING, y, CONST.ELEMENT_HEIGHT,
        getText("IGUI_MMS_yCoord", "1"), 1, 1, 1, 1, CONST.FONT.MEDIUM, true);
    self.nwYLabel:initialise();
    self.nwYLabel:instantiate();
    self:addChild(self.nwYLabel);
    self.nwYEntryBox = ISTextEntryBox:new("", self.nwYLabel:getRight() + CONST.ITEM_SPACING / 2, y,
        CONST.NUMBER_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.nwYEntryBox:initialise();
    self.nwYEntryBox:instantiate();
    self.nwYEntryBox.coordType = "y1";
    self.nwYEntryBox.onTextChange = self.onCoordsInputChange;
    self.nwYEntryBox:setOnlyNumbers(true);
    self:addChild(self.nwYEntryBox);

    self.pickNWButton = ISButton:new(self.nwYEntryBox:getRight() + CONST.ITEM_SPACING, y, CONST.ELEMENT_HEIGHT,
        CONST.ELEMENT_HEIGHT, "", self, self.onClickPickLocation);
    self.pickNWButton:initialise();
    self.pickNWButton:instantiate();
    self.pickNWButton.internal = "PICK_NW";
    self.pickNWButton:setImage(getTexture("media/ui/pick_current_location.png"));
    self.pickNWButton:setTooltip(getText("Tooltip_MMS_PickCurrentLocation"));
    self.pickNWButton.borderColor = CONST.COLORS.BORDER;
    self:addChild(self.pickNWButton);

    y = self.locationLabel:getBottom() + CONST.ITEM_SPACING;

    -- SE Coordinates for Area Type Marker, Width and Height for Rectangle Type
    self.seXLabel = ISLabel:new(self.markerTypeValLabel:getX(), y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_xCoord", "2"),
        1, 1, 1, 1, CONST.FONT.MEDIUM, true);
    self.seXLabel:initialise();
    self.seXLabel:instantiate();
    self:addChild(self.seXLabel);
    self.seXEntryBox = ISTextEntryBox:new("", self.seXLabel:getRight() + CONST.ITEM_SPACING / 2, y,
        CONST.NUMBER_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.seXEntryBox:initialise();
    self.seXEntryBox:instantiate();
    self.seXEntryBox.coordType = "x2";
    self.seXEntryBox.onTextChange = self.onCoordsInputChange;
    self.seXEntryBox:setOnlyNumbers(true);
    self:addChild(self.seXEntryBox);

    self.seYLabel = ISLabel:new(self.seXEntryBox:getRight() + CONST.ITEM_SPACING, y, CONST.ELEMENT_HEIGHT,
        getText("IGUI_MMS_yCoord", "2"), 1, 1, 1, 1, CONST.FONT.MEDIUM, true);
    self.seYLabel:initialise();
    self.seYLabel:instantiate();
    self:addChild(self.seYLabel);
    self.seYEntryBox = ISTextEntryBox:new("", self.seYLabel:getRight() + CONST.ITEM_SPACING / 2, y,
        CONST.NUMBER_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.seYEntryBox:initialise();
    self.seYEntryBox:instantiate();
    self.seYEntryBox.coordType = "y2";
    self.seYEntryBox.onTextChange = self.onCoordsInputChange;
    self.seYEntryBox:setOnlyNumbers(true);
    self:addChild(self.seYEntryBox);

    self.pickSEButton = ISButton:new(self.seYEntryBox:getRight() + CONST.ITEM_SPACING, y, CONST.ELEMENT_HEIGHT,
        CONST.ELEMENT_HEIGHT, "", self, self.onClickPickLocation);
    self.pickSEButton:initialise();
    self.pickSEButton:instantiate();
    self.pickSEButton.internal = "PICK_SE";
    self.pickSEButton:setImage(getTexture("media/ui/pick_current_location.png"));
    self.pickSEButton:setTooltip(getText("Tooltip_MMS_PickCurrentLocation"));
    self.pickSEButton.borderColor = CONST.COLORS.BORDER;
    self:addChild(self.pickSEButton);
    y = self.seXLabel:getBottom() + CONST.ITEM_SPACING;

    -- Texture
    self.textureLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Texture"), 1, 1, 1, 1, UIFont.Medium,
        true);
    self.textureLabel:initialise();
    self:addChild(self.textureLabel);

    self.textureEntryBox = ISTextEntryBox:new("", self.markerTypeValLabel:getX(), y, CONST.ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.textureEntryBox:initialise();
    self.textureEntryBox:instantiate();
    self.textureEntryBox.onTextChange = self.onTextureInputChange;
    self:addChild(self.textureEntryBox);
    y = self.textureLabel:getBottom() + CONST.ITEM_SPACING;

    -- Rectangle and Area specific controls
    self.colorLabelMarker = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_MarkerColor"), 1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.colorLabelMarker:initialise();
    self.colorLabelMarker:instantiate();
    self:addChild(self.colorLabelMarker);
    self.colorPickerMarkerButton = ISButton:new(self.markerTypeValLabel:getX(), y, CONST.NUMBER_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT, "", self, self.onPressedColorPickerMarkerBttn);
    self.colorPickerMarkerButton:initialise();
    self.colorPickerMarkerButton:instantiate();
    self.colorPickerMarkerButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 };
    self:addChild(self.colorPickerMarkerButton);

    self.colorPickerMarker = ISColorPicker:new(0, 0)
    self.colorPickerMarker:initialise()
    self.colorPickerMarker.pickedTarget = self
    self.colorPickerMarker.resetFocusTo = self
    self.currentColorMarker = ColorInfo.new(1, 1, 1, 1);
    self.colorPickerMarker:setInitialColor(self.currentColorMarker);
    self.colorPickerMarker:addToUIManager();
    self.colorPickerMarker:setVisible(false);
    self.colorPickerMarker.otherFct = true;
    self.colorPickerMarker.parent = self;
    y = self.colorLabelMarker:getBottom() + CONST.ITEM_SPACING;


    -- Scale
    self.scaleLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_MarkerScale"), 1, 1, 1, 1, UIFont.Medium,
        true);
    self.scaleLabel:initialise();
    self:addChild(self.scaleLabel);

    self.scaleEntryBox = ISTextEntryBox:new("", self.markerTypeValLabel:getX(), y, CONST.NUMBER_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.scaleEntryBox:initialise();
    self.scaleEntryBox:instantiate();
    self.scaleEntryBox.onTextChange = self.onScaleInputChange;
    self.scaleEntryBox.scaleType = "scale";
    -- self.scaleEntryBox:setOnlyNumbers(true);
    self.scaleEntryBox:setTooltip(getText("Tooltip_MMS_Scale"));
    self:addChild(self.scaleEntryBox);
    y = self.scaleLabel:getBottom() + CONST.ITEM_SPACING;


    -- Add Fixed Scale control
    self.lockZoomTickBox = ISTickBox:new(x, y, CONST.ENTRY_WIDTH, CONST.ELEMENT_HEIGHT, "", self,
        MapMarkerManager.onTickBoxFixedScaleOption);
    self.lockZoomTickBox:initialise();
    self.lockZoomTickBox:addOption(getText("IGUI_MMS_FixedScale"));
    self.lockZoomTickBox:setFont(UIFont.Medium);
    self.lockZoomTickBox:setWidthToFit();
    self.lockZoomTickBox.tooltip = getText("Tooltip_MMS_FixedScale");
    self:addChild(self.lockZoomTickBox);
    y = self.lockZoomTickBox:getBottom() + CONST.ITEM_SPACING;


    -- Add Max Zoom Level control
    self.maxZoomLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_MaxZoom"), 1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.maxZoomLabel:initialise();
    self.maxZoomLabel:instantiate();
    self:addChild(self.maxZoomLabel);

    self.maxZoomEntryBox = ISTextEntryBox:new("", self.markerTypeValLabel:getX(), y, CONST.NUMBER_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.maxZoomEntryBox:initialise();
    self.maxZoomEntryBox:instantiate();
    self.maxZoomEntryBox.onTextChange = self.onMaxZoomInputChange;
    self.maxZoomEntryBox:setOnlyNumbers(true);
    self.maxZoomEntryBox.tooltip = getText("Tooltip_MMS_MaxZoom");
    self:addChild(self.maxZoomEntryBox);


    -- Close Button at the bottom right
    self.closeBtn = ISButton:new(self.width - CONST.BUTTON_WIDTH - CONST.PADDING,
        CONST.WINDOW_HEIGHT - CONST.BUTTON_HEIGHT - CONST.PADDING, CONST.BUTTON_WIDTH, CONST.BUTTON_HEIGHT,
        getText("IGUI_MMS_Close"), self, MapMarkerManager.onClickBttn);
    self.closeBtn.internal = "CLOSE";
    self.closeBtn:initialise();
    self.closeBtn:instantiate();
    self.closeBtn:setFont(UIFont.Medium);
    self.closeBtn:setWidthToTitle(CONST.BUTTON_WIDTH, false);
    self:addChild(self.closeBtn);

    self:populateElementsDetails(nil);
    self.refresh = 3;
end

function MapMarkerManager:onPressedColorPickerMarkerBttn(button)
    self.colorPickerMarker:setX(getMouseX() - 100);
    self.colorPickerMarker:setY(getMouseY() - 20);
    self.colorPickerMarker.pickedFunc = self.onPickedMarkerColor;
    self.colorPickerMarker:setVisible(true);
    self.colorPickerMarker:bringToTop();
end

function MapMarkerManager:onPickedMarkerColor(color, mouseUp)
    self.currentColorMarker = ColorInfo.new(color.r, color.g, color.b, 1);
    self.colorPickerMarkerButton.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 };
    self.colorPickerMarker:setVisible(false);

    local selectedMapMarkerIdx = self:getMapMarkerIdx();
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not selectedMapMarkerIdx or not mapMarkerData then return; end

    sendClientCommand("MapMarkerSystem", "EditMarkerData",
        {
            selectedIdx = selectedMapMarkerIdx,
            newKey = "color",
            newValue = { r = color.r, g = color.g, b = color.b, a = 1 },
        }
    );
end

function MapMarkerManager:onPressedColorPickerMarkerNameBttn(button)
    self.colorPickerMarkerName:setX(getMouseX() - 100);
    self.colorPickerMarkerName:setY(getMouseY() - 20);
    self.colorPickerMarkerName.pickedFunc = self.onPickedMarkerNameColor;
    self.colorPickerMarkerName:setVisible(true);
    self.colorPickerMarkerName:bringToTop();
end

function MapMarkerManager:onPickedMarkerNameColor(color, mouseUp)
    self.currentColorMarkerName = ColorInfo.new(color.r, color.g, color.b, 1);
    self.colorPickerMarkerNameButton.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 };
    self.colorPickerMarkerName:setVisible(false);

    local selectedMapMarkerIdx = self:getMapMarkerIdx();
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not selectedMapMarkerIdx or not mapMarkerData then return; end

    sendClientCommand("MapMarkerSystem", "EditMarkerData",
        {
            selectedIdx = selectedMapMarkerIdx,
            newKey = "colorName",
            newValue = { r = color.r, g = color.g, b = color.b, a = 1 },
        }
    );
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

function MapMarkerManager:populateMarkersList(mapMarkers)
    local prevSelected = self.markersList.selected;
    self.markersList:clear();
    if not mapMarkers then
        MapMarkerSystem.MapMarkers = MapMarkerSystem.Shared.RequestMarkers();
    else
        MapMarkerSystem.MapMarkers = mapMarkers;
    end
    if MapMarkerSystem.MapMarkers then
        for i = 1, #MapMarkerSystem.MapMarkers do
            self.markersList:addItem(MapMarkerSystem.MapMarkers[i].name, MapMarkerSystem.MapMarkers[i]);
        end
        if #MapMarkerSystem.MapMarkers > 0 then
            if prevSelected and prevSelected <= #MapMarkerSystem.MapMarkers then
                self.markersList.selected = prevSelected;
                self:populateElementsDetails(MapMarkerSystem.MapMarkers[prevSelected]);
            else
                MapMarkerManager.instance.markersList.selected = 1;
                MapMarkerManager.instance:populateElementsDetails(MapMarkerSystem.MapMarkers[1]);
            end
        else
            self.markersList.selected = 0;
            self:populateElementsDetails(nil);
        end
    end
end

function MapMarkerManager:getMapMarkerIdx()
    return self.markersList and self.markersList.selected;
end

function MapMarkerManager:onTickBoxEnableMarkerOption(index, selected)
    local selectedMapMarkerIdx = self:getMapMarkerIdx();

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    mapMarkerData.isEnabled = selected;

    self.enableMarkerTickBox.selected[index] = selected;

    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = self:getMapMarkerIdx(),
        newKey = "isEnabled",
        newValue = selected
    });
end

function MapMarkerManager:onTickBoxEnableMarkerNameOption(index, selected)
    local selectedMapMarkerIdx = self:getMapMarkerIdx();

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    mapMarkerData.isNameEnabled = selected;

    self.enableMarkerNameTickBox.selected[index] = selected;

    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = self:getMapMarkerIdx(),
        newKey = "isNameEnabled",
        newValue = selected
    });
end

function MapMarkerManager:onChangeMarkerNameFont(comboBox, arg1, arg2)
    local selectedFont = comboBox:getSelectedText();
    if not selectedFont then return; end

    local selectedMapMarkerIdx = self:getMapMarkerIdx();
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = self:getMapMarkerIdx(),
        newKey = "nameFont",
        newValue = selectedFont
    });
end

function MapMarkerManager:onTickBoxFixedScaleOption(index, selected)
    local selectedMapMarkerIdx = self:getMapMarkerIdx();

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    mapMarkerData.lockZoom = selected;

    self.lockZoomTickBox.selected[index] = selected;

    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = self:getMapMarkerIdx(),
        newKey = "lockZoom",
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

    self.parent.markerNameEntryBox:setText(mapMarkerData.name);
end

function MapMarkerManager:onScaleInputChange()
    local scaleVal = self:getInternalText();
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx();

    if scaleVal == "" or not tonumber(scaleVal) then scaleVal = "1"; end

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    mapMarkerData[self.scaleType] = tonumber(scaleVal) and tonumber(scaleVal) or mapMarkerData[self.scaleType];

    sendClientCommand("MapMarkerSystem", "EditMarkerData",
        {
            selectedIdx = selectedMapMarkerIdx,
            newKey = self.scaleType,
            newValue = mapMarkerData[self.scaleType]
        }
    );
    self:setText(tostring(mapMarkerData[self.scaleType]));
end

function MapMarkerManager:onMaxZoomInputChange()
    local maxZoomVal = self:getInternalText();
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx();

    if maxZoomVal == "" or not tonumber(maxZoomVal) then maxZoomVal = "100"; end

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    mapMarkerData.maxZoomLevel = tonumber(maxZoomVal) and tonumber(maxZoomVal) or mapMarkerData.maxZoomLevel;

    sendClientCommand("MapMarkerSystem", "EditMarkerData",
        {
            selectedIdx = selectedMapMarkerIdx,
            newKey = "maxZoomLevel",
            newValue = mapMarkerData.maxZoomLevel
        }
    );
    self.parent.maxZoomEntryBox:setText(tostring(mapMarkerData.maxZoomLevel));
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
    local coordVal = tonumber(self:getInternalText()) or -1;

    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx();

    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx];
    if not mapMarkerData then return; end

    mapMarkerData.coordinates = mapMarkerData.coordinates or {};

    local defaultCoords = { x = -1, y = -1 };
    local function updateCoordinates(coordType, coordKey)
        local targetCoords = mapMarkerData.coordinates[coordKey] or defaultCoords;
        if coordType == "x" then
            targetCoords.x = coordVal;
        elseif coordType == "y" then
            targetCoords.y = coordVal;
        end
        mapMarkerData.coordinates[coordKey] = targetCoords;
    end

    local function sendCoordinate(coordKey, value)
        sendClientCommand("MapMarkerSystem", "EditMarkerData", {
            selectedIdx = selectedMapMarkerIdx,
            newKey = coordKey,
            newValue = value
        });
    end

    if mapMarkerData.markerType == "texture" then
        updateCoordinates(self.coordType:sub(1, 1), "center");
        local center = mapMarkerData.coordinates.center or { x = -1, y = -1 };
        if center.x ~= -1 and center.y ~= -1 then
            sendCoordinate("coordinates.center.x", center.x);
            sendCoordinate("coordinates.center.y", center.y);
        end
    elseif mapMarkerData.markerType == "rectangle" then
        if self.coordType == "x1" or self.coordType == "y1" then
            updateCoordinates(self.coordType:sub(1, 1), "center");
            local center = mapMarkerData.coordinates.center or { x = -1, y = -1 };
            if center.x ~= -1 and center.y ~= -1 then
                sendCoordinate("coordinates.center.x", center.x);
                sendCoordinate("coordinates.center.y", center.y);
            end
        else
            mapMarkerData.coordinates.width = self.coordType == "x2" and coordVal or mapMarkerData.coordinates.width;
            mapMarkerData.coordinates.height = self.coordType == "y2" and coordVal or mapMarkerData.coordinates.height;
            if not (mapMarkerData.coordinates.width < 1 or mapMarkerData.coordinates.height < 1) then
                sendCoordinate("coordinates.width", mapMarkerData.coordinates.width);
                sendCoordinate("coordinates.height", mapMarkerData.coordinates.height);
            end
        end
    elseif mapMarkerData.markerType == "area" then
        local coordKey = (self.coordType == "x1" or self.coordType == "y1") and "nw" or "se";
        updateCoordinates(self.coordType:sub(1, 1), coordKey);

        local nw = mapMarkerData.coordinates.nw or { x = -1, y = -1 };
        local se = mapMarkerData.coordinates.se or { x = -1, y = -1 };
        if nw.x ~= -1 and nw.y ~= -1 then
            sendCoordinate("coordinates.nw.x", nw.x);
            sendCoordinate("coordinates.nw.y", nw.y);
        end
        if se.x ~= -1 and se.y ~= -1 then
            sendCoordinate("coordinates.se.x", se.x);
            sendCoordinate("coordinates.se.y", se.y);
        end
    end
end

function MapMarkerManager:updateElementsPositions(markerData)
    local y = self.markersList:getBottom() + CONST.SECTION_SPACING;

    self.markerTypeLabel:setY(y);
    self.markerTypeValLabel:setY(y);
    y = self.markerTypeLabel:getBottom() + CONST.ITEM_SPACING;

    self.markerNameLabel:setY(y);
    self.markerNameEntryBox:setY(y);
    y = self.markerNameLabel:getBottom() + CONST.ITEM_SPACING;

    self.enableMarkerTickBox:setY(y);
    y = self.enableMarkerTickBox:getBottom() + CONST.ITEM_SPACING;

    if markerData.markerType == "rectangle" or markerData.markerType == "area" then
        self.enableMarkerNameTickBox:setY(y);
        y = self.enableMarkerNameTickBox:getBottom() + CONST.ITEM_SPACING;

        self.markerNameFontLabel:setY(y);
        self.markerNameFontComboBox:setY(y);
        y = self.markerNameFontComboBox:getBottom() + CONST.ITEM_SPACING;

        self.colorLabelMarkerName:setY(y);
        self.colorPickerMarkerNameButton:setY(y);
        y = self.colorLabelMarkerName:getBottom() + CONST.ITEM_SPACING;

        self.scaleNameLabel:setY(y);
        self.scaleNameEntryBox:setY(y);
        y = self.scaleNameLabel:getBottom() + CONST.ITEM_SPACING;
    end

    self.locationLabel:setY(y);
    self.nwXLabel:setY(y);
    self.nwYLabel:setY(y);
    self.nwXEntryBox:setY(y);
    self.nwYEntryBox:setY(y);
    self.pickNWButton:setY(y);
    y = self.locationLabel:getBottom() + CONST.ITEM_SPACING;

    if markerData.markerType == "texture" then
        self.textureLabel:setY(y);
        self.textureEntryBox:setY(y);
        y = self.textureLabel:getBottom() + CONST.ITEM_SPACING;

        self.scaleLabel:setY(y);
        self.scaleEntryBox:setY(y);
        y = self.scaleLabel:getBottom() + CONST.ITEM_SPACING;

        self.lockZoomTickBox:setY(y);
        y = self.lockZoomTickBox:getBottom() + CONST.ITEM_SPACING;
    elseif markerData.markerType == "rectangle" then
        self.seXLabel:setY(y);
        self.seXEntryBox:setY(y);
        self.seYLabel:setY(y);
        self.seYEntryBox:setY(y);
        y = self.seXLabel:getBottom() + CONST.ITEM_SPACING;

        self.colorLabelMarker:setY(y);
        self.colorPickerMarkerButton:setY(y);
        y = self.colorLabelMarker:getBottom() + CONST.ITEM_SPACING;

        self.scaleLabel:setY(y);
        self.scaleEntryBox:setY(y);
        y = self.scaleLabel:getBottom() + CONST.ITEM_SPACING;

        self.lockZoomTickBox:setY(y);
        y = self.lockZoomTickBox:getBottom() + CONST.ITEM_SPACING;
    elseif markerData.markerType == "area" then
        self.seXLabel:setY(y);
        self.seXEntryBox:setY(y);
        self.seYLabel:setY(y);
        self.seYEntryBox:setY(y);
        self.pickSEButton:setY(y);
        y = self.seXEntryBox:getBottom() + CONST.ITEM_SPACING;

        self.textureLabel:setVisible(false);
        self.textureEntryBox:setVisible(false);
        self.scaleLabel:setVisible(false);
        self.scaleEntryBox:setVisible(false);
        self.lockZoomTickBox:setVisible(false);

        self.colorLabelMarker:setY(y);
        self.colorPickerMarkerButton:setY(y);
        y = self.colorLabelMarker:getBottom() + CONST.ITEM_SPACING;
    end

    self.maxZoomLabel:setY(y);
    self.maxZoomEntryBox:setY(y);
end

function MapMarkerManager:populateElementsDetails(markerData)
    self.markerTypeValLabel:setName("");

    self.markerNameEntryBox:setText("");
    self.markerNameEntryBox:setEditable(false);

    self.enableMarkerTickBox:setSelected(1, false);

    self.enableMarkerNameTickBox:setSelected(1, false);
    self.markerNameFontComboBox:select(MapMarkerSystem.FontList[1]);

    self.colorPickerMarkerNameButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 };

    self.scaleNameEntryBox:setText("");
    self.scaleNameEntryBox:setEditable(false);

    self.nwXEntryBox:setText("");
    self.nwXEntryBox:setEditable(false);
    self.nwYEntryBox:setText("");
    self.nwYEntryBox:setEditable(false);

    self.seXEntryBox:setText("");
    self.seXEntryBox:setEditable(false);
    self.seYEntryBox:setText("");
    self.seYEntryBox:setEditable(false);

    self.textureEntryBox:setText("");
    self.textureEntryBox:setEditable(false);

    self.colorPickerMarkerButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 };

    self.scaleEntryBox:setText("");
    self.scaleEntryBox:setEditable(false);

    self.lockZoomTickBox:setSelected(1, false);

    self.maxZoomEntryBox:setText("");
    self.maxZoomEntryBox:setEditable(false);

    local componentsToHide = {
        'markerTypeLabel', 'markerTypeValLabel',
        'markerNameLabel', 'markerNameEntryBox',
        'enableMarkerTickBox',

        'enableMarkerNameTickBox',
        'markerNameFontLabel', 'markerNameFontComboBox',
        'colorLabelMarkerName', 'colorPickerMarkerNameButton',
        'scaleNameLabel', 'scaleNameEntryBox',

        'locationLabel',
        'nwXLabel', 'nwXEntryBox',
        'nwYLabel', 'nwYEntryBox', 'pickNWButton',
        'seXLabel', 'seXEntryBox',
        'seYLabel', 'seYEntryBox', 'pickSEButton',
        'textureLabel', 'textureEntryBox',
        'colorLabelMarker', 'colorPickerMarkerButton',
        'scaleLabel', 'scaleEntryBox',
        'lockZoomTickBox',
        'maxZoomLabel', 'maxZoomEntryBox'
    };
    for i = 1, #componentsToHide do
        local component = self[componentsToHide[i]];
        if component and component.setVisible then
            component:setVisible(false);
        end
    end

    if not markerData then return; end

    local markerTypes = {
        ["texture"] = getText("IGUI_MMS_TextureMarker"),
        ["rectangle"] = getText("IGUI_MMS_RectangleMarker"),
        ["area"] = getText("IGUI_MMS_AreaMarker")
    };

    self.markerTypeLabel:setVisible(true);
    self.markerTypeValLabel:setName(markerTypes[markerData.markerType] or "N/A");
    self.markerTypeValLabel:setVisible(true);

    self.markerNameLabel:setVisible(true);
    self.markerNameEntryBox:setText(markerData.name or "");
    self.markerNameEntryBox:setEditable(true);
    self.markerNameEntryBox:setVisible(true);

    self.enableMarkerTickBox:setVisible(true);
    self.enableMarkerTickBox:setSelected(1, markerData.isEnabled or false);

    self.locationLabel:setVisible(true);
    self.maxZoomLabel:setVisible(true);
    self.maxZoomEntryBox:setText(tostring(markerData.maxZoomLevel or ""));
    self.maxZoomEntryBox:setEditable(true);
    self.maxZoomEntryBox:setVisible(true);

    local typeConfigs = {
        ["texture"] = function()
            local center = markerData.coordinates.center or { x = -1, y = -1 };
            self.nwXLabel:setName(getText("IGUI_MMS_xCoord", ""));
            self.nwXEntryBox:setText(tostring(center.x or ""));
            self.nwXLabel:setVisible(true);
            self.nwXEntryBox:setVisible(true);
            self.nwXEntryBox:setEditable(true);

            self.nwYLabel:setName(getText("IGUI_MMS_yCoord", ""));
            self.nwYEntryBox:setText(tostring(center.y or ""));
            self.nwYLabel:setVisible(true);
            self.nwYEntryBox:setVisible(true);
            self.nwYEntryBox:setEditable(true);
            self.pickNWButton:setVisible(true);

            self.textureEntryBox:setText(markerData.texturePath or "");
            self.textureEntryBox:setEditable(true);
            self.textureLabel:setVisible(true);
            self.textureEntryBox:setVisible(true);

            self.scaleEntryBox:setText(tostring(markerData.scale or ""));
            self.scaleEntryBox:setEditable(true);
            self.scaleLabel:setVisible(true);
            self.scaleEntryBox:setVisible(true);

            self.lockZoomTickBox:setSelected(1, markerData.lockZoom or false);
            self.lockZoomTickBox:setVisible(true);
        end,
        ["rectangle"] = function()
            self.enableMarkerNameTickBox:setSelected(1, markerData.isNameEnabled or false);
            self.enableMarkerNameTickBox:setVisible(true);

            self.markerNameFontLabel:setVisible(true);

            self.markerNameFontComboBox:select(markerData.nameFont or MapMarkerSystem.FontList[1]);
            self.markerNameFontComboBox:setVisible(true);

            self.colorPickerMarkerNameButton.backgroundColor = markerData.colorName or { r = 1, g = 1, b = 1, a = 1 };
            self.colorLabelMarkerName:setVisible(true);
            self.colorPickerMarkerNameButton:setVisible(true);

            self.scaleNameEntryBox:setText(tostring(markerData.scaleName or ""));
            self.scaleNameEntryBox:setEditable(true);
            self.scaleNameLabel:setVisible(true);
            self.scaleNameEntryBox:setVisible(true);

            local center = markerData.coordinates.center or { x = -1, y = -1 };
            self.nwXLabel:setName(getText("IGUI_MMS_xCoord", ""));
            self.nwXEntryBox:setText(tostring(center.x or ""));
            self.nwXLabel:setVisible(true);
            self.nwXEntryBox:setVisible(true);
            self.nwXEntryBox:setEditable(true);

            self.nwYLabel:setName(getText("IGUI_MMS_yCoord", ""));
            self.nwYEntryBox:setText(tostring(center.y or ""));
            self.nwYLabel:setVisible(true);
            self.nwYEntryBox:setVisible(true);
            self.nwYEntryBox:setEditable(true);
            self.pickNWButton:setVisible(true);

            self.seXLabel:setName(getText("IGUI_MMS_wMarker"));
            self.seXEntryBox:setText(tostring(markerData.coordinates.width or ""));
            self.seXLabel:setVisible(true);
            self.seXEntryBox:setVisible(true);
            self.seXEntryBox:setEditable(true);

            self.seYLabel:setName(getText("IGUI_MMS_hMarker"));
            self.seYEntryBox:setText(tostring(markerData.coordinates.height or ""));
            self.seYLabel:setVisible(true);
            self.seYEntryBox:setVisible(true);
            self.seYEntryBox:setEditable(true);

            self.scaleEntryBox:setText(tostring(markerData.scale or ""));
            self.scaleEntryBox:setEditable(true);
            self.scaleLabel:setVisible(true);
            self.scaleEntryBox:setVisible(true);

            self.lockZoomTickBox:setSelected(1, markerData.lockZoom or false);
            self.lockZoomTickBox:setVisible(true);

            self.colorPickerMarkerButton.backgroundColor = markerData.color or { r = 1, g = 1, b = 1, a = 1 };
            self.colorLabelMarker:setVisible(true);
            self.colorPickerMarkerButton:setVisible(true);
        end,
        ["area"] = function()
            self.enableMarkerNameTickBox:setSelected(1, markerData.isNameEnabled or false);
            self.enableMarkerNameTickBox:setVisible(true);

            self.markerNameFontLabel:setVisible(true);

            self.markerNameFontComboBox:select(markerData.nameFont or MapMarkerSystem.FontList[1]);
            self.markerNameFontComboBox:setVisible(true);

            self.colorPickerMarkerNameButton.backgroundColor = markerData.colorName or { r = 1, g = 1, b = 1, a = 1 };
            self.colorLabelMarkerName:setVisible(true);
            self.colorPickerMarkerNameButton:setVisible(true);

            self.scaleNameEntryBox:setText(tostring(markerData.scaleName or ""));
            self.scaleNameEntryBox:setEditable(true);
            self.scaleNameLabel:setVisible(true);
            self.scaleNameEntryBox:setVisible(true);

            local nw = markerData.coordinates.nw or { x = -1, y = -1 };
            local se = markerData.coordinates.se or { x = -1, y = -1 };

            self.nwXLabel:setName(getText("IGUI_MMS_xCoord", "1"));
            self.nwXEntryBox:setText(tostring(nw.x or ""));
            self.nwXLabel:setVisible(true);
            self.nwXEntryBox:setVisible(true);
            self.nwXEntryBox:setEditable(true);

            self.nwYLabel:setName(getText("IGUI_MMS_yCoord", "1"));
            self.nwYEntryBox:setText(tostring(nw.y or ""));
            self.nwYLabel:setVisible(true);
            self.nwYEntryBox:setVisible(true);
            self.nwYEntryBox:setEditable(true);
            self.pickNWButton:setVisible(true);

            self.seXLabel:setName(getText("IGUI_MMS_xCoord", "2"));
            self.seXEntryBox:setText(tostring(se.x or ""));
            self.seXLabel:setVisible(true);
            self.seXEntryBox:setVisible(true);
            self.seXEntryBox:setEditable(true);

            self.seYLabel:setName(getText("IGUI_MMS_yCoord", "2"));
            self.seYEntryBox:setText(tostring(se.y or ""));
            self.seYLabel:setVisible(true);
            self.seYEntryBox:setVisible(true);
            self.seYEntryBox:setEditable(true);
            self.pickSEButton:setVisible(true);

            self.colorPickerMarkerButton.backgroundColor = markerData.color or { r = 1, g = 1, b = 1, a = 1 };
            self.colorLabelMarker:setVisible(true);
            self.colorPickerMarkerButton:setVisible(true);
        end
    };

    local tooltipConfigs = {
        ["texture"] = function()
            self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_TextureX"));
            self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_TextureY"));
            self.textureEntryBox:setTooltip(getText("Tooltip_MMS_TexturePath"));
        end,
        ["rectangle"] = function()
            self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_RectCenterX"));
            self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_RectCenterY"));
            self.seXEntryBox:setTooltip(getText("Tooltip_MMS_RectWidth"));
            self.seYEntryBox:setTooltip(getText("Tooltip_MMS_RectHeight"));
            self.colorPickerMarkerButton:setTooltip(getText("Tooltip_MMS_RectColorPicker"));
        end,
        ["area"] = function()
            self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_AreaX1"));
            self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_AreaY1"));
            self.seXEntryBox:setTooltip(getText("Tooltip_MMS_AreaX2"));
            self.seYEntryBox:setTooltip(getText("Tooltip_MMS_AreaY2"));
            self.colorPickerMarkerButton:setTooltip(getText("Tooltip_MMS_AreaColorPicker"));
        end
    };

    self.nwXEntryBox:setTooltip(nil);
    self.nwYEntryBox:setTooltip(nil);
    self.seXEntryBox:setTooltip(nil);
    self.seYEntryBox:setTooltip(nil);
    self.textureEntryBox:setTooltip(nil);
    self.colorPickerMarkerButton:setTooltip(nil);

    if typeConfigs[markerData.markerType] then
        typeConfigs[markerData.markerType]();
    end
    if tooltipConfigs[markerData.markerType] then
        tooltipConfigs[markerData.markerType]();
    end
    self:updateElementsPositions(markerData);
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

    local markerTypes = {
        ["texture"] = "[T]",
        ["rectangle"] = "[R]",
        ["area"] = "[A]"
    };
    local markerNameEntryBox = markerTypes[markerData.markerType] .. " " .. markerData.name;
    self:drawText(markerNameEntryBox, 15, y + itemPadY, textColor.r, textColor.g, textColor.b, 0.9, self.font);

    local coordsText = "";
    if markerData.markerType == "texture" or markerData.markerType == "rectangle" then
        coordsText = string.format("(%d, %d)", markerData.coordinates.center.x or 0, markerData.coordinates.center.y or 0);
    elseif markerData.markerType == "area" then
        local x1 = markerData.coordinates.nw.x;
        local y1 = markerData.coordinates.nw.y;
        local x2 = markerData.coordinates.se.x;
        local y2 = markerData.coordinates.se.y;
        coordsText = string.format("(%d,%d;%d,%d)", x1, y1, x2, y2);
    end

    local coordsWidth = getTextManager():MeasureStringX(UIFont.Small, coordsText);
    local coordsX = self:getWidth() - 15 - coordsWidth;
    self:drawText(coordsText, coordsX, y + itemPadY, 0.7, 0.7, 0.7, 0.9, UIFont.Small);

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

    self.parent:populateElementsDetails(item);
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
        local x, y = nil, nil;
        if mapMarkerData.markerType == "texture" or mapMarkerData.markerType == "rectangle" then
            x = mapMarkerData.coordinates.center.x;
            y = mapMarkerData.coordinates.center.y;
        elseif mapMarkerData.markerType == "area" then
            x = (mapMarkerData.coordinates.nw.x + mapMarkerData.coordinates.se.x) / 2;
            y = (mapMarkerData.coordinates.nw.y + mapMarkerData.coordinates.se.y) / 2;
        end
        self.playerObj:setX(x);
        self.playerObj:setY(y);
        self.playerObj:setZ(0.0);
        self.playerObj:setLx(x);
        self.playerObj:setLy(y);
    elseif button.internal == "DELETEMARKER" then
        local selectedMapMarkerIdx = self:getMapMarkerIdx();
        if not selectedMapMarkerIdx or not MapMarkerSystem.MapMarkers[selectedMapMarkerIdx] then return; end
        sendClientCommand("MapMarkerSystem", "RemoveMapMarker", { selectedIdx = selectedMapMarkerIdx });
        self.markersList.selected = 0;
        self.refresh = 3;
    elseif button.internal == "ADDMARKER" then
        local modal = AddMarkerModal:new(0, 0, 300, 200, getText("IGUI_MMS_AddMarker"), self, self.onAddMapMarker,
            self.playerNum);
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

function MapMarkerManager:onClickPickLocation(button)
    local isoPlayer = getPlayer();
    local x = math.floor(isoPlayer:getX());
    local y = math.floor(isoPlayer:getY());
    if button.internal == "PICK_NW" then
        self.nwXEntryBox:setText(tostring(x or ""));
        self.nwYEntryBox:setText(tostring(y or ""));
        self.nwXEntryBox:onTextChange();
        self.nwYEntryBox:onTextChange();
    elseif button.internal == "PICK_SE" then
        self.seXEntryBox:setText(tostring(x or ""));
        self.seYEntryBox:setText(tostring(y or ""));
        self.seXEntryBox:onTextChange();
        self.seYEntryBox:onTextChange();
    end
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
