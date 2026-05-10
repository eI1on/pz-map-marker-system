local Logger = require("MapMarkerSystem/Logger");
local FileUtils = require("ElyonLib/FileUtils/FileUtils");
local MapMarkerSystem = require("MapMarkerSystem/Shared");
local AddMarkerModal = require("MapMarkerSystem/AddMarkerModal");
local Theme = require("ElyonLib/UI/Theme/Theme");

local MapMarkerManager = ISCollapsableWindowJoypad:derive("MapMarkerManager");
MapMarkerManager.instance = nil;

local T = Theme.colors

local C = {
    PAD            = 10,
    ISPC           = 5,
    SSPC           = 10,
    EH             = 25,
    BH             = 25,
    COORD_W        = 50,
    MIN_LIST_H     = 60,
    DETAILS_RESERVE = 320,
    FONT = {
        SMALL  = UIFont.Small,
        MEDIUM = UIFont.Medium,
        LARGE  = UIFont.Large
    },
    MIN_W = 460,
    MIN_H = 500,
    DEF_W = 480,
    DEF_H = 800,
}

function MapMarkerManager:new(x, y, w, h, playerObj)
    local o = ISCollapsableWindowJoypad.new(self, x, y, w, h)
    o:setResizable(true)
    o.character       = playerObj
    o.playerObj       = playerObj
    o.playerNum       = playerObj and playerObj:getPlayerNum() or -1
    o.title           = getText("IGUI_MMS_MapMarkerSystem")
    o.minimumWidth    = C.MIN_W
    o.minimumHeight   = C.MIN_H
    o.borderColor     = Theme.copy(T.border)
    o.backgroundColor = Theme.copy(T.background)
    return o
end

function MapMarkerManager:createChildren()
    ISCollapsableWindowJoypad.createChildren(self)
    local th  = self:titleBarHeight()
    local x   = C.PAD
    local y   = th + C.PAD
    local w   = self:getWidth()

    self.exportButton = ISButton:new(0, y, 90, C.BH, getText("IGUI_MMS_Export"), self, self.onExport)
    self.exportButton:initialise()
    self.exportButton:instantiate()
    self.exportButton:setFont(C.FONT.SMALL)
    self.exportButton:setWidthToTitle(10)
    Theme.applyButtonStyle(self.exportButton)
    self:addChild(self.exportButton)

    self.importButton = ISButton:new(0, y, 90, C.BH, getText("IGUI_MMS_Import"), self, self.onImport)
    self.importButton:initialise()
    self.importButton:instantiate()
    self.importButton:setFont(C.FONT.SMALL)
    self.importButton:setWidthToTitle(10)
    Theme.applyButtonStyle(self.importButton)
    self:addChild(self.importButton)

    self.exportButton:setX(w - self.exportButton:getWidth() - C.PAD)
    self.importButton:setX(self.exportButton:getX() - self.importButton:getWidth() - C.PAD)

    y = y + C.BH + C.ISPC

    local bw = math.max(60, math.floor((w - C.PAD * 4) / 3))

    self.addMarkerBtn = ISButton:new(C.PAD, y, bw, C.BH, getText("IGUI_MMS_AddMarker"), self, MapMarkerManager.onClickBttn)
    self.addMarkerBtn.internal = "ADDMARKER"
    self.addMarkerBtn:initialise()
    self.addMarkerBtn:instantiate()
    self.addMarkerBtn:setFont(C.FONT.SMALL)
    Theme.applyButtonStyle(self.addMarkerBtn, "primary")
    self:addChild(self.addMarkerBtn)

    self.teleportBtn = ISButton:new(C.PAD * 2 + bw, y, bw, C.BH, getText("IGUI_MMS_Teleport"), self, MapMarkerManager.onClickBttn)
    self.teleportBtn.internal = "TELEPORT"
    self.teleportBtn:initialise()
    self.teleportBtn:instantiate()
    self.teleportBtn:setFont(C.FONT.SMALL)
    Theme.applyButtonStyle(self.teleportBtn)
    self:addChild(self.teleportBtn)

    self.deleteMarkerBtn = ISButton:new(C.PAD * 3 + bw * 2, y, bw, C.BH, getText("IGUI_MMS_Delete"), self, MapMarkerManager.onClickBttn)
    self.deleteMarkerBtn.internal = "DELETEMARKER"
    self.deleteMarkerBtn:initialise()
    self.deleteMarkerBtn:instantiate()
    self.deleteMarkerBtn:setFont(C.FONT.SMALL)
    Theme.applyButtonStyle(self.deleteMarkerBtn, "danger")
    self:addChild(self.deleteMarkerBtn)

    y = y + C.BH + C.SSPC

    local listH = math.max(C.MIN_LIST_H, C.DEF_H - y - C.SSPC - C.DETAILS_RESERVE - C.PAD)
    self.markersList = ISScrollingListBox:new(x, y, w - C.PAD * 2, listH)
    self.markersList:initialise()
    self.markersList:instantiate()
    self.markersList:setFont(C.FONT.MEDIUM, 7)
    self.markersList.doDrawItem = self.drawMapMarkersListItem
    self.markersList.onMouseDown = self.onMouseDownMapMarkersList
    Theme.applyListStyle(self.markersList)
    self.markersList.drawBorder = true
    self:addChild(self.markersList)

    y = y + listH + C.SSPC

    self.markerTypeLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerType"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.markerTypeLabel:initialise()
    self.markerTypeLabel:instantiate()
    self:addChild(self.markerTypeLabel)

    self.valX = self.markerTypeLabel:getRight() + C.SSPC
    local valX = self.valX

    self.markerTypeValLabel = ISLabel:new(valX, y, C.EH, "", T.textMuted.r, T.textMuted.g, T.textMuted.b, T.textMuted.a, C.FONT.MEDIUM, true)
    self.markerTypeValLabel:initialise()
    self.markerTypeValLabel:instantiate()
    self:addChild(self.markerTypeValLabel)
    y = self.markerTypeLabel:getBottom() + C.ISPC

    self.markerNameLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_Name"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.markerNameLabel:initialise()
    self:addChild(self.markerNameLabel)

    self.markerNameEntryBox = ISTextEntryBox:new("", valX, y, w - valX - C.PAD, C.EH)
    self.markerNameEntryBox:initialise()
    self.markerNameEntryBox:instantiate()
    self.markerNameEntryBox:setTooltip(getText("Tooltip_MMS_MarkerName"))
    self.markerNameEntryBox.onTextChange = self.onMarkerNameInputChange
    Theme.applyFieldStyle(self.markerNameEntryBox)
    self:addChild(self.markerNameEntryBox)
    y = self.markerNameLabel:getBottom() + C.ISPC

    self.enableMarkerTickBox = ISTickBox:new(x, y, C.EH * 4, C.EH, "", self, MapMarkerManager.onTickBoxEnableMarkerOption)
    self.enableMarkerTickBox:initialise()
    self.enableMarkerTickBox:addOption(getText("IGUI_MMS_EnableMarker"))
    self.enableMarkerTickBox:setFont(C.FONT.MEDIUM)
    self.enableMarkerTickBox:setWidthToFit()
    self.enableMarkerTickBox.tooltip = getText("Tooltip_MMS_EnableMarker")
    Theme.applyTickBoxStyle(self.enableMarkerTickBox)
    self:addChild(self.enableMarkerTickBox)
    y = self.enableMarkerTickBox:getBottom() + C.ISPC

    self.enableMarkerNameTickBox = ISTickBox:new(x, y, C.EH * 4, C.EH, "", self, MapMarkerManager.onTickBoxEnableMarkerNameOption)
    self.enableMarkerNameTickBox:initialise()
    self.enableMarkerNameTickBox:addOption(getText("IGUI_MMS_EnableMarkerName"))
    self.enableMarkerNameTickBox:setFont(C.FONT.MEDIUM)
    self.enableMarkerNameTickBox:setWidthToFit()
    self.enableMarkerNameTickBox.tooltip = getText("Tooltip_MMS_EnableMarkerName")
    Theme.applyTickBoxStyle(self.enableMarkerNameTickBox)
    self:addChild(self.enableMarkerNameTickBox)
    y = self.enableMarkerNameTickBox:getBottom() + C.ISPC

    self.markerNameFontLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerFontName"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.markerNameFontLabel:initialise()
    self.markerNameFontLabel:instantiate()
    self:addChild(self.markerNameFontLabel)

    self.markerNameFontComboBox = ISComboBox:new(valX, y, 150, C.EH)
    self.markerNameFontComboBox.font = C.FONT.SMALL
    self.markerNameFontComboBox:initialise()
    self.markerNameFontComboBox:instantiate()
    self.markerNameFontComboBox:setWidthToOptions(150)
    self.markerNameFontComboBox.onChange = self.onChangeMarkerNameFont
    self.markerNameFontComboBox.target = self
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

    self.colorPickerMarkerNameButton = ISButton:new(valX, y, 50, C.EH, "", self, self.onPressedColorPickerMarkerNameBttn)
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
    self.scaleNameEntryBox = ISTextEntryBox:new("1", valX, y, 50, C.EH)
    self.scaleNameEntryBox:initialise()
    self.scaleNameEntryBox:instantiate()
    self.scaleNameEntryBox.onTextChange = self.onScaleInputChange
    self.scaleNameEntryBox.scaleType = "scaleName"
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

    self.nwXLabel = ISLabel:new(valX, y, C.EH, getText("IGUI_MMS_xCoord", "1"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.nwXLabel:initialise()
    self.nwXLabel:instantiate()
    self:addChild(self.nwXLabel)

    self.nwXEntryBox = ISTextEntryBox:new("", self.nwXLabel:getRight() + halfIspc, y, C.COORD_W, C.EH)
    self.nwXEntryBox:initialise()
    self.nwXEntryBox:instantiate()
    self.nwXEntryBox.coordType = "x1"
    self.nwXEntryBox.onTextChange = self.onCoordsInputChange
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
    self.nwYEntryBox.coordType = "y1"
    self.nwYEntryBox.onTextChange = self.onCoordsInputChange
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

    self.seXLabel = ISLabel:new(valX, y, C.EH, getText("IGUI_MMS_xCoord", "2"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.seXLabel:initialise()
    self.seXLabel:instantiate()
    self:addChild(self.seXLabel)

    self.seXEntryBox = ISTextEntryBox:new("", self.seXLabel:getRight() + halfIspc, y, C.COORD_W, C.EH)
    self.seXEntryBox:initialise()
    self.seXEntryBox:instantiate()
    self.seXEntryBox.coordType = "x2"
    self.seXEntryBox.onTextChange = self.onCoordsInputChange
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
    self.seYEntryBox.coordType = "y2"
    self.seYEntryBox.onTextChange = self.onCoordsInputChange
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
    y = self.seXLabel:getBottom() + C.ISPC

    self.textureLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_Texture"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.textureLabel:initialise()
    self:addChild(self.textureLabel)

    self.textureEntryBox = ISTextEntryBox:new("", valX, y, w - valX - C.PAD, C.EH)
    self.textureEntryBox:initialise()
    self.textureEntryBox:instantiate()
    self.textureEntryBox.onTextChange = self.onTextureInputChange
    Theme.applyFieldStyle(self.textureEntryBox)
    self:addChild(self.textureEntryBox)
    y = self.textureLabel:getBottom() + C.ISPC

    self.colorLabelMarker = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerColor"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.colorLabelMarker:initialise()
    self.colorLabelMarker:instantiate()
    self:addChild(self.colorLabelMarker)

    self.colorPickerMarkerButton = ISButton:new(valX, y, 50, C.EH, "", self, self.onPressedColorPickerMarkerBttn)
    self.colorPickerMarkerButton:initialise()
    self.colorPickerMarkerButton:instantiate()
    self.colorPickerMarkerButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 }
    self.colorPickerMarkerButton.borderColor = Theme.copy(T.border)
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

    self.scaleLabel = ISLabel:new(x, y, C.EH, getText("IGUI_MMS_MarkerScale"), T.text.r, T.text.g, T.text.b, T.text.a, C.FONT.MEDIUM, true)
    self.scaleLabel:initialise()
    self:addChild(self.scaleLabel)

    self.scaleEntryBox = ISTextEntryBox:new("", valX, y, 50, C.EH)
    self.scaleEntryBox:initialise()
    self.scaleEntryBox:instantiate()
    self.scaleEntryBox.onTextChange = self.onScaleInputChange
    self.scaleEntryBox.scaleType = "scale"
    self.scaleEntryBox:setTooltip(getText("Tooltip_MMS_Scale"))
    Theme.applyFieldStyle(self.scaleEntryBox)
    self:addChild(self.scaleEntryBox)
    y = self.scaleLabel:getBottom() + C.ISPC

    self.lockZoomTickBox = ISTickBox:new(x, y, C.EH * 4, C.EH, "", self, MapMarkerManager.onTickBoxFixedScaleOption)
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

    self.maxZoomEntryBox = ISTextEntryBox:new("", valX, y, 50, C.EH)
    self.maxZoomEntryBox:initialise()
    self.maxZoomEntryBox:instantiate()
    self.maxZoomEntryBox.onTextChange = self.onMaxZoomInputChange
    self.maxZoomEntryBox:setOnlyNumbers(true)
    self.maxZoomEntryBox.tooltip = getText("Tooltip_MMS_MaxZoom")
    Theme.applyFieldStyle(self.maxZoomEntryBox)
    self:addChild(self.maxZoomEntryBox)

    self:populateElementsDetails(nil)
    self.refresh = 3
end

function MapMarkerManager:layoutChildren()
    local w    = self:getWidth()
    local pad  = C.PAD
    local valX = self.valX or 0

    local expW = self.exportButton:getWidth()
    local impW = self.importButton:getWidth()
    self.exportButton:setX(w - expW - pad)
    self.importButton:setX(w - expW - impW - pad * 2)

    local bw = math.max(60, math.floor((w - pad * 4) / 3))
    self.addMarkerBtn:setWidth(bw)
    self.addMarkerBtn:setX(pad)
    self.teleportBtn:setWidth(bw)
    self.teleportBtn:setX(pad * 2 + bw)
    self.deleteMarkerBtn:setWidth(bw)
    self.deleteMarkerBtn:setX(pad * 3 + bw * 2)

    self.markersList:setWidth(w - pad * 2)

    local listH = math.max(C.MIN_LIST_H, self:getHeight() - self.markersList:getY() - C.SSPC - C.DETAILS_RESERVE - pad)
    self.markersList:setHeight(listH)

    self.markerNameEntryBox:setWidth(w - valX - pad)
    self.textureEntryBox:setWidth(w - valX - pad)

    local selIdx = self.markersList and self.markersList.selected
    local markerData = selIdx and selIdx > 0 and MapMarkerSystem.MapMarkers and MapMarkerSystem.MapMarkers[selIdx]
    if markerData then
        self:updateElementsPositions(markerData)
    end
end

function MapMarkerManager:onResize()
    ISUIElement.onResize(self)
    self:layoutChildren()
end

function MapMarkerManager:prerender()
    ISCollapsableWindowJoypad.prerender(self)
    if self.refresh and self.refresh > 0 then
        self.refresh = self.refresh - 1
        if self.refresh <= 0 then
            self:populateElements()
        end
    end
end

function MapMarkerManager:populateElements()
    self:populateMarkersList()
end

function MapMarkerManager:populateMarkersList(mapMarkers)
    local prevSelected = self.markersList.selected
    self.markersList:clear()
    if not mapMarkers then
        MapMarkerSystem.MapMarkers = MapMarkerSystem.Shared.RequestMarkers()
    else
        MapMarkerSystem.MapMarkers = mapMarkers
    end
    if MapMarkerSystem.MapMarkers then
        for i = 1, #MapMarkerSystem.MapMarkers do
            self.markersList:addItem(MapMarkerSystem.MapMarkers[i].name, MapMarkerSystem.MapMarkers[i])
        end
        if #MapMarkerSystem.MapMarkers > 0 then
            if prevSelected and prevSelected <= #MapMarkerSystem.MapMarkers then
                self.markersList.selected = prevSelected
                self:populateElementsDetails(MapMarkerSystem.MapMarkers[prevSelected])
            else
                MapMarkerManager.instance.markersList.selected = 1
                MapMarkerManager.instance:populateElementsDetails(MapMarkerSystem.MapMarkers[1])
            end
        else
            self.markersList.selected = 0
            self:populateElementsDetails(nil)
        end
    end
end

function MapMarkerManager:getMapMarkerIdx()
    return self.markersList and self.markersList.selected
end

function MapMarkerManager:onTickBoxEnableMarkerOption(index, selected)
    local selectedMapMarkerIdx = self:getMapMarkerIdx()
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not mapMarkerData then return end
    mapMarkerData.isEnabled = selected
    self.enableMarkerTickBox.selected[index] = selected
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = self:getMapMarkerIdx(),
        newKey = "isEnabled",
        newValue = selected
    })
end

function MapMarkerManager:onTickBoxEnableMarkerNameOption(index, selected)
    local selectedMapMarkerIdx = self:getMapMarkerIdx()
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not mapMarkerData then return end
    mapMarkerData.isNameEnabled = selected
    self.enableMarkerNameTickBox.selected[index] = selected
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = self:getMapMarkerIdx(),
        newKey = "isNameEnabled",
        newValue = selected
    })
end

function MapMarkerManager:onChangeMarkerNameFont(comboBox, arg1, arg2)
    local selectedFont = comboBox:getSelectedText()
    if not selectedFont then return end
    local selectedMapMarkerIdx = self:getMapMarkerIdx()
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not mapMarkerData then return end
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = self:getMapMarkerIdx(),
        newKey = "nameFont",
        newValue = selectedFont
    })
end

function MapMarkerManager:onTickBoxFixedScaleOption(index, selected)
    local selectedMapMarkerIdx = self:getMapMarkerIdx()
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not mapMarkerData then return end
    mapMarkerData.lockZoom = selected
    self.lockZoomTickBox.selected[index] = selected
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = self:getMapMarkerIdx(),
        newKey = "lockZoom",
        newValue = selected
    })
end

function MapMarkerManager:onMarkerNameInputChange()
    local nameVal = self:getInternalText()
    if nameVal == "" then return end
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx()
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not mapMarkerData then return end
    mapMarkerData.name = nameVal
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = selectedMapMarkerIdx,
        newKey = "name",
        newValue = nameVal
    })
    self.parent.markerNameEntryBox:setText(mapMarkerData.name)
end

function MapMarkerManager:onScaleInputChange()
    local scaleVal = self:getInternalText()
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx()
    if scaleVal == "" or not tonumber(scaleVal) then scaleVal = "1" end
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not mapMarkerData then return end
    mapMarkerData[self.scaleType] = tonumber(scaleVal) and tonumber(scaleVal) or mapMarkerData[self.scaleType]
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = selectedMapMarkerIdx,
        newKey = self.scaleType,
        newValue = mapMarkerData[self.scaleType]
    })
    self:setText(tostring(mapMarkerData[self.scaleType]))
end

function MapMarkerManager:onMaxZoomInputChange()
    local maxZoomVal = self:getInternalText()
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx()
    if maxZoomVal == "" or not tonumber(maxZoomVal) then maxZoomVal = "100" end
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not mapMarkerData then return end
    mapMarkerData.maxZoomLevel = tonumber(maxZoomVal) and tonumber(maxZoomVal) or mapMarkerData.maxZoomLevel
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = selectedMapMarkerIdx,
        newKey = "maxZoomLevel",
        newValue = mapMarkerData.maxZoomLevel
    })
    self.parent.maxZoomEntryBox:setText(tostring(mapMarkerData.maxZoomLevel))
end

local function textureExists(texture)
    return texture and texture ~= "" and getTexture(texture) or nil
end

function MapMarkerManager:onTextureInputChange()
    local textureVal = self:getInternalText()
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx()
    if not textureExists(textureVal) then return end
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not mapMarkerData then return end
    mapMarkerData.texturePath = textureVal
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = selectedMapMarkerIdx,
        newKey = "texturePath",
        newValue = textureVal
    })
    self.parent.textureEntryBox:setText(mapMarkerData.texturePath)
end

function MapMarkerManager:onCoordsInputChange()
    local coordVal = tonumber(self:getInternalText()) or -1
    local selectedMapMarkerIdx = self.parent:getMapMarkerIdx()
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not mapMarkerData then return end
    mapMarkerData.coordinates = mapMarkerData.coordinates or {}

    local defaultCoords = { x = -1, y = -1 }
    local function updateCoordinates(coordType, coordKey)
        local targetCoords = mapMarkerData.coordinates[coordKey] or defaultCoords
        if coordType == "x" then
            targetCoords.x = coordVal
        elseif coordType == "y" then
            targetCoords.y = coordVal
        end
        mapMarkerData.coordinates[coordKey] = targetCoords
    end

    local function sendCoordinate(coordKey, value)
        sendClientCommand("MapMarkerSystem", "EditMarkerData", {
            selectedIdx = selectedMapMarkerIdx,
            newKey = coordKey,
            newValue = value
        })
    end

    if mapMarkerData.markerType == "texture" then
        updateCoordinates(self.coordType:sub(1, 1), "center")
        local center = mapMarkerData.coordinates.center or { x = -1, y = -1 }
        if center.x ~= -1 and center.y ~= -1 then
            sendCoordinate("coordinates.center.x", center.x)
            sendCoordinate("coordinates.center.y", center.y)
        end
    elseif mapMarkerData.markerType == "rectangle" then
        if self.coordType == "x1" or self.coordType == "y1" then
            updateCoordinates(self.coordType:sub(1, 1), "center")
            local center = mapMarkerData.coordinates.center or { x = -1, y = -1 }
            if center.x ~= -1 and center.y ~= -1 then
                sendCoordinate("coordinates.center.x", center.x)
                sendCoordinate("coordinates.center.y", center.y)
            end
        else
            mapMarkerData.coordinates.width  = self.coordType == "x2" and coordVal or mapMarkerData.coordinates.width
            mapMarkerData.coordinates.height = self.coordType == "y2" and coordVal or mapMarkerData.coordinates.height
            if not (mapMarkerData.coordinates.width < 1 or mapMarkerData.coordinates.height < 1) then
                sendCoordinate("coordinates.width", mapMarkerData.coordinates.width)
                sendCoordinate("coordinates.height", mapMarkerData.coordinates.height)
            end
        end
    elseif mapMarkerData.markerType == "area" then
        local coordKey = (self.coordType == "x1" or self.coordType == "y1") and "nw" or "se"
        updateCoordinates(self.coordType:sub(1, 1), coordKey)
        local nw = mapMarkerData.coordinates.nw or { x = -1, y = -1 }
        local se = mapMarkerData.coordinates.se or { x = -1, y = -1 }
        if nw.x ~= -1 and nw.y ~= -1 then
            sendCoordinate("coordinates.nw.x", nw.x)
            sendCoordinate("coordinates.nw.y", nw.y)
        end
        if se.x ~= -1 and se.y ~= -1 then
            sendCoordinate("coordinates.se.x", se.x)
            sendCoordinate("coordinates.se.y", se.y)
        end
    end
end

function MapMarkerManager:updateElementsPositions(markerData)
    local y = self.markersList:getBottom() + C.SSPC

    self.markerTypeLabel:setY(y)
    self.markerTypeValLabel:setY(y)
    y = self.markerTypeLabel:getBottom() + C.ISPC

    self.markerNameLabel:setY(y)
    self.markerNameEntryBox:setY(y)
    y = self.markerNameLabel:getBottom() + C.ISPC

    self.enableMarkerTickBox:setY(y)
    y = self.enableMarkerTickBox:getBottom() + C.ISPC

    if markerData.markerType == "rectangle" or markerData.markerType == "area" then
        self.enableMarkerNameTickBox:setY(y)
        y = self.enableMarkerNameTickBox:getBottom() + C.ISPC

        self.markerNameFontLabel:setY(y)
        self.markerNameFontComboBox:setY(y)
        y = self.markerNameFontComboBox:getBottom() + C.ISPC

        self.colorLabelMarkerName:setY(y)
        self.colorPickerMarkerNameButton:setY(y)
        y = self.colorLabelMarkerName:getBottom() + C.ISPC

        self.scaleNameLabel:setY(y)
        self.scaleNameEntryBox:setY(y)
        y = self.scaleNameLabel:getBottom() + C.ISPC
    end

    self.locationLabel:setY(y)
    self.nwXLabel:setY(y)
    self.nwYLabel:setY(y)
    self.nwXEntryBox:setY(y)
    self.nwYEntryBox:setY(y)
    self.pickNWButton:setY(y)
    y = self.locationLabel:getBottom() + C.ISPC

    if markerData.markerType == "texture" then
        self.textureLabel:setY(y)
        self.textureEntryBox:setY(y)
        y = self.textureLabel:getBottom() + C.ISPC

        self.scaleLabel:setY(y)
        self.scaleEntryBox:setY(y)
        y = self.scaleLabel:getBottom() + C.ISPC

        self.lockZoomTickBox:setY(y)
        y = self.lockZoomTickBox:getBottom() + C.ISPC
    elseif markerData.markerType == "rectangle" then
        self.seXLabel:setY(y)
        self.seXEntryBox:setY(y)
        self.seYLabel:setY(y)
        self.seYEntryBox:setY(y)
        y = self.seXLabel:getBottom() + C.ISPC

        self.colorLabelMarker:setY(y)
        self.colorPickerMarkerButton:setY(y)
        y = self.colorLabelMarker:getBottom() + C.ISPC

        self.scaleLabel:setY(y)
        self.scaleEntryBox:setY(y)
        y = self.scaleLabel:getBottom() + C.ISPC

        self.lockZoomTickBox:setY(y)
        y = self.lockZoomTickBox:getBottom() + C.ISPC
    elseif markerData.markerType == "area" then
        self.seXLabel:setY(y)
        self.seXEntryBox:setY(y)
        self.seYLabel:setY(y)
        self.seYEntryBox:setY(y)
        self.pickSEButton:setY(y)
        y = self.seXEntryBox:getBottom() + C.ISPC

        self.textureLabel:setVisible(false)
        self.textureEntryBox:setVisible(false)
        self.scaleLabel:setVisible(false)
        self.scaleEntryBox:setVisible(false)
        self.lockZoomTickBox:setVisible(false)

        self.colorLabelMarker:setY(y)
        self.colorPickerMarkerButton:setY(y)
        y = self.colorLabelMarker:getBottom() + C.ISPC
    end

    self.maxZoomLabel:setY(y)
    self.maxZoomEntryBox:setY(y)
end

function MapMarkerManager:populateElementsDetails(markerData)
    self.markerTypeValLabel:setName("")
    self.markerNameEntryBox:setText("")
    self.markerNameEntryBox:setEditable(false)
    self.enableMarkerTickBox:setSelected(1, false)
    self.enableMarkerNameTickBox:setSelected(1, false)
    self.markerNameFontComboBox:select(MapMarkerSystem.FontList[1])
    self.colorPickerMarkerNameButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 }
    self.scaleNameEntryBox:setText("")
    self.scaleNameEntryBox:setEditable(false)
    self.nwXEntryBox:setText("")
    self.nwXEntryBox:setEditable(false)
    self.nwYEntryBox:setText("")
    self.nwYEntryBox:setEditable(false)
    self.seXEntryBox:setText("")
    self.seXEntryBox:setEditable(false)
    self.seYEntryBox:setText("")
    self.seYEntryBox:setEditable(false)
    self.textureEntryBox:setText("")
    self.textureEntryBox:setEditable(false)
    self.colorPickerMarkerButton.backgroundColor = { r = 1, g = 1, b = 1, a = 1 }
    self.scaleEntryBox:setText("")
    self.scaleEntryBox:setEditable(false)
    self.lockZoomTickBox:setSelected(1, false)
    self.maxZoomEntryBox:setText("")
    self.maxZoomEntryBox:setEditable(false)

    local componentsToHide = {
        "markerTypeLabel", "markerTypeValLabel",
        "markerNameLabel", "markerNameEntryBox",
        "enableMarkerTickBox",
        "enableMarkerNameTickBox",
        "markerNameFontLabel", "markerNameFontComboBox",
        "colorLabelMarkerName", "colorPickerMarkerNameButton",
        "scaleNameLabel", "scaleNameEntryBox",
        "locationLabel",
        "nwXLabel", "nwXEntryBox",
        "nwYLabel", "nwYEntryBox", "pickNWButton",
        "seXLabel", "seXEntryBox",
        "seYLabel", "seYEntryBox", "pickSEButton",
        "textureLabel", "textureEntryBox",
        "colorLabelMarker", "colorPickerMarkerButton",
        "scaleLabel", "scaleEntryBox",
        "lockZoomTickBox",
        "maxZoomLabel", "maxZoomEntryBox"
    }
    for i = 1, #componentsToHide do
        local component = self[componentsToHide[i]]
        if component and component.setVisible then
            component:setVisible(false)
        end
    end

    if not markerData then return end

    local markerTypes = {
        ["texture"]   = getText("IGUI_MMS_TextureMarker"),
        ["rectangle"] = getText("IGUI_MMS_RectangleMarker"),
        ["area"]      = getText("IGUI_MMS_AreaMarker")
    }

    self.markerTypeLabel:setVisible(true)
    self.markerTypeValLabel:setName(markerTypes[markerData.markerType] or "N/A")
    self.markerTypeValLabel:setVisible(true)

    self.markerNameLabel:setVisible(true)
    self.markerNameEntryBox:setText(markerData.name or "")
    self.markerNameEntryBox:setEditable(true)
    self.markerNameEntryBox:setVisible(true)

    self.enableMarkerTickBox:setVisible(true)
    self.enableMarkerTickBox:setSelected(1, markerData.isEnabled or false)

    self.locationLabel:setVisible(true)
    self.maxZoomLabel:setVisible(true)
    self.maxZoomEntryBox:setText(tostring(markerData.maxZoomLevel or ""))
    self.maxZoomEntryBox:setEditable(true)
    self.maxZoomEntryBox:setVisible(true)

    local typeConfigs = {
        ["texture"] = function()
            local center = markerData.coordinates.center or { x = -1, y = -1 }
            self.nwXLabel:setName(getText("IGUI_MMS_xCoord", ""))
            self.nwXEntryBox:setText(tostring(center.x or ""))
            self.nwXLabel:setVisible(true)
            self.nwXEntryBox:setVisible(true)
            self.nwXEntryBox:setEditable(true)
            self.nwYLabel:setName(getText("IGUI_MMS_yCoord", ""))
            self.nwYEntryBox:setText(tostring(center.y or ""))
            self.nwYLabel:setVisible(true)
            self.nwYEntryBox:setVisible(true)
            self.nwYEntryBox:setEditable(true)
            self.pickNWButton:setVisible(true)
            self.textureEntryBox:setText(markerData.texturePath or "")
            self.textureEntryBox:setEditable(true)
            self.textureLabel:setVisible(true)
            self.textureEntryBox:setVisible(true)
            self.scaleEntryBox:setText(tostring(markerData.scale or ""))
            self.scaleEntryBox:setEditable(true)
            self.scaleLabel:setVisible(true)
            self.scaleEntryBox:setVisible(true)
            self.lockZoomTickBox:setSelected(1, markerData.lockZoom or false)
            self.lockZoomTickBox:setVisible(true)
        end,
        ["rectangle"] = function()
            self.enableMarkerNameTickBox:setSelected(1, markerData.isNameEnabled or false)
            self.enableMarkerNameTickBox:setVisible(true)
            self.markerNameFontLabel:setVisible(true)
            self.markerNameFontComboBox:select(markerData.nameFont or MapMarkerSystem.FontList[1])
            self.markerNameFontComboBox:setVisible(true)
            self.colorPickerMarkerNameButton.backgroundColor = markerData.colorName or { r = 1, g = 1, b = 1, a = 1 }
            self.colorLabelMarkerName:setVisible(true)
            self.colorPickerMarkerNameButton:setVisible(true)
            self.scaleNameEntryBox:setText(tostring(markerData.scaleName or ""))
            self.scaleNameEntryBox:setEditable(true)
            self.scaleNameLabel:setVisible(true)
            self.scaleNameEntryBox:setVisible(true)
            local center = markerData.coordinates.center or { x = -1, y = -1 }
            self.nwXLabel:setName(getText("IGUI_MMS_xCoord", ""))
            self.nwXEntryBox:setText(tostring(center.x or ""))
            self.nwXLabel:setVisible(true)
            self.nwXEntryBox:setVisible(true)
            self.nwXEntryBox:setEditable(true)
            self.nwYLabel:setName(getText("IGUI_MMS_yCoord", ""))
            self.nwYEntryBox:setText(tostring(center.y or ""))
            self.nwYLabel:setVisible(true)
            self.nwYEntryBox:setVisible(true)
            self.nwYEntryBox:setEditable(true)
            self.pickNWButton:setVisible(true)
            self.seXLabel:setName(getText("IGUI_MMS_wMarker"))
            self.seXEntryBox:setText(tostring(markerData.coordinates.width or ""))
            self.seXLabel:setVisible(true)
            self.seXEntryBox:setVisible(true)
            self.seXEntryBox:setEditable(true)
            self.seYLabel:setName(getText("IGUI_MMS_hMarker"))
            self.seYEntryBox:setText(tostring(markerData.coordinates.height or ""))
            self.seYLabel:setVisible(true)
            self.seYEntryBox:setVisible(true)
            self.seYEntryBox:setEditable(true)
            self.scaleEntryBox:setText(tostring(markerData.scale or ""))
            self.scaleEntryBox:setEditable(true)
            self.scaleLabel:setVisible(true)
            self.scaleEntryBox:setVisible(true)
            self.lockZoomTickBox:setSelected(1, markerData.lockZoom or false)
            self.lockZoomTickBox:setVisible(true)
            self.colorPickerMarkerButton.backgroundColor = markerData.color or { r = 1, g = 1, b = 1, a = 1 }
            self.colorLabelMarker:setVisible(true)
            self.colorPickerMarkerButton:setVisible(true)
        end,
        ["area"] = function()
            self.enableMarkerNameTickBox:setSelected(1, markerData.isNameEnabled or false)
            self.enableMarkerNameTickBox:setVisible(true)
            self.markerNameFontLabel:setVisible(true)
            self.markerNameFontComboBox:select(markerData.nameFont or MapMarkerSystem.FontList[1])
            self.markerNameFontComboBox:setVisible(true)
            self.colorPickerMarkerNameButton.backgroundColor = markerData.colorName or { r = 1, g = 1, b = 1, a = 1 }
            self.colorLabelMarkerName:setVisible(true)
            self.colorPickerMarkerNameButton:setVisible(true)
            self.scaleNameEntryBox:setText(tostring(markerData.scaleName or ""))
            self.scaleNameEntryBox:setEditable(true)
            self.scaleNameLabel:setVisible(true)
            self.scaleNameEntryBox:setVisible(true)
            local nw = markerData.coordinates.nw or { x = -1, y = -1 }
            local se = markerData.coordinates.se or { x = -1, y = -1 }
            self.nwXLabel:setName(getText("IGUI_MMS_xCoord", "1"))
            self.nwXEntryBox:setText(tostring(nw.x or ""))
            self.nwXLabel:setVisible(true)
            self.nwXEntryBox:setVisible(true)
            self.nwXEntryBox:setEditable(true)
            self.nwYLabel:setName(getText("IGUI_MMS_yCoord", "1"))
            self.nwYEntryBox:setText(tostring(nw.y or ""))
            self.nwYLabel:setVisible(true)
            self.nwYEntryBox:setVisible(true)
            self.nwYEntryBox:setEditable(true)
            self.pickNWButton:setVisible(true)
            self.seXLabel:setName(getText("IGUI_MMS_xCoord", "2"))
            self.seXEntryBox:setText(tostring(se.x or ""))
            self.seXLabel:setVisible(true)
            self.seXEntryBox:setVisible(true)
            self.seXEntryBox:setEditable(true)
            self.seYLabel:setName(getText("IGUI_MMS_yCoord", "2"))
            self.seYEntryBox:setText(tostring(se.y or ""))
            self.seYLabel:setVisible(true)
            self.seYEntryBox:setVisible(true)
            self.seYEntryBox:setEditable(true)
            self.pickSEButton:setVisible(true)
            self.colorPickerMarkerButton.backgroundColor = markerData.color or { r = 1, g = 1, b = 1, a = 1 }
            self.colorLabelMarker:setVisible(true)
            self.colorPickerMarkerButton:setVisible(true)
        end
    }

    local tooltipConfigs = {
        ["texture"] = function()
            self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_TextureX"))
            self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_TextureY"))
            self.textureEntryBox:setTooltip(getText("Tooltip_MMS_TexturePath"))
        end,
        ["rectangle"] = function()
            self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_RectCenterX"))
            self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_RectCenterY"))
            self.seXEntryBox:setTooltip(getText("Tooltip_MMS_RectWidth"))
            self.seYEntryBox:setTooltip(getText("Tooltip_MMS_RectHeight"))
            self.colorPickerMarkerButton:setTooltip(getText("Tooltip_MMS_RectColorPicker"))
        end,
        ["area"] = function()
            self.nwXEntryBox:setTooltip(getText("Tooltip_MMS_AreaX1"))
            self.nwYEntryBox:setTooltip(getText("Tooltip_MMS_AreaY1"))
            self.seXEntryBox:setTooltip(getText("Tooltip_MMS_AreaX2"))
            self.seYEntryBox:setTooltip(getText("Tooltip_MMS_AreaY2"))
            self.colorPickerMarkerButton:setTooltip(getText("Tooltip_MMS_AreaColorPicker"))
        end
    }

    self.nwXEntryBox:setTooltip(nil)
    self.nwYEntryBox:setTooltip(nil)
    self.seXEntryBox:setTooltip(nil)
    self.seYEntryBox:setTooltip(nil)
    self.textureEntryBox:setTooltip(nil)
    self.colorPickerMarkerButton:setTooltip(nil)

    if typeConfigs[markerData.markerType] then
        typeConfigs[markerData.markerType]()
    end
    if tooltipConfigs[markerData.markerType] then
        tooltipConfigs[markerData.markerType]()
    end
    self:updateElementsPositions(markerData)
end

function MapMarkerManager:drawMapMarkersListItem(y, item, alt)
    if not item.height then item.height = self.itemheight end
    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), item.height - 1, 0.3, T.warning.r, T.warning.g, T.warning.b)
    end
    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
    local markerData = item.item
    local tr, tg, tb
    if markerData.isEnabled then
        tr, tg, tb = T.success.r, T.success.g, T.success.b
    else
        tr, tg, tb = T.danger.r, T.danger.g, T.danger.b
    end
    local markerTypes = { ["texture"] = "[T]", ["rectangle"] = "[R]", ["area"] = "[A]" }
    local displayName = markerTypes[markerData.markerType] .. " " .. markerData.name
    self:drawText(displayName, 15, y + itemPadY, tr, tg, tb, 0.9, self.font)
    local coordsText = ""
    if markerData.markerType == "texture" or markerData.markerType == "rectangle" then
        coordsText = string.format("(%d, %d)", markerData.coordinates.center.x or 0, markerData.coordinates.center.y or 0)
    elseif markerData.markerType == "area" then
        coordsText = string.format("(%d,%d;%d,%d)",
            markerData.coordinates.nw.x, markerData.coordinates.nw.y,
            markerData.coordinates.se.x, markerData.coordinates.se.y)
    end
    local coordsWidth = getTextManager():MeasureStringX(UIFont.Small, coordsText)
    local coordsX = self:getWidth() - 15 - coordsWidth
    self:drawText(coordsText, coordsX, y + itemPadY, T.textMuted.r, T.textMuted.g, T.textMuted.b, 0.9, UIFont.Small)
    return y + item.height
end

function MapMarkerManager:onMouseDownMapMarkersList(x, y)
    if self.items and #self.items == 0 then return end
    local row = self:rowAt(x, y)
    if row > #self.items then row = #self.items end
    if row < 1 then row = 1 end
    local item = self.items[row].item
    getSoundManager():playUISound("UISelectListItem")
    self.selected = row
    if self.onmousedown then
        self.onmousedown(self.target, item)
    end
    self.parent:populateElementsDetails(item)
end

function MapMarkerManager:onPressedColorPickerMarkerBttn(button)
    self.colorPickerMarker:setX(getMouseX() - 100)
    self.colorPickerMarker:setY(getMouseY() - 20)
    self.colorPickerMarker.pickedFunc = self.onPickedMarkerColor
    self.colorPickerMarker:setVisible(true)
    self.colorPickerMarker:bringToTop()
end

function MapMarkerManager:onPickedMarkerColor(color, mouseUp)
    self.currentColorMarker = ColorInfo.new(color.r, color.g, color.b, 1)
    self.colorPickerMarkerButton.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 }
    self.colorPickerMarker:setVisible(false)
    local selectedMapMarkerIdx = self:getMapMarkerIdx()
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not selectedMapMarkerIdx or not mapMarkerData then return end
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = selectedMapMarkerIdx,
        newKey = "color",
        newValue = { r = color.r, g = color.g, b = color.b, a = 1 }
    })
end

function MapMarkerManager:onPressedColorPickerMarkerNameBttn(button)
    self.colorPickerMarkerName:setX(getMouseX() - 100)
    self.colorPickerMarkerName:setY(getMouseY() - 20)
    self.colorPickerMarkerName.pickedFunc = self.onPickedMarkerNameColor
    self.colorPickerMarkerName:setVisible(true)
    self.colorPickerMarkerName:bringToTop()
end

function MapMarkerManager:onPickedMarkerNameColor(color, mouseUp)
    self.currentColorMarkerName = ColorInfo.new(color.r, color.g, color.b, 1)
    self.colorPickerMarkerNameButton.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 }
    self.colorPickerMarkerName:setVisible(false)
    local selectedMapMarkerIdx = self:getMapMarkerIdx()
    local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
    if not selectedMapMarkerIdx or not mapMarkerData then return end
    sendClientCommand("MapMarkerSystem", "EditMarkerData", {
        selectedIdx = selectedMapMarkerIdx,
        newKey = "colorName",
        newValue = { r = color.r, g = color.g, b = color.b, a = 1 }
    })
end

function MapMarkerManager:close()
    local playerObj = self.playerObj or getPlayer()
    if playerObj then
        local modData = playerObj:getModData()
        modData.MMS_Position = { x = self:getX(), y = self:getY(), width = self:getWidth(), height = self:getHeight() }
    end
    self:setVisible(false)
    self:removeFromUIManager()
    MapMarkerManager.instance = nil
end

function MapMarkerManager:onClickBttn(button)
    if button.internal == "TELEPORT" then
        if not self.playerObj then return end
        local selectedMapMarkerIdx = self:getMapMarkerIdx()
        local mapMarkerData = MapMarkerSystem.MapMarkers[selectedMapMarkerIdx]
        if not selectedMapMarkerIdx or not mapMarkerData then return end
        local mx, my = nil, nil
        if mapMarkerData.markerType == "texture" or mapMarkerData.markerType == "rectangle" then
            mx = mapMarkerData.coordinates.center.x
            my = mapMarkerData.coordinates.center.y
        elseif mapMarkerData.markerType == "area" then
            mx = (mapMarkerData.coordinates.nw.x + mapMarkerData.coordinates.se.x) / 2
            my = (mapMarkerData.coordinates.nw.y + mapMarkerData.coordinates.se.y) / 2
        end
        self.playerObj:setX(mx)
        self.playerObj:setY(my)
        self.playerObj:setZ(0.0)
        self.playerObj:setLx(mx)
        self.playerObj:setLy(my)
    elseif button.internal == "DELETEMARKER" then
        local selectedMapMarkerIdx = self:getMapMarkerIdx()
        if not selectedMapMarkerIdx or not MapMarkerSystem.MapMarkers[selectedMapMarkerIdx] then return end
        sendClientCommand("MapMarkerSystem", "RemoveMapMarker", { selectedIdx = selectedMapMarkerIdx })
        self.markersList.selected = 0
        self.refresh = 3
    elseif button.internal == "ADDMARKER" then
        local modal = AddMarkerModal:new(0, 0, 300, 200, getText("IGUI_MMS_AddMarker"), self, self.onAddMapMarker, self.playerNum)
        modal:initialise()
        modal:addToUIManager()
    end
end

function MapMarkerManager:onAddMapMarker(target, newMapMarker)
    if target.internal ~= "OK" then return end
    if not newMapMarker then return end
    sendClientCommand("MapMarkerSystem", "AddMapMarker", { newMapMarker = newMapMarker })
    self.markersList:addItem(newMapMarker.name, newMapMarker)
    self.refresh = 3
end

function MapMarkerManager:onClickPickLocation(button)
    local isoPlayer = getPlayer()
    local px = math.floor(isoPlayer:getX())
    local py = math.floor(isoPlayer:getY())
    if button.internal == "PICK_NW" then
        self.nwXEntryBox:setText(tostring(px or ""))
        self.nwYEntryBox:setText(tostring(py or ""))
        self.nwXEntryBox:onTextChange()
        self.nwYEntryBox:onTextChange()
    elseif button.internal == "PICK_SE" then
        self.seXEntryBox:setText(tostring(px or ""))
        self.seYEntryBox:setText(tostring(py or ""))
        self.seXEntryBox:onTextChange()
        self.seYEntryBox:onTextChange()
    end
end

function MapMarkerManager:onImport()
    local markers = FileUtils.readJson("MapMarkerSystemMarkers.json", "Map Marker Manager", { isModFile = false })
    if (not markers) or (type(markers) ~= "table") then
        Logger:error("Map Marker System Markers IMPORT FAILED")
        return
    end
    sendClientCommand("MapMarkerSystem", "ImportMapMarkerData", { mapMarkers = markers })
    self.refresh = 3
end

function MapMarkerManager:onExport()
    local cacheDir = Core.getMyDocumentFolder() ..
        getFileSeparator() .. "Lua" .. getFileSeparator() .. "MapMarkerSystemMarkers.json"
    local markers = MapMarkerSystem.Shared.RequestMarkers()
    local success = FileUtils.writeJson("MapMarkerSystemMarkers.json", markers, "Map Marker Manager", { createIfNull = true })
    if success then
        Logger:info("Map Marker System Markers EXPORTED SUCCESFULLY TO %s", cacheDir)
        local modal = ISModalDialog:new(0, 0, 350, 150, getText("IGUI_MMS_ExportSuccesful", cacheDir),
            true, nil, function(dummy, button, playerObj)
                if button.internal == "NO" then return end
                if isDesktopOpenSupported() then
                    showFolderInDesktop(cacheDir)
                else
                    openUrl(cacheDir)
                end
            end, self.playerNum, self.character)
        modal:initialise()
        modal.moveWithMouse = true
        modal:addToUIManager()
        if JoypadState.players[self.playerNum + 1] then
            setJoypadFocus(self.playerNum, modal)
        end
    else
        Logger:error("Map Marker System Markers FAILED TO EXPORT TO %s", cacheDir)
    end
end

function MapMarkerManager.openPanel()
    if MapMarkerManager.instance then
        MapMarkerManager.instance:close()
        return
    end
    local playerObj = getPlayer()
    local modData = playerObj and playerObj:getModData() or {}
    local saved = modData.MMS_Position or {}
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w = saved.width or C.DEF_W
    local h = saved.height or C.DEF_H
    local x = math.max(0, math.min(saved.x or (sw - w) / 2, sw - w))
    local y = math.max(0, math.min(saved.y or (sh - h) / 2, sh - h))
    MapMarkerManager.instance = MapMarkerManager:new(x, y, w, h, playerObj)
    MapMarkerManager.instance:initialise()
    MapMarkerManager.instance:addToUIManager()
end

local MenuDock = require("ElyonLib/UI/MenuDock/MenuDock")

MenuDock.registerButton({
    id = "map_marker_system",
    title = getText("IGUI_MMS_MapMarkerSystem"),
    icon = "media/ui/ui_icon_map_marker_system.png",
    minimumAccessLevel = "Admin",
    allowSinglePlayer = true,
    onClick = function(playerNum, entry)
        MapMarkerManager.openPanel()
    end,
})

return MapMarkerManager;
