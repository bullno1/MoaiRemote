print("Hai, can haz cheeze burgerz???")
local viewport = MOAIViewport.new ()
local devWidth, devHeight = MOAIGfxDevice.getViewSize()
viewport:setSize(devWidth, devHeight)
viewport:setScale(devWidth, -devHeight)
viewport:setOffset(-1, 1)

local layer = MOAILayer2D.new ()
layer:setViewport(viewport)
MOAISim.pushRenderPass (layer)
gfxQuad = MOAIGfxQuad2D.new ()
gfxQuad:setTexture ( "cathead.png" )
gfxQuad:setRect ( -64, -64, 64, 64 )
gfxQuad:setUVRect ( 1, 0, 0, 1)


prop = MOAIProp2D.new ()
prop:setDeck ( gfxQuad )
layer:insertProp ( prop )
prop:moveRot ( 360 * 6, 1.5 * 10 )
prop:seekLoc ( devWidth / 2, devHeight / 2, 1.5 * 10, MOAIEaseType.SMOOTH)

local touchDeck = MOAIScriptDeck.new()
local touchSensor = MOAIInputMgr.device.touch
touchDeck:setDrawCallback(function(index, xOff, yOff, xScale, yScale)
	for _, id in ipairs{touchSensor:getActiveTouches()} do
		local x, y = touchSensor:getTouch(id)
		MOAIGfxDevice.setPenColor(1, 1, 1, 0.75)
		MOAIDraw.fillCircle (x, y, 10, 10)
		MOAIGfxDevice.setPenColor(0, 0, 1, 0.75)
		MOAIDraw.drawLine (x, -devHeight, x, devHeight)
		MOAIDraw.drawLine (-devWidth, y, devWidth, y)
	end
end)
touchDeck:setRect(-devWidth, -devHeight, devWidth, devHeight)

local prop = MOAIProp2D.new()
prop:setDeck(touchDeck)
layer:insertProp(prop)
prop:setBlendMode(MOAIProp2D.BLEND_ADD)
