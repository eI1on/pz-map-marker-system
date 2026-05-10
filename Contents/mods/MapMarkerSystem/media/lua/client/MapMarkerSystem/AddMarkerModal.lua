local MapMarkerSystem = require("MapMarkerSystem/Shared");
local Theme = require("ElyonLib/UI/Theme/Theme");
local AddMarkerModal = ISPanelJoypad:derive("AddMarkerModal");

local T = Theme.colors

local C = {
    PAD    = 20,
    ISPC   = 10,
    SSPC   = 15,
    EH     = 25,
    BH     = 30,
    BW     = 100,
    ENTRY_W = 200,
    COORD_W = 60,
    FONT = {
        SMALL  = UIFont.Small,
        MEDIUM = UIFont.Medium,
        LARGE  = UIFont.Large
    },
    MODAL_W = 335,
    MODAL_H = 450,
}

function AddMarkerModal:new(x, y, width, height, title, target, onclick, player)
    local o = ISPanelJoypad:new(x, y, C.MODAL_W, C.MODAL_H)
    setmetatable(o, self)
    self.__index = self

    local playerObj = player and getSpecificPlayer(player) or nil
    if y == 0 then
        if playerObj and playerObj:getJoypadBind() ~= -1 then
            o.y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - C.MODAL_H) / 2
        else
            o.y = o:getMouseY() - (C.MODAL_H / 2)
        end
        o:setY(o.y)
    end
    if x == 0 then
        if playerObj and playerObj:getJoypadBind() ~= -1 then
            o.x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - C.MODAL_W) / 2
        else
            o.x = o:getMouseX() - (C.MODAL_W / 2)
        end
        o:setX(o.x)
    end

    o.backgroundColor = Theme.copy(T.background)
    o.borderColor     = Theme.copy(T.border)
    o.width           = C.MODAL_W
    o.height          = C.MODAL_H
    o.anchorLeft      = true
    o.anchorRight     = true
    o.anchorTop       = true
    o.anchorBottom    = true
    o.moveWithMouse   = true
    o.target          = target
    o.onclick         = onclick
    o.player          = player
    o.title           = title
    o.currentType     = "texture"

    return o
end

function AddMarkerModal:updateUIPositions()
    local y = self.titleLabel:getBottom() + C.SSPC

    self.markerTypeLabel:setY(y)
    self.markerTypeRadio:setY(y)
    y = self.markerTypeLabel:getBottom() + 3 * C.SSPC

    self.nameLabel:setY(y)
    self.nameEntryBox:setY(y)
    y = self.nameLabel:getBottom() + C.ISPC

    if self.currentType == "texture" then
        self.locationLabel:setY(y)
        self.nwXLabel:setY(y)
        self.nwYLabel:setY(y)
        self.nwXEntryBox:setY(y)
        self.nwYEntryBox:setY(y)
        self.pickNWButton:setY(y)
        y = self.locationLabel:getBottom() + C.ISPC

        self.nwXLabel:setName(getText("IGUI_MMS_xCoord", ""))
        self.nwYLabel:setName(getText("IGUI_MMS_yCoord", ""))

        self.pickSEButton:setVisible(false)
        self.seXLabel:setVisible(false)
        self.seXEntryBox:setVisible(false)
        self.seYLabel:setVisible(false)
        self.seYEntryBox:setVisible(false)

        y = self:configureTextureFields(y)

        self.lockZoomTickBox:setVisible(true)
        self.lockZoomTickBox:setY(y)
        y = self.lockZoomTickBox:getBottom() + C.ISPC
    elseif self.currentType == "rectangle" then
        self.enableMarkerNameTickBox:setVisible(true)
        self.enableMarkerNameTickBox:setY(y)
        y = self.enableMarkerNameTickBox:getBottom() + C.ISPC

        self.markerNameFontLabel:setVisible(true)
        self.markerNameFontLabel:setY(y)
        self.markerNameFontComboBox:setVisible(true)
        self.markerNameFontComboBox:setY(y)
        y = self.markerNameFontComboBox:getBottom() + C.ISPC

        self.colorLabelMarkerName:setVisible(true)
        self.colorLabelMarkerName:setY(y)
        self.colorPickerMarkerNameButton:setVisible(true)
        self.colorPickerMarkerNameButton:setY(y)
        y = self.colorLabelMarkerName:getBottom() + C.ISPC

        self.scaleNameLabel:setVisible(true)
        self.scaleNameLabel:setY(y)
        self.scaleNameEntryBox:setVisible(true)
        self.scaleNameEntryBox:setY(y)
        y = self.scaleNameLabel:getBottom() + C.ISPC

        self.locationLabel:setY(y)
        self.nwXLabel:setY(y)
        self.nwYLabel:setY(y)
        self.nwXEntryBox:setY(y)
        self.nwYEntryBox:setY(y)
        self.pickNWButton:setY(y)
        y = self.locationLabel:getBottom() + C.ISPC

        self.nwXLabel:setName(getText("IGUI_MMS_xCoord", ""))
        self.nwYLabel:setName(getText("IGUI_MMS_yCoord", ""))

        self.pickSEButton:setVisible(false)

        self.seXLabel:setName(getText("IGUI_MMS_wMarker"))
        self.seYLabel:setName(getText("IGUI_MMS_hMarker"))
        self.seXLabel:setVisible(true)
        self.seXEntryBox:setVisible(true)
        self.seYLabel:setVisible(true)
        self.seYEntryBox:setVisible(true)
        self.seXLabel:setY(y)
        self.seXEntryBox:setY(y)
        self.seYLabel:setY(y)
        self.seYEntryBox:setY(y)
        y = self.seXEntryBox:getBottom() + C.ISPC

        y = self:configureRectangleFields(y)

        self.lockZoomTickBox:setVisible(true)
        self.lockZoomTickBox:setY(y)
        y = self.lockZoomTickBox:getBottom() + C.ISPC
    elseif self.currentType == "area" then
        self.enableMarkerNameTickBox:setVisible(true)
        self.enableMarkerNameTickBox:setY(y)
        y = self.enableMarkerNameTickBox:getBottom() + C.ISPC

        self.markerNameFontLabel:setVisible(true)
        self.markerNameFontLabel:setY(y)
        self.markerNameFontComboBox:setVisible(true)
        self.markerNameFontComboBox:setY(y)
        y = self.markerNameFontComboBox:getBottom() + C.ISPC

        self.colorLabelMarkerName:setVisible(true)
        self.colorLabelMarkerName:setY(y)
        self.colorPickerMarkerNameButton:setVisible(true)
        self.colorPickerMarkerNameButton:setY(y)
        y = self.colorLabelMarkerName:getBottom() + C.ISPC

        self.scaleNameLabel:setVisible(true)
        self.scaleNameLabel:setY(y)
        self.scaleNameEntryBox:setVisible(true)
        self.scaleNameEntryBox:setY(y)
        y = self.scaleNameLabel:getBottom() + C.ISPC

        self.locationLabel:setY(y)
        self.nwXLabel:setY(y)
        self.nwYLabel:setY(y)
        self.nwXEntryBox:setY(y)
        self.nwYEntryBox:setY(y)
        self.pickNWButton:setY(y)
        y = self.locationLabel:getBottom() + C.ISPC

        self.nwXLabel:setName(getText("IGUI_MMS_xCoord", "1"))
        self.nwYLabel:setName(getText("IGUI_MMS_yCoord", "1"))

        self.pickSEButton:setVisible(true)
        self.pickSEButton:setY(y)

        self.seXLabel:setName(getText("IGUI_MMS_xCoord", "2"))
        self.seYLabel:setName(getText("IGUI_MMS_yCoord", "2"))
        self.seXLabel:setVisible(true)
        self.seXEntryBox:setVisible(true)
        self.seYLabel:setVisible(true)
        self.seYEntryBox:setVisible(true)
        self.seXLabel:setY(y)
        self.seXEntryBox:setY(y)
        self.seYLabel:setY(y)
        self.seYEntryBox:setY(y)
        y = self.seXEntryBox:getBottom() + C.ISPC

        y = self:configureColorField(y)

        self.lockZoomTickBox:setVisible(false)
    end

    self.maxZoomLabel:setY(y)
    self.maxZoomEntryBox:setY(y)
    y = self.maxZoomEntryBox:getBottom() + C.ISPC

    self.okButton:setY(y + C.SSPC)
    self.cancelButton:setY(y + C.SSPC)

    self:setHeight(y + C.SSPC + C.BH + C.PAD)
end

function AddMarkerModal:configureRectangleFields(y)
    self.colorLabelMarker:setVisible(true)
    self.colorPickerMarkerButton:setVisible(true)
    self.colorLabelMarker:setY(y)
    self.colorPickerMarkerButton:setY(y)
    y = self.colorLabelMarker:getBottom() + C.ISPC

    self.scaleLabel:setVisible(true)
    self.scaleEntryBox:setVisible(true)
    self.scaleLabel:setY(y)
    self.scaleEntryBox:setY(y)
    y = self.scaleLabel:getBottom() + C.ISPC

    return y
end

function AddMarkerModal:configureTextureFields(y)
    self.textureLabel:setVisible(true)
    self.textureEntryBox:setVisible(true)
    self.textureLabel:setY(y)
    self.textureEntryBox:setY(y)
    y = self.textureLabel:getBottom() + C.ISPC

    self.scaleLabel:setVisible(true)
    self.scaleEntryBox:setVisible(true)
    self.scaleLabel:setY(y)
    self.scaleEntryBox:setY(y)
    y = self.scaleLabel:getBottom() + C.ISPC

    return y
end

function AddMarkerModal:configureColorField(y)
    self.colorLabelMarker:setVisible(true)
    self.colorPickerMarkerButton:setVisible(true)
    self.colorLabelMarker:setY(y)
    self.colorPickerMarkerButton:setY(y)
    y = self.colorLabelMarker:getBottom() + C.ISPC
    return y
end

function AddMarkerModal:onMarkerTypeChanged(buttons, index)
    local markerTypes = { "texture", "rectangle", "area" }
    self.currentType = markerTypes[index] or markerTypes[1]

    self.enableMarkerNameTickBox:setVisible(false)
    self.markerNameFontLabel:setVisible(false)
    self.markerNameFontComboBox:setVisible(false)
    self.colorLabelMarkerName:setVisible(false)
    self.colorPickerMarkerNameButton:setVisible(false)
    self.scaleNameLabel:setVisible(false)
    self.scaleNameEntryBox:setVisible(false)
    self.textureLabel:setVisible(false)
    self.textureEntryBox:setVisible(false)
    self.scaleLabel:setVisible(false)
    self.scaleEntryBox:setVisible(false)
    self.seXLabel:setVisible(false)
    self.seXEntryBox:setVisible(false)
    self.seYLabel:setVisible(false)
    self.seYEntryBox:setVisible(false)
    self.pickSEButton:setVisible(false)
    self.colorLabelMarker:setVisible(false)
    self.colorPickerMarkerButton:setVisible(false)

    self:updateTooltips()
    self:updateUIPositions()
    self:validateInputs()
end

function AddMarkerModal:updateTooltips()
    self.nwXEntryBox:setTooltip(nil)
    self.nwYEntryBox:setTooltip(nil)
    self.seXEntryBox:setTooltip(nil)
    self.seYEntryBox:setTooltip(nil)

    if self.currentType == "texture" then
        self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_TextureX"))
        self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_TextureY"))
    elseif self.currentType == "rectangle" then
        self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_RectCenterX"))
        self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_RectCenterY"))
        self.seXEntryBox:setTooltip(getText("Tooltip_MMS_RectWidth"))
        self.seYEntryBox:setTooltip(getText("Tooltip_MMS_RectHeight"))
        self.colorPickerMarkerButton:setTooltip(getText("Tooltip_MMS_RectColorPicker"))
    elseif self.currentType == "area" then
        self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_AreaX1"))
        self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_AreaY1"))
        self.seXEntryBox:setTooltip(getText("Tooltip_MMS_AreaX2"))
        self.seYEntryBox:setTooltip(getText("Tooltip_MMS_AreaY2"))
        self.colorPickerMarkerButton:setTooltip(getText("Tooltip_MMS_AreaColorPicker"))
    end
end

function AddMarkerModal:createChildren()
    local x = C.PAD
    local y = C.PAD

    self.titleLabel = ISLabel:new(
        (self.width - getTextManager():MeasureStringX(C.FONT.LARGE, getText("IGUI_MMS_AddNewMarker"))) / 2,
        y, C.EH, getText("IGUI_MMS_AddNewMarker"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.LARGE, true
    )
    self.titleLabel:initialise()
    self.titleLabel:instantiate()
    self:addChild(self.titleLabel)
    y = self.titleLabel:getBottom() + C.SSPC

    self.markerTypeLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerType"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.markerTypeLabel:initialise()
    self.markerTypeLabel:instantiate()
    self:addChild(self.markerTypeLabel)

    self.markerTypeRadio = ISRadioButtons:new(self.markerTypeLabel:getRight() + C.ISPC, y, C.ENTRY_W, C.EH, self, self.onMarkerTypeChanged)
    self.markerTypeRadio:initialise()
    self.markerTypeRadio:instantiate()
    self.markerTypeRadio.autoWidth = true
    self.markerTypeRadio.choicesColor = Theme.copy(T.text)
    self.markerTypeRadio:addOption(getText("IGUI_MMS_TextureMarker"))
    self.markerTypeRadio:addOption(getText("IGUI_MMS_RectangleMarker"))
    self.markerTypeRadio:addOption(getText("IGUI_MMS_AreaMarker"))
    self.markerTypeRadio:setSelected(1)
    self:addChild(self.markerTypeRadio)

    y = self.markerTypeRadio:getBottom() + C.SSPC

    self.nameLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_Name"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.nameLabel:initialise()
    self.nameLabel:instantiate()
    self:addChild(self.nameLabel)

    self.nameEntryBox = ISTextEntryBox:new("", self.markerTypeRadio:getX(), y, C.ENTRY_W, C.EH)
    self.nameEntryBox:initialise()
    self.nameEntryBox:instantiate()
    self.nameEntryBox:setTooltip(getText("Tooltip_MMS_MarkerName"))
    Theme.applyFieldStyle(self.nameEntryBox)
    self:addChild(self.nameEntryBox)
    y = self.nameLabel:getBottom() + C.ISPC

    self.enableMarkerNameTickBox = ISTickBox:new(x, y, C.COORD_W, C.EH)
    self.enableMarkerNameTickBox:initialise()
    self.enableMarkerNameTickBox:addOption(getText("IGUI_MMS_EnableMarkerName"))
    self.enableMarkerNameTickBox:setFont(C.FONT.MEDIUM)
    self.enableMarkerNameTickBox:setWidthToFit()
    self.enableMarkerNameTickBox.tooltip = getText("Tooltip_MMS_EnableMarkerName")
    Theme.applyTickBoxStyle(self.enableMarkerNameTickBox)
    self:addChild(self.enableMarkerNameTickBox)
    self.enableMarkerNameTickBox:setSelected(1, true)
    y = self.enableMarkerNameTickBox:getBottom() + C.ISPC

    self.markerNameFontLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerFontName"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.markerNameFontLabel:initialise()
    self.markerNameFontLabel:instantiate()
    self:addChild(self.markerNameFontLabel)

    self.markerNameFontComboBox = ISComboBox:new(self.markerTypeRadio:getX(), y, C.COORD_W, C.EH)
    self.markerNameFontComboBox.font = C.FONT.SMALL
    self.markerNameFontComboBox:initialise()
    self.markerNameFontComboBox:instantiate()
    self.markerNameFontComboBox:setWidthToOptions(150)
    Theme.applyComboStyle(self.markerNameFontComboBox)
    self:addChild(self.markerNameFontComboBox)
    for i = 1, #MapMarkerSystem.FontList do
        self.markerNameFontComboBox:addOption(MapMarkerSystem.FontList[i])
    end
    y = self.markerNameFontLabel:getBottom() + C.ISPC

    self.colorLabelMarkerName = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerNameColor"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.colorLabelMarkerName:initialise()
    self.colorLabelMarkerName:instantiate()
    self:addChild(self.colorLabelMarkerName)

    self.colorPickerMarkerNameButton = ISButton:new(self.markerTypeRadio:getX(), y, C.COORD_W, C.EH, "", self, self.onPressedColorPickerMarkerNameBttn)
    self.colorPickerMarkerNameButton:initialise()
    self.colorPickerMarkerNameButton:instantiate()
    self.colorPickerMarkerNameButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 }
    self.colorPickerMarkerNameButton.borderColor = Theme.copy(T.border)
    self.colorPickerMarkerNameButton:setTooltip(getText("Tooltip_MMS_MarkerNameColorPicker"))
    self:addChild(self.colorPickerMarkerNameButton)

    self.colorPickerMarkerName = ISColorPicker:new(0, 0)
    self.colorPickerMarkerName:initialise()
    self.colorPickerMarkerName.pickedTarget = self
    self.colorPickerMarkerName.resetFocusTo = self
    self.currentColorMarkerName = ColorInfo.new(1, 1, 1, 1)
    self.colorPickerMarkerName:setInitialColor(self.currentColorMarkerName)
    self.colorPickerMarkerName:addToUIManager()
    self.colorPickerMarkerName:setVisible(false)
    self.colorPickerMarkerName.otherFct = true
    self.colorPickerMarkerName.parent = self
    y = self.colorLabelMarkerName:getBottom() + C.ISPC

    self.scaleNameLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerNameScale"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.scaleNameLabel:initialise()
    self.scaleNameLabel:instantiate()
    self.scaleNameEntryBox = ISTextEntryBox:new("1", self.markerTypeRadio:getX(), y, C.COORD_W, C.EH)
    self.scaleNameEntryBox:initialise()
    self.scaleNameEntryBox:instantiate()
    self.scaleNameEntryBox:setOnlyNumbers(true)
    self.scaleNameEntryBox:setTooltip(getText("Tooltip_MMS_NameScale"))
    Theme.applyFieldStyle(self.scaleNameEntryBox)
    self:addChild(self.scaleNameLabel)
    self:addChild(self.scaleNameEntryBox)
    y = self.scaleNameLabel:getBottom() + C.ISPC

    self.locationLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_Location"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.locationLabel:initialise()
    self.locationLabel:instantiate()
    self:addChild(self.locationLabel)

    local halfIspc = C.ISPC / 2

    self.nwXLabel = ISLabel:new(self.markerTypeRadio:getX(), y, C.EH, getText("IGUI_MMS_xCoord", "1"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.nwXLabel:initialise()
    self.nwXLabel:instantiate()
    self:addChild(self.nwXLabel)

    self.nwXEntryBox = ISTextEntryBox:new("", self.nwXLabel:getRight() + halfIspc, y, C.COORD_W, C.EH)
    self.nwXEntryBox:initialise()
    self.nwXEntryBox:instantiate()
    self.nwXEntryBox:setOnlyNumbers(true)
    Theme.applyFieldStyle(self.nwXEntryBox)
    self:addChild(self.nwXEntryBox)

    self.nwYLabel = ISLabel:new(self.nwXEntryBox:getRight() + C.ISPC, y, C.EH, getText("IGUI_MMS_yCoord", "1"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.nwYLabel:initialise()
    self.nwYLabel:instantiate()
    self:addChild(self.nwYLabel)

    self.nwYEntryBox = ISTextEntryBox:new("", self.nwYLabel:getRight() + halfIspc, y, C.COORD_W, C.EH)
    self.nwYEntryBox:initialise()
    self.nwYEntryBox:instantiate()
    self.nwYEntryBox:setOnlyNumbers(true)
    Theme.applyFieldStyle(self.nwYEntryBox)
    self:addChild(self.nwYEntryBox)

    self.pickNWButton = ISButton:new(self.nwYEntryBox:getRight() + C.ISPC, y, C.EH, C.EH, "", self, self.onClickPickLocation)
    self.pickNWButton:initialise()
    self.pickNWButton:instantiate()
    self.pickNWButton.internal = "PICK_NW"
    self.pickNWButton:setImage(getTexture("media/ui/pick_current_location.png"))
    self.pickNWButton:setTooltip(getText("Tooltip_MMS_PickCurrentLocation"))
    self.pickNWButton.borderColor = Theme.copy(T.border)
    self:addChild(self.pickNWButton)
    y = self.locationLabel:getBottom() + C.ISPC

    self.seXLabel = ISLabel:new(self.markerTypeRadio:getX(), y, C.EH, getText("IGUI_MMS_xCoord", "2"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.seXLabel:initialise()
    self.seXLabel:instantiate()
    self:addChild(self.seXLabel)

    self.seXEntryBox = ISTextEntryBox:new("", self.seXLabel:getRight() + halfIspc, y, C.COORD_W, C.EH)
    self.seXEntryBox:initialise()
    self.seXEntryBox:instantiate()
    self.seXEntryBox:setOnlyNumbers(true)
    Theme.applyFieldStyle(self.seXEntryBox)
    self:addChild(self.seXEntryBox)

    self.seYLabel = ISLabel:new(self.seXEntryBox:getRight() + C.ISPC, y, C.EH, getText("IGUI_MMS_yCoord", "2"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.seYLabel:initialise()
    self.seYLabel:instantiate()
    self:addChild(self.seYLabel)

    self.seYEntryBox = ISTextEntryBox:new("", self.seYLabel:getRight() + halfIspc, y, C.COORD_W, C.EH)
    self.seYEntryBox:initialise()
    self.seYEntryBox:instantiate()
    self.seYEntryBox:setOnlyNumbers(true)
    Theme.applyFieldStyle(self.seYEntryBox)
    self:addChild(self.seYEntryBox)

    self.pickSEButton = ISButton:new(self.seYEntryBox:getRight() + C.ISPC, y, C.EH, C.EH, "", self, self.onClickPickLocation)
    self.pickSEButton:initialise()
    self.pickSEButton:instantiate()
    self.pickSEButton.internal = "PICK_SE"
    self.pickSEButton:setImage(getTexture("media/ui/pick_current_location.png"))
    self.pickSEButton:setTooltip(getText("Tooltip_MMS_PickCurrentLocation"))
    self.pickSEButton.borderColor = Theme.copy(T.border)
    self:addChild(self.pickSEButton)
    y = self.seXEntryBox:getBottom() + C.ISPC

    self.textureLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_Texture"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.textureLabel:initialise()
    self.textureLabel:instantiate()
    self:addChild(self.textureLabel)

    self.textureEntryBox = ISTextEntryBox:new("", self.markerTypeRadio:getX(), y, C.ENTRY_W, C.EH)
    self.textureEntryBox:initialise()
    self.textureEntryBox:instantiate()
    self.textureEntryBox:setTooltip(getText("Tooltip_MMS_TexturePath"))
    Theme.applyFieldStyle(self.textureEntryBox)
    self:addChild(self.textureEntryBox)
    y = self.textureLabel:getBottom() + C.ISPC

    self.scaleLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerScale"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.scaleLabel:initialise()
    self.scaleLabel:instantiate()
    self.scaleEntryBox = ISTextEntryBox:new("1", self.markerTypeRadio:getX(), y, C.COORD_W, C.EH)
    self.scaleEntryBox:initialise()
    self.scaleEntryBox:instantiate()
    self.scaleEntryBox:setOnlyNumbers(true)
    self.scaleEntryBox:setTooltip(getText("Tooltip_MMS_Scale"))
    Theme.applyFieldStyle(self.scaleEntryBox)
    self:addChild(self.scaleLabel)
    self:addChild(self.scaleEntryBox)
    y = self.scaleLabel:getBottom() + C.ISPC

    self.colorLabelMarker = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerColor"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.colorLabelMarker:initialise()
    self.colorLabelMarker:instantiate()
    self.colorPickerMarkerButton = ISButton:new(self.markerTypeRadio:getX(), y, C.COORD_W, C.EH, "", self, self.onPressedColorPickerMarkerBttn)
    self.colorPickerMarkerButton:initialise()
    self.colorPickerMarkerButton:instantiate()
    self.colorPickerMarkerButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 }
    self.colorPickerMarkerButton.borderColor = Theme.copy(T.border)
    self:addChild(self.colorLabelMarker)
    self:addChild(self.colorPickerMarkerButton)

    self.colorPickerMarker = ISColorPicker:new(0, 0)
    self.colorPickerMarker:initialise()
    self.colorPickerMarker.pickedTarget = self
    self.colorPickerMarker.resetFocusTo = self
    self.currentColorMarker = ColorInfo.new(1, 1, 1, 1)
    self.colorPickerMarker:setInitialColor(self.currentColorMarker)
    self.colorPickerMarker:addToUIManager()
    self.colorPickerMarker:setVisible(false)
    self.colorPickerMarker.otherFct = true
    self.colorPickerMarker.parent = self
    y = self.colorLabelMarker:getBottom() + C.ISPC

    self.lockZoomTickBox = ISTickBox:new(x, y, C.COORD_W, C.EH)
    self.lockZoomTickBox:initialise()
    self.lockZoomTickBox:addOption(getText("IGUI_MMS_FixedScale"))
    self.lockZoomTickBox:setFont(C.FONT.MEDIUM)
    self.lockZoomTickBox:setWidthToFit()
    self.lockZoomTickBox.tooltip = getText("Tooltip_MMS_FixedScale")
    Theme.applyTickBoxStyle(self.lockZoomTickBox)
    self:addChild(self.lockZoomTickBox)
    y = self.lockZoomTickBox:getBottom() + C.ISPC

    self.maxZoomLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MaxZoom"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.maxZoomLabel:initialise()
    self.maxZoomLabel:instantiate()
    self:addChild(self.maxZoomLabel)

    self.maxZoomEntryBox = ISTextEntryBox:new("100", self.markerTypeRadio:getX(), y, C.COORD_W, C.EH)
    self.maxZoomEntryBox:initialise()
    self.maxZoomEntryBox:instantiate()
    self.maxZoomEntryBox:setOnlyNumbers(true)
    self.maxZoomEntryBox.tooltip = getText("Tooltip_MMS_MaxZoom")
    Theme.applyFieldStyle(self.maxZoomEntryBox)
    self:addChild(self.maxZoomEntryBox)

    local buttonY = self.height - C.BH - C.PAD
    self.okButton = ISButton:new(self.width / 2 - C.BW - 5, buttonY, C.BW, C.BH, getText("IGUI_MMS_OK"), self, self.onClick)
    self.okButton:initialise()
    self.okButton:instantiate()
    self.okButton.internal = "OK"
    Theme.applyButtonStyle(self.okButton, "primary")
    self:addChild(self.okButton)

    self.cancelButton = ISButton:new(self.width / 2 + 5, buttonY, C.BW, C.BH, getText("IGUI_MMS_Cancel"), self, self.onClick)
    self.cancelButton:initialise()
    self.cancelButton:instantiate()
    self.cancelButton.internal = "CANCEL"
    Theme.applyButtonStyle(self.cancelButton)
    self:addChild(self.cancelButton)

    self:onMarkerTypeChanged(nil, 1)
end

function AddMarkerModal:onPressedColorPickerMarkerBttn(button)
    self.colorPickerMarker:setX(getMouseX() - 100)
    self.colorPickerMarker:setY(getMouseY() - 20)
    self.colorPickerMarker.pickedFunc = self.onPickedMarkerColor
    self.colorPickerMarker:setVisible(true)
    self.colorPickerMarker:bringToTop()
end

function AddMarkerModal:onPickedMarkerColor(color, mouseUp)
    self.currentColorMarker = ColorInfo.new(color.r, color.g, color.b, 1)
    self.colorPickerMarkerButton.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 }
    self.colorLabelMarker:setColor(color.r, color.g, color.b)
    self.colorPickerMarker:setVisible(false)
end

function AddMarkerModal:onPressedColorPickerMarkerNameBttn(button)
    self.colorPickerMarkerName:setX(getMouseX() - 100)
    self.colorPickerMarkerName:setY(getMouseY() - 20)
    self.colorPickerMarkerName.pickedFunc = self.onPickedMarkerNameColor
    self.colorPickerMarkerName:setVisible(true)
    self.colorPickerMarkerName:bringToTop()
end

function AddMarkerModal:onPickedMarkerNameColor(color, mouseUp)
    self.currentColorMarkerName = ColorInfo.new(color.r, color.g, color.b, 1)
    self.colorPickerMarkerNameButton.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 }
    self.colorLabelMarkerName:setColor(color.r, color.g, color.b)
    self.colorPickerMarkerName:setVisible(false)
end

local function textureExists(texture)
    return texture and texture ~= "" and getTexture(texture) or nil
end

function AddMarkerModal:validateInputs()
    self.okButton:setEnable(true)
    self.okButton.tooltip = nil
    local isValid = true
    local tooltip = ""

    if self.nameEntryBox:getText() == "" then
        isValid = false
        tooltip = tooltip .. getText("Tooltip_MMS_InvalidName") .. "\n"
    end

    local nwX = tonumber(self.nwXEntryBox:getText()) or -1
    local nwY = tonumber(self.nwYEntryBox:getText()) or -1
    if nwX <= 0 or nwY <= 0 then
        isValid = false
        tooltip = tooltip .. getText("Tooltip_MMS_InvalidCoordinates") .. "\n"
    end

    if self.currentType == "texture" then
        local textureString = self.textureEntryBox:getText()
        local texture = textureExists(textureString)
        self.textureEntryBox:setTooltip(nil)
        if not texture then
            isValid = false
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidTexture") .. " \n"
            self.textureEntryBox:setTooltip(getText("Tooltip_MMS_TexturePath"))
        else
            if self.textureEntryBox:isMouseOver() then
                local tx, ty = self:getMouseX() + 25, self:getMouseY() + 25
                local tw, th = texture:getWidth(), texture:getHeight()
                local maxDim = 400
                local aspect = tw / th
                if tw > maxDim or th > maxDim then
                    if aspect > 1 then
                        tw, th = maxDim, maxDim / aspect
                    else
                        tw, th = maxDim * aspect, maxDim
                    end
                end
                local padding = 5
                self:drawRect(tx - padding, ty - padding, tw + 2 * padding, th + 2 * padding, Theme.d(T.background))
                self:drawRectBorder(tx - padding, ty - padding, tw + 2 * padding, th + 2 * padding, Theme.d(T.border))
                self:drawTextureScaled(texture, tx, ty, tw, th, 1, 1, 1, 1)
            end
        end
        local scale = tonumber(self.scaleEntryBox:getText()) or 1
        if scale <= 0 then
            isValid = false
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidScale") .. "\n"
        end
    elseif self.currentType == "area" then
        local seX = tonumber(self.seXEntryBox:getText()) or -1
        local seY = tonumber(self.seYEntryBox:getText()) or -1
        if seX < nwX or seY < nwY then
            isValid = false
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidAreaCoordinates") .. "\n"
        end
    elseif self.currentType == "rectangle" then
        local seX = tonumber(self.seXEntryBox:getText()) or -1
        local seY = tonumber(self.seYEntryBox:getText()) or -1
        if seX <= 0 or seY <= 0 then
            isValid = false
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidSize") .. "\n"
        end
        local scale = tonumber(self.scaleEntryBox:getText()) or 0
        if scale <= 0 then
            isValid = false
            tooltip = tooltip .. getText("Tooltip_MMS_InvalidScale") .. "\n"
        end
    end

    local zoom = tonumber(self.maxZoomEntryBox:getText()) or 100
    if zoom <= 0 then
        isValid = false
        tooltip = tooltip .. getText("Tooltip_MMS_InvalidZoom") .. "\n"
    end

    if not isValid then
        self.okButton.tooltip = tooltip
    end
    self.okButton:setEnable(isValid)
end

function AddMarkerModal:render()
    ISPanelJoypad.render(self)
    self:validateInputs()
end

function AddMarkerModal:onClick(button)
    if button.internal == "CANCEL" then
        self:destroy()
    elseif button.internal == "OK" then
        local data = {
            name        = self.nameEntryBox:getText(),
            markerType  = self.currentType,
            isEnabled   = true,
            maxZoomLevel = 100,
        }

        if self.currentType == "texture" then
            data.coordinates = {
                center = {
                    x = tonumber(self.nwXEntryBox:getText()),
                    y = tonumber(self.nwYEntryBox:getText())
                }
            }
            data.texturePath = self.textureEntryBox:getText()
            data.scale       = tonumber(self.scaleEntryBox:getText())
            data.lockZoom    = self.lockZoomTickBox:isSelected(1)
        elseif self.currentType == "area" then
            data.isNameEnabled = self.enableMarkerNameTickBox:isSelected(1)
            data.colorName     = self.colorPickerMarkerNameButton.backgroundColor
            data.scaleName     = tonumber(self.scaleNameEntryBox:getText())
            data.nameFont      = self.markerNameFontComboBox:getSelectedText() or MapMarkerSystem.FontList[1]
            data.coordinates   = {
                nw = {
                    x = tonumber(self.nwXEntryBox:getText()),
                    y = tonumber(self.nwYEntryBox:getText())
                },
                se = {
                    x = tonumber(self.seXEntryBox:getText()),
                    y = tonumber(self.seYEntryBox:getText())
                }
            }
            data.color = self.colorPickerMarkerButton.backgroundColor
        elseif self.currentType == "rectangle" then
            data.isNameEnabled = self.enableMarkerNameTickBox:isSelected(1)
            data.colorName     = self.colorPickerMarkerNameButton.backgroundColor
            data.scaleName     = tonumber(self.scaleNameEntryBox:getText())
            data.nameFont      = self.markerNameFontComboBox and self.markerNameFontComboBox.selected or 1
            data.coordinates   = {
                center = {
                    x = tonumber(self.nwXEntryBox:getText()),
                    y = tonumber(self.nwYEntryBox:getText())
                },
                width  = tonumber(self.seXEntryBox:getText()),
                height = tonumber(self.seYEntryBox:getText())
            }
            data.color    = self.colorPickerMarkerButton.backgroundColor
            data.scale    = tonumber(self.scaleEntryBox:getText())
            data.lockZoom = self.lockZoomTickBox:isSelected(1)
        end

        if self.onclick then
            self.onclick(self.target, button, data)
        end
        self:destroy()
    end
end

function AddMarkerModal:onClickPickLocation(button)
    local isoPlayer = getPlayer()
    local px = math.floor(isoPlayer:getX())
    local py = math.floor(isoPlayer:getY())
    if button.internal == "PICK_NW" then
        self.nwXEntryBox:setText(tostring(px or ""))
        self.nwYEntryBox:setText(tostring(py or ""))
    elseif button.internal == "PICK_SE" then
        self.seXEntryBox:setText(tostring(px or ""))
        self.seYEntryBox:setText(tostring(py or ""))
    end
end

function AddMarkerModal:destroy()
    self:setVisible(false)
    self:removeFromUIManager()
end

return AddMarkerModal;
