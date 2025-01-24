local AddMarkerModal = ISPanelJoypad:derive("AddMarkerModal");

local CONST = {
    PADDING = 20,
    ELEMENT_HEIGHT = 25,
    MODAL_WIDTH = 335,
    MODAL_HEIGHT = 450,
    LABEL_WIDTH = 80,
    ENTRY_WIDTH = 200,
    COORD_ENTRY_WIDTH = 60,
    SECTION_SPACING = 15,
    ITEM_SPACING = 10,
    BUTTON_WIDTH = 100,
    BUTTON_HEIGHT = 30,
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

function AddMarkerModal:new(x, y, width, height, title, target, onclick, player)
    local o = ISPanelJoypad:new(x, y, CONST.MODAL_WIDTH, CONST.MODAL_HEIGHT);
    setmetatable(o, self);
    self.__index = self;

    local playerObj = player and getSpecificPlayer(player) or nil;
    if y == 0 then
        if playerObj and playerObj:getJoypadBind() ~= -1 then
            o.y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - CONST.MODAL_HEIGHT) / 2;
        else
            o.y = o:getMouseY() - (CONST.MODAL_HEIGHT / 2);
        end
        o:setY(o.y);
    end
    if x == 0 then
        if playerObj and playerObj:getJoypadBind() ~= -1 then
            o.x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - CONST.MODAL_WIDTH) / 2;
        else
            o.x = o:getMouseX() - (CONST.MODAL_WIDTH / 2);
        end
        o:setX(o.x);
    end

    o.backgroundColor = CONST.COLORS.BACKGROUND;
    o.borderColor = CONST.COLORS.BORDER;
    o.width = CONST.MODAL_WIDTH;
    o.height = CONST.MODAL_HEIGHT;
    o.anchorLeft = true;
    o.anchorRight = true;
    o.anchorTop = true;
    o.anchorBottom = true;
    o.moveWithMouse = true;

    o.target = target;
    o.onclick = onclick;
    o.player = player;
    o.title = title;
    o.currentType = "texture";

    return o;
end

function AddMarkerModal:updateUIPositions()
    local y = self.titleLabel:getBottom() + CONST.SECTION_SPACING;

    self.markerTypeLabel:setY(y);
    self.markerTypeRadio:setY(y);
    y = self.markerTypeLabel:getBottom() + 3 * CONST.SECTION_SPACING;

    self.nameLabel:setY(y);
    self.nameEntryBox:setY(y);
    y = self.nameLabel:getBottom() + CONST.ITEM_SPACING;

    local coordinateConfigs = {
        texture = {
            nwXLabel = getText("IGUI_MMS_xCoord", ""),
            nwYLabel = getText("IGUI_MMS_yCoord", ""),
            seXLabel = nil,
            seYLabel = nil,
            showSecondCoords = false,
            showPickSEButton = false,
            showFixedScale = true,
            additionalFields = self.configureTextureFields
        },
        rectangle = {
            nwXLabel = getText("IGUI_MMS_xCoord", ""),
            nwYLabel = getText("IGUI_MMS_yCoord", ""),
            seXLabel = getText("IGUI_MMS_wMarker"),
            seYLabel = getText("IGUI_MMS_hMarker"),
            showSecondCoords = true,
            showPickSEButton = false,
            showFixedScale = true,
            additionalFields = self.configureRectangleFields
        },
        area = {
            nwXLabel = getText("IGUI_MMS_xCoord", "1"),
            nwYLabel = getText("IGUI_MMS_yCoord", "1"),
            seXLabel = getText("IGUI_MMS_xCoord", "2"),
            seYLabel = getText("IGUI_MMS_yCoord", "2"),
            showSecondCoords = true,
            showPickSEButton = true,
            showFixedScale = false,
            additionalFields = self.configureColorField
        }
    }

    self.locationLabel:setY(y);
    self.nwXLabel:setY(y);
    self.nwYLabel:setY(y);
    self.nwXEntryBox:setY(y);
    self.nwYEntryBox:setY(y);
    self.pickNWButton:setY(y);
    y = self.locationLabel:getBottom() + CONST.ITEM_SPACING;

    local config = coordinateConfigs[self.currentType];

    self.nwXLabel:setName(config.nwXLabel);
    self.nwYLabel:setName(config.nwYLabel);

    if config.showPickSEButton then
        self.pickSEButton:setVisible(true);
        self.pickSEButton:setY(y);
    else
        self.pickSEButton:setVisible(false);
    end

    if config.showSecondCoords then
        self.seXLabel:setName(config.seXLabel);
        self.seYLabel:setName(config.seYLabel);
        self.seXLabel:setVisible(true);
        self.seXEntryBox:setVisible(true);
        self.seYLabel:setVisible(true);
        self.seYEntryBox:setVisible(true);
        self.seXLabel:setY(y);
        self.seXEntryBox:setY(y);
        self.seYLabel:setY(y);
        self.seYEntryBox:setY(y);
        y = self.seXEntryBox:getBottom() + CONST.ITEM_SPACING;
    else
        self.seXLabel:setVisible(false);
        self.seXEntryBox:setVisible(false);
        self.seYLabel:setVisible(false);
        self.seYEntryBox:setVisible(false);
    end

    y = config.additionalFields(self, y);

    if config.showFixedScale then
        self.lockZoomTickBox:setVisible(true);
        self.lockZoomTickBox:setY(y);
        y = self.lockZoomTickBox:getBottom() + CONST.ITEM_SPACING;
    else
        self.lockZoomTickBox:setVisible(false);
    end

    self.maxZoomLabel:setY(y);
    self.maxZoomEntryBox:setY(y);
    y = self.maxZoomEntryBox:getBottom() + CONST.ITEM_SPACING;

    local buttonY = math.max(y + CONST.SECTION_SPACING, self.height - CONST.BUTTON_HEIGHT - CONST.PADDING);
    self.okButton:setY(buttonY);
    self.cancelButton:setY(buttonY);
end

function AddMarkerModal:configureRectangleFields(y)
    self.colorLabel:setVisible(true);
    self.colorPickerButton:setVisible(true);
    self.colorLabel:setY(y);
    self.colorPickerButton:setY(y);
    y = self.colorLabel:getBottom() + CONST.ITEM_SPACING;

    self.scaleLabel:setVisible(true);
    self.scaleEntryBox:setVisible(true);
    self.scaleLabel:setY(y);
    self.scaleEntryBox:setY(y);
    y = self.scaleLabel:getBottom() + CONST.ITEM_SPACING;

    return y;
end

function AddMarkerModal:configureTextureFields(y)
    self.textureLabel:setVisible(true);
    self.textureEntryBox:setVisible(true);
    self.textureLabel:setY(y);
    self.textureEntryBox:setY(y);
    y = self.textureLabel:getBottom() + CONST.ITEM_SPACING;

    self.scaleLabel:setVisible(true);
    self.scaleEntryBox:setVisible(true);
    self.scaleLabel:setY(y);
    self.scaleEntryBox:setY(y);
    y = self.scaleLabel:getBottom() + CONST.ITEM_SPACING;

    return y;
end

function AddMarkerModal:configureColorField(y)
    self.colorLabel:setVisible(true);
    self.colorPickerButton:setVisible(true);
    self.colorLabel:setY(y);
    self.colorPickerButton:setY(y);
    y = self.colorLabel:getBottom() + CONST.ITEM_SPACING;

    return y;
end

function AddMarkerModal:onMarkerTypeChanged(buttons, index)
    local markerTypes = { "texture", "rectangle", "area" };
    self.currentType = markerTypes[index] or markerTypes[1];

    self.textureLabel:setVisible(false);
    self.textureEntryBox:setVisible(false);
    self.scaleLabel:setVisible(false);
    self.scaleEntryBox:setVisible(false);

    self.seXLabel:setVisible(false);
    self.seXEntryBox:setVisible(false);

    self.seYLabel:setVisible(false);
    self.seYEntryBox:setVisible(false);
    self.pickSEButton:setVisible(false);

    self.colorLabel:setVisible(false);
    self.colorPickerButton:setVisible(false);

    self:updateTooltips();
    self:updateUIPositions();
    self:validateInputs();
end

function AddMarkerModal:updateTooltips()
    self.nwXEntryBox:setTooltip(nil);
    self.nwYEntryBox:setTooltip(nil);
    self.seXEntryBox:setTooltip(nil);
    self.seYEntryBox:setTooltip(nil);
    self.textureEntryBox:setTooltip(nil);
    self.scaleEntryBox:setTooltip(nil);

    if self.currentType == "texture" then
        self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_TextureX"));
        self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_TextureY"));
        self.textureEntryBox:setTooltip(getText("Tooltip_MMS_TexturePath"));
        self.scaleEntryBox:setTooltip(getText("Tooltip_MMS_Scale"));
    elseif self.currentType == "rectangle" then
        self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_RectCenterX"));
        self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_RectCenterY"));
        self.seXEntryBox:setTooltip(getText("Tooltip_MMS_RectWidth"));
        self.seYEntryBox:setTooltip(getText("Tooltip_MMS_RectHeight"));
        self.scaleEntryBox:setTooltip(getText("Tooltip_MMS_Scale"));
        self.colorPickerButton:setTooltip(getText("Tooltip_MMS_RectColorPicker"));
    elseif self.currentType == "area" then
        self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_AreaX1"));
        self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_AreaY1"));
        self.seXEntryBox:setTooltip(getText("Tooltip_MMS_AreaX2"));
        self.seYEntryBox:setTooltip(getText("Tooltip_MMS_AreaY2"));
        self.colorPickerButton:setTooltip(getText("Tooltip_MMS_AreaColorPicker"));
    end
end

function AddMarkerModal:createChildren()
    local x = CONST.PADDING;
    local y = CONST.PADDING;

    -- Title
    self.titleLabel = ISLabel:new(
        (self.width - getTextManager():MeasureStringX(CONST.FONT.LARGE, getText("IGUI_MMS_AddNewMarker"))) / 2,
        y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_AddNewMarker"), 1, 1, 1, 1, CONST.FONT.LARGE, true
    );
    self.titleLabel:initialise();
    self.titleLabel:instantiate();
    self:addChild(self.titleLabel);
    y = self.titleLabel:getBottom() + CONST.SECTION_SPACING;

    -- Marker Type Selection
    self.markerTypeLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_MarkerType"), 1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.markerTypeLabel:initialise();
    self.markerTypeLabel:instantiate();
    self:addChild(self.markerTypeLabel);

    self.markerTypeRadio = ISRadioButtons:new(self.markerTypeLabel:getRight() + CONST.ITEM_SPACING, y, CONST.ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT, self, self.onMarkerTypeChanged);
    self.markerTypeRadio:initialise();
    self.markerTypeRadio:instantiate();
    self:addChild(self.markerTypeRadio);
    self.markerTypeRadio.autoWidth = true;
    self.markerTypeRadio:addOption(getText("IGUI_MMS_TextureMarker"));
    self.markerTypeRadio:addOption(getText("IGUI_MMS_RectangleMarker"));
    self.markerTypeRadio:addOption(getText("IGUI_MMS_AreaMarker"));
    self.markerTypeRadio:setSelected(1);

    y = self.markerTypeRadio:getBottom() + CONST.SECTION_SPACING;

    -- Name
    self.nameLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Name"), 1, 1, 1, 1, CONST.FONT.MEDIUM,
        true);
    self.nameLabel:initialise();
    self.nameLabel:instantiate();
    self:addChild(self.nameLabel);

    self.nameEntryBox = ISTextEntryBox:new("", self.markerTypeRadio:getX(), y, CONST.ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.nameEntryBox:initialise();
    self.nameEntryBox:instantiate();
    self.nameEntryBox:setTooltip(getText("Tooltip_MMS_MarkerName"));
    self:addChild(self.nameEntryBox);
    y = self.nameLabel:getBottom() + CONST.ITEM_SPACING;

    -- Coordinates (NW/Center)
    self.locationLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Location"), 1, 1, 1, 1, CONST.FONT
        .MEDIUM, true);
    self.locationLabel:initialise();
    self.locationLabel:instantiate();
    self:addChild(self.locationLabel);

    self.nwXLabel = ISLabel:new(self.markerTypeRadio:getX(), y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_xCoord", "1"), 1,
        1, 1, 1, CONST.FONT.MEDIUM, true);
    self.nwXLabel:initialise();
    self.nwXLabel:instantiate();
    self:addChild(self.nwXLabel);
    self.nwXEntryBox = ISTextEntryBox:new("", self.nwXLabel:getRight() + CONST.ITEM_SPACING / 2, y, CONST.COORD_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.nwXEntryBox:initialise();
    self.nwXEntryBox:instantiate();
    self.nwXEntryBox:setOnlyNumbers(true);
    self:addChild(self.nwXEntryBox);

    self.nwYLabel = ISLabel:new(self.nwXEntryBox:getRight() + CONST.ITEM_SPACING, y, CONST.ELEMENT_HEIGHT,
        getText("IGUI_MMS_yCoord", "1"), 1, 1, 1, 1, CONST.FONT.MEDIUM, true);
    self.nwYLabel:initialise();
    self.nwYLabel:instantiate();
    self:addChild(self.nwYLabel);
    self.nwYEntryBox = ISTextEntryBox:new("", self.nwYLabel:getRight() + CONST.ITEM_SPACING / 2, y, CONST.COORD_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.nwYEntryBox:initialise();
    self.nwYEntryBox:instantiate();
    self.nwYEntryBox:setOnlyNumbers(true);
    self:addChild(self.nwYEntryBox);

    self.pickNWButton = ISButton:new(self.nwYEntryBox:getRight() + CONST.ITEM_SPACING, y, CONST.ELEMENT_HEIGHT, CONST.ELEMENT_HEIGHT, "", self, self.onClickPickLocation);
    self.pickNWButton:initialise();
    self.pickNWButton:instantiate();
    self.pickNWButton.internal = "PICK_NW";
    self.pickNWButton:setImage(getTexture("media/ui/pick_current_location.png"));
    self.pickNWButton:setTooltip(getText("Tooltip_MMS_PickCurrentLocation"));
    self.pickNWButton.borderColor = CONST.COLORS.BORDER;
    self:addChild(self.pickNWButton);
    y = self.locationLabel:getBottom() + CONST.ITEM_SPACING;

    -- SE Coordinates for Area Type Marker, Width and Height for Rectangle Type
    self.seXLabel = ISLabel:new(self.markerTypeRadio:getX(), y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_xCoord", "2"), 1,
        1, 1, 1, CONST.FONT.MEDIUM, true);
    self.seXLabel:initialise();
    self.seXLabel:instantiate();
    self:addChild(self.seXLabel);
    self.seXEntryBox = ISTextEntryBox:new("", self.seXLabel:getRight() + CONST.ITEM_SPACING / 2, y, CONST.COORD_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.seXEntryBox:initialise();
    self.seXEntryBox:instantiate();
    self.seXEntryBox:setOnlyNumbers(true);
    self:addChild(self.seXEntryBox);

    self.seYLabel = ISLabel:new(self.seXEntryBox:getRight() + CONST.ITEM_SPACING, y, CONST.ELEMENT_HEIGHT,
        getText("IGUI_MMS_yCoord", "2"), 1, 1, 1, 1, CONST.FONT.MEDIUM, true);
    self.seYLabel:initialise();
    self.seYLabel:instantiate();
    self:addChild(self.seYLabel);
    self.seYEntryBox = ISTextEntryBox:new("", self.seYLabel:getRight() + CONST.ITEM_SPACING / 2, y, CONST.COORD_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.seYEntryBox:initialise();
    self.seYEntryBox:instantiate();
    self.seYEntryBox:setOnlyNumbers(true);
    self:addChild(self.seYEntryBox);

    self.pickSEButton = ISButton:new(self.seYEntryBox:getRight() + CONST.ITEM_SPACING, y, CONST.ELEMENT_HEIGHT, CONST.ELEMENT_HEIGHT, "", self, self.onClickPickLocation);
    self.pickSEButton:initialise();
    self.pickSEButton:instantiate();
    self.pickSEButton.internal = "PICK_SE";
    self.pickSEButton:setImage(getTexture("media/ui/pick_current_location.png"));
    self.pickSEButton:setTooltip(getText("Tooltip_MMS_PickCurrentLocation"));
    self.pickSEButton.borderColor = CONST.COLORS.BORDER;
    self:addChild(self.pickSEButton);
    y = self.seXEntryBox:getBottom() + CONST.ITEM_SPACING;

    -- Texture specific controls
    self.textureLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Texture"), 1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.textureLabel:initialise();
    self.textureLabel:instantiate();
    self.textureEntryBox = ISTextEntryBox:new("", self.markerTypeRadio:getX(), y, CONST.ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.textureEntryBox:initialise();
    self.textureEntryBox:instantiate();
    self:addChild(self.textureLabel);
    self:addChild(self.textureEntryBox);
    y = self.textureLabel:getBottom() + CONST.ITEM_SPACING;

    self.scaleLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Scale"), 1, 1, 1, 1, CONST.FONT.MEDIUM,
        true);
    self.scaleLabel:initialise();
    self.scaleLabel:instantiate();
    self.scaleEntryBox = ISTextEntryBox:new("1", self.markerTypeRadio:getX(), y, CONST.COORD_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.scaleEntryBox:initialise();
    self.scaleEntryBox:instantiate();
    self.scaleEntryBox:setOnlyNumbers(true);
    self.scaleEntryBox:setTooltip(getText("Tooltip_MMS_Scale"));
    self:addChild(self.scaleLabel);
    self:addChild(self.scaleEntryBox);
    y = self.scaleLabel:getBottom() + CONST.ITEM_SPACING;


    -- Rectangle and Area specific controls
    self.colorLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Color"), 1, 1, 1, 1, CONST.FONT.MEDIUM,
        true);
    self.colorLabel:initialise();
    self.colorLabel:instantiate();
    self.colorPickerButton = ISButton:new(self.markerTypeRadio:getX(), y, CONST.COORD_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT,
        "", self, self.onColorPicker);
    self.colorPickerButton:initialise();
    self.colorPickerButton:instantiate();
    self.colorPickerButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 };
    self:addChild(self.colorLabel);
    self:addChild(self.colorPickerButton);

    self.colorPicker = ISColorPicker:new(0, 0)
    self.colorPicker:initialise()
    self.colorPicker.pickedTarget = self
    self.colorPicker.resetFocusTo = self
    self.currentColor = ColorInfo.new(1, 1, 1, 1);
    self.colorPicker:setInitialColor(self.currentColor);
    self.colorPicker:addToUIManager();
    self.colorPicker:setVisible(false);
    self.colorPicker.otherFct = true;
    self.colorPicker.parent = self;
    y = self.colorLabel:getBottom() + CONST.ITEM_SPACING;

    -- Add Fixed Scale control
    self.lockZoomTickBox = ISTickBox:new(x, y, CONST.COORD_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
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

    self.maxZoomEntryBox = ISTextEntryBox:new("100", self.markerTypeRadio:getX(), y, CONST.COORD_ENTRY_WIDTH,
        CONST.ELEMENT_HEIGHT);
    self.maxZoomEntryBox:initialise();
    self.maxZoomEntryBox:instantiate();
    self.maxZoomEntryBox:setOnlyNumbers(true);
    self.maxZoomEntryBox.tooltip = getText("Tooltip_MMS_MaxZoom");
    self:addChild(self.maxZoomEntryBox);

    -- Buttons
    local buttonY = self.height - CONST.BUTTON_HEIGHT - CONST.PADDING;
    self.okButton = ISButton:new(self.width / 2 - CONST.BUTTON_WIDTH - 5, buttonY, CONST.BUTTON_WIDTH,
        CONST.BUTTON_HEIGHT, getText("IGUI_MMS_OK"), self, self.onClick);
    self.okButton:initialise();
    self.okButton:instantiate();
    self.cancelButton = ISButton:new(self.width / 2 + 5, buttonY, CONST.BUTTON_WIDTH, CONST.BUTTON_HEIGHT,
        getText("IGUI_MMS_Cancel"), self, self.onClick);
    self.cancelButton:initialise();
    self.cancelButton:instantiate();
    self.okButton.internal = "OK";
    self.cancelButton.internal = "CANCEL";
    self:addChild(self.okButton);
    self:addChild(self.cancelButton);

    self:onMarkerTypeChanged(nil, 1);
end

function AddMarkerModal:onColorPicker(button)
    self.colorPicker:setX(getMouseX() - 100);
    self.colorPicker:setY(getMouseY() - 20);
    self.colorPicker.pickedFunc = self.onPickedColor;
    self.colorPicker:setVisible(true);
    self.colorPicker:bringToTop();
end

function AddMarkerModal:onPickedColor(color, mouseUp)
    self.currentColor = ColorInfo.new(color.r, color.g, color.b, 1);
    self.colorPickerButton.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 };
    self.colorLabel:setColor(color.r, color.g, color.b);
    self.colorPicker:setVisible(false);
end

local function textureExists(texture)
    return texture and texture ~= "" and getTexture(texture) or nil;
end

function AddMarkerModal:validateInputs()
    self.okButton:setEnable(true);
    self.okButton.tooltip = nil;
    local isValid = true;
    local tooltip = "";

    if self.nameEntryBox:getText() == "" then
        isValid = false;
        tooltip = tooltip .. getText("Tooltip_MMS_InvalidName") .. "\n";
    end

    local nwX = tonumber(self.nwXEntryBox:getText()) or -1;
    local nwY = tonumber(self.nwYEntryBox:getText()) or -1;
    if nwX <= 0 or nwY <= 0 then
        isValid = false;
        tooltip = tooltip .. getText("Tooltip_MMS_InvalidCoordinates") .. "\n";
    end

    if self.currentType == "texture" then
        local textureString = self.textureEntryBox:getText();
        local texture = textureExists(textureString);

        self.textureEntryBox:setTooltip(nil);
        if not texture then
            isValid = false;
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidTexture") .. " \n";
            self.textureEntryBox:setTooltip(getText("Tooltip_MMS_TexturePath"));
        else
            -- media/ui/quest1.png
            if self.textureEntryBox:isMouseOver() then
                local x, y = self:getMouseX() + 25, self:getMouseY() + 25;
                local w, h = texture:getWidth(), texture:getHeight();
                local maxDim = 400;
                local aspect = w / h;
                if w > maxDim or h > maxDim then
                    if aspect > 1 then
                        w, h = maxDim, maxDim / aspect;
                    else
                        w, h = maxDim * aspect, maxDim;
                    end
                end
                local padding = 5;
                self:drawRect(x - padding, y - padding, w + 2 * padding, h + 2 * padding, CONST.COLORS.BACKGROUND.a,
                    CONST.COLORS.BACKGROUND.r, CONST.COLORS.BACKGROUND.g, CONST.COLORS.BACKGROUND.b);
                self:drawRectBorder(x - padding, y - padding, w + 2 * padding, h + 2 * padding, CONST.COLORS.BORDER.a,
                    CONST.COLORS.BORDER.r, CONST.COLORS.BORDER.g, CONST.COLORS.BORDER.b);
                self:drawTextureScaled(texture, x, y, w, h, 1, 1, 1, 1);
            end
        end

        local scale = tonumber(self.scaleEntryBox:getText()) or 0;
        if scale <= 0 then
            isValid = false;
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidScale") .. "\n";
        end
    elseif self.currentType == "area" then
        local seX = tonumber(self.seXEntryBox:getText()) or -1;
        local seY = tonumber(self.seYEntryBox:getText()) or -1;
        if seX < nwX or seY < nwY then
            isValid = false;
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidAreaCoordinates") .. "\n";
        end
    elseif self.currentType == "rectangle" then
        local seX = tonumber(self.seXEntryBox:getText()) or -1;
        local seY = tonumber(self.seYEntryBox:getText()) or -1;
        if seX <= 0 or seY <= 0 then
            isValid = false;
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidSize") .. "\n";
        end

        local scale = tonumber(self.scaleEntryBox:getText()) or 0;
        if scale <= 0 then
            isValid = false;
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidScale") .. "\n";
        end
    end

    local zoom = tonumber(self.maxZoomEntryBox:getText()) or -1;
    if zoom <= 0 then
        isValid = false;
        tooltip = tooltip .. getText("Tooltip_MMS_InvalidZoom") .. "\n";
    end

    if isValid then
        self.okButton.tooltip = nil;
    else
        self.okButton.tooltip = tooltip;
    end
    self.okButton:setEnable(isValid);
end

function AddMarkerModal:prerender()
    ISPanelJoypad.prerender(self);
    self:validateInputs();
end

function AddMarkerModal:onClick(button)
    if button.internal == "CANCEL" then
        self:destroy();
    elseif button.internal == "OK" then
        local data = {
            name = self.nameEntryBox:getText(),
            markerType = self.currentType,
            isEnabled = true,
            maxZoomLevel = 100,
        };

        if self.currentType == "texture" then
            data.coordinates = {
                center = {
                    x = tonumber(self.nwXEntryBox:getText()),
                    y = tonumber(self.nwYEntryBox:getText())
                }
            };
            data.texturePath = self.textureEntryBox:getText();
            data.scale = tonumber(self.scaleEntryBox:getText());
            data.lockZoom = self.lockZoomTickBox:isSelected(1);
        elseif self.currentType == "area" then
            data.coordinates = {
                nw = {
                    x = tonumber(self.nwXEntryBox:getText()),
                    y = tonumber(self.nwYEntryBox:getText())
                },
                se = {
                    x = tonumber(self.seXEntryBox:getText()),
                    y = tonumber(self.seYEntryBox:getText())
                }
            };
            data.color = self.colorPickerButton.backgroundColor;
        elseif self.currentType == "rectangle" then
            data.coordinates = {
                center = {
                    x = tonumber(self.nwXEntryBox:getText()),
                    y = tonumber(self.nwYEntryBox:getText())
                },
                width = tonumber(self.seXEntryBox:getText()),
                height = tonumber(self.seYEntryBox:getText())
            };
            data.color = self.colorPickerButton.backgroundColor;
            data.scale = tonumber(self.scaleEntryBox:getText());
            data.lockZoom = self.lockZoomTickBox:isSelected(1);
        end

        if self.onclick then
            self.onclick(self.target, button, data);
        end
        self:destroy();
    end
end

function AddMarkerModal:onClickPickLocation(button)
    local isoPlayer = getPlayer();
    local x = math.floor(isoPlayer:getX());
    local y = math.floor(isoPlayer:getY());
    if button.internal == "PICK_NW" then
        self.nwXEntryBox:setText(tostring(x or ""));
        self.nwYEntryBox:setText(tostring(y or ""));
    elseif button.internal == "PICK_SE" then
        self.seXEntryBox:setText(tostring(x or ""));
        self.seYEntryBox:setText(tostring(y or ""));
    end
end

function AddMarkerModal:destroy()
    self:setVisible(false);
    self:removeFromUIManager();
end

return AddMarkerModal;
