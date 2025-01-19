---@diagnostic disable: undefined-field
local AddMarkerModal = ISPanelJoypad:derive("AddMarkerModal");

local CONST = {
    PADDING = 20,
    ELEMENT_HEIGHT = 25,
    MODAL_WIDTH = 325,
    MODAL_HEIGHT = 250,
    LABEL_WIDTH = 80,
    ENTRY_WIDTH = 200,
    COORD_ENTRY_WIDTH = 70,
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

function AddMarkerModal:new(x, y, width, height, title, defaultEntryText, target, onclick, player)
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

    o.defaultEntryText = defaultEntryText;
    o.target = target;
    o.onclick = onclick;
    o.player = player;
    o.title = title;

    return o;
end

function AddMarkerModal:initialise()
    ISPanelJoypad.initialise(self);
    self:createChildren();
end

function AddMarkerModal:createChildren()
    local x = CONST.PADDING;
    local y = CONST.PADDING;

    -- Title centered at the top
    local titleText = getText("IGUI_MMS_AddNewMarker");
    local titleWidth = getTextManager():MeasureStringX(CONST.FONT.LARGE, titleText);
    self.titleLabel = ISLabel:new((self.width - titleWidth) / 2, y, CONST.ELEMENT_HEIGHT, titleText, 1, 1, 1, 1,
        CONST.FONT.LARGE, true);
    self.titleLabel:initialise();
    self:addChild(self.titleLabel);
    y = y + CONST.ELEMENT_HEIGHT + CONST.SECTION_SPACING;

    -- Name Section
    self.nameLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Name"), 1, 1, 1, 1, CONST.FONT.MEDIUM,
        true);
    self.nameLabel:initialise();
    self:addChild(self.nameLabel);

    self.nameEntry = ISTextEntryBox:new("", x + CONST.LABEL_WIDTH, y, CONST.ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.nameEntry:initialise();
    self.nameEntry:instantiate();
    self:addChild(self.nameEntry);
    y = y + CONST.ELEMENT_HEIGHT + CONST.ITEM_SPACING;

    -- Coordinates Section
    self.coordLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Location"), 1, 1, 1, 1, CONST.FONT
        .MEDIUM, true);
    self.coordLabel:initialise();
    self:addChild(self.coordLabel);

    local coordX = x + CONST.LABEL_WIDTH;
    self.xLabel = ISLabel:new(coordX, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_xCoord"), 1, 1, 1, 1, CONST.FONT.MEDIUM,
        true);
    self.xLabel:initialise();
    self:addChild(self.xLabel);

    self.xEntry = ISTextEntryBox:new("", coordX + 25, y, CONST.COORD_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.xEntry:initialise();
    self.xEntry:instantiate();
    self.xEntry:setOnlyNumbers(true);
    self:addChild(self.xEntry);

    self.yLabel = ISLabel:new(coordX + CONST.COORD_ENTRY_WIDTH + 35, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_yCoord"),
        1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.yLabel:initialise();
    self:addChild(self.yLabel);

    self.yEntry = ISTextEntryBox:new("", self.yLabel:getRight() + 5, y, CONST.COORD_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.yEntry:initialise();
    self.yEntry:instantiate();
    self.yEntry:setOnlyNumbers(true);
    self:addChild(self.yEntry);
    y = y + CONST.ELEMENT_HEIGHT + CONST.ITEM_SPACING;

    -- Scale Section
    self.scaleLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Scale"), 1, 1, 1, 1, CONST.FONT.MEDIUM,
        true);
    self.scaleLabel:initialise();
    self:addChild(self.scaleLabel);

    self.scaleEntry = ISTextEntryBox:new("", x + CONST.LABEL_WIDTH, y, CONST.COORD_ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.scaleEntry:initialise();
    self.scaleEntry:instantiate();
    self.scaleEntry:setOnlyNumbers(true);
    self:addChild(self.scaleEntry);
    y = y + CONST.ELEMENT_HEIGHT + CONST.ITEM_SPACING;

    -- Texture Section
    self.textureLabel = ISLabel:new(x, y, CONST.ELEMENT_HEIGHT, getText("IGUI_MMS_Texture"), 1, 1, 1, 1,
        CONST.FONT.MEDIUM, true);
    self.textureLabel:initialise();
    self:addChild(self.textureLabel);

    self.textureEntry = ISTextEntryBox:new("", x + CONST.LABEL_WIDTH, y, CONST.ENTRY_WIDTH, CONST.ELEMENT_HEIGHT);
    self.textureEntry:initialise();
    self.textureEntry:instantiate();
    self:addChild(self.textureEntry);

    -- Buttons at the bottom
    local buttonY = self.height - CONST.BUTTON_HEIGHT - CONST.PADDING;
    local buttonCenterX = self.width / 2;

    self.okButton = ISButton:new(buttonCenterX - CONST.BUTTON_WIDTH - 5, buttonY, CONST.BUTTON_WIDTH, CONST
        .BUTTON_HEIGHT, getText("IGUI_MMS_OK"), self, AddMarkerModal.onClick);
    self.okButton.internal = "OK";
    self.okButton:initialise();
    self.okButton:setFont(CONST.FONT.MEDIUM);
    self:addChild(self.okButton);

    self.cancelButton = ISButton:new(buttonCenterX + 5, buttonY, CONST.BUTTON_WIDTH, CONST.BUTTON_HEIGHT,
        getText("IGUI_MMS_Cancel"), self,
        AddMarkerModal.onClick);
    self.cancelButton.internal = "CANCEL";
    self.cancelButton:initialise();
    self.cancelButton:setFont(CONST.FONT.MEDIUM);
    self:addChild(self.cancelButton);

    self:validateInputs();
end

local function textureExists(texture)
    return texture and texture ~= "" and getTexture(texture) or nil;
end

function AddMarkerModal:validateInputs()
    self.okButton:setEnable(true);
    self.okButton.tooltip = nil;
    local isValid = true;
    local tooltip = "";

    local name = self.nameEntry:getText();
    if name == "" then
        isValid = false;
        tooltip = tooltip .. getText("IGUI_MMS_InvalidName") .. " \n";
    end

    local xEntry = tonumber(self.xEntry:getText()) or -1;
    local yEntry = tonumber(self.yEntry:getText()) or -1;
    if xEntry < 0 or yEntry < 0 then
        isValid = false;
        tooltip = tooltip .. getText("IGUI_MMS_InvalidCoordinates") .. " \n";
    end

    local scale = tonumber(self.scaleEntry:getText()) or 0;
    if scale <= 0 then
        isValid = false;
        tooltip = tooltip .. getText("IGUI_MMS_InvalidScale") .. " \n";
    end

    local textureString = self.textureEntry:getText();
    local texture = textureExists(textureString);
    if not texture then
        isValid = false;
        tooltip = tooltip .. getText("IGUI_MMS_InvalidTexture") .. " \n";
    else
        -- media/ui/quest1.png
        if self.textureEntry:isMouseOver() then
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
        if self.onclick then
            self.onclick(self.target, button, {
                name = self.nameEntry:getText(),
                coordinates = {
                    x = tonumber(self.xEntry:getText()),
                    y = tonumber(self.yEntry:getText()),
                },
                scale = tonumber(self.scaleEntry:getText()),
                texturePath = self.textureEntry:getText(),
                isEnabled = true,
            });
        end
        self:destroy();
    end
end

function AddMarkerModal:destroy()
    self:setVisible(false);
    self:removeFromUIManager();
end

return AddMarkerModal;