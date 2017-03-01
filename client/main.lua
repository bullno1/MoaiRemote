--
-- moai remote client - sits and waits for an app
-- to be deployed to it, and then executes the app
--

require ("lua-enumerable")

local APP_NAME = "MOAI Remote"

local STAGE_HEIGHT = 0
local STAGE_WIDTH = 0

-- grrr.. MOAI .. grr..
if (MOAIEnvironment.screenHeight ~= nil) and (MOAIEnvironment.screenWidth ~= nil) then
  STAGE_WIDTH = MOAIEnvironment.screenWidth 
  STAGE_HEIGHT = MOAIEnvironment.screenHeight
end

if (MOAIEnvironment.verticalResolution ~= nil) and (MOAIEnvironment.horizontalResolution ~= nil) then
  STAGE_WIDTH = MOAIEnvironment.horizontalResolution 
  STAGE_HEIGHT = MOAIEnvironment.verticalResolution
end

if STAGE_HEIGHT == 0 then STAGE_HEIGHT = 960 print ("height fixup") end
if STAGE_WIDTH == 0 then STAGE_WIDTH = 960 print ("width fixup") end

-- rudimentary app message store
local mrMessages = {}
mrMessages["welcome"] = "<c:2CF>welcome<c>to<c:F52> " .. APP_NAME .. "\n\n\nwaiting for server.."
mrMessages["data"] = "data happening! "
mrMessages["sendto"] = "server said hi!"
mrMessages["execute"] = "receiving new package to execute... "
mrMessages["returntomain"] = "returning .. "

-- MOAI: set up the basics .. mr-* = moai remote-*
--MOAISim.openWindow ( APP_NAME, STAGE_WIDTH, STAGE_HEIGHT )
--MOAIDebugLines.setStyle ( MOAIDebugLines.TEXT_BOX, 1, 1, 1, 1, 1 )
--MOAIDebugLines.setStyle ( MOAIDebugLines.TEXT_BOX_LAYOUT, 1, 0, 0, 1, 1 )
--MOAIDebugLines.setStyle ( MOAIDebugLines.TEXT_BOX_BASELINES, 1, 1, 0, 0, 1 )

mrRenderables = {}

mrViewport = MOAIViewport.new ()
mrViewport:setSize ( STAGE_WIDTH, STAGE_HEIGHT )
mrViewport:setScale ( STAGE_WIDTH, STAGE_HEIGHT )

mrAppLayer = MOAILayer2D.new ()
mrAppLayer:setViewport ( mrViewport )
mrRenderables[1] = mrAppLayer
MOAISim.pushRenderPass ( mrAppLayer )

mrAppDeckList = {}
mrAppDecks = {}
mrAppDeckList["bg"] = { name="bg", 
                        pngfile="mrBackground.png", 
                        r1x=((STAGE_WIDTH / 2 * -1)), 
                        r1y=((STAGE_HEIGHT / 2 ) * -1), 
                        r2x=(STAGE_WIDTH / 2), 
                        r2y=(STAGE_HEIGHT / 2)}

table.all(mrAppDeckList, function (inDeck, i)
						mrAppDecks[inDeck.name]  = MOAIGfxQuad2D.new ()
   						mrAppDecks[inDeck.name]:setTexture ( inDeck.pngfile)
   						mrAppDecks[inDeck.name]:setRect ( inDeck.r1x, inDeck.r1y, inDeck.r2x, inDeck.r2y)
   					end )



-- add the background
mrBGProp = MOAIProp2D.new ()
mrBGProp.name = "bg"
mrBGProp:setDeck ( mrAppDecks["bg"] )
mrAppLayer:insertProp ( mrBGProp )

--mrPartition:insertProp(mrBGProp)

-- rudimentary MOAI text console
local asciiTextCodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?()&/-'
local appFonts = {}

appFonts["anonymous"] 	= {ttf='anonymous.ttf', textcodes=asciiTextCodes, font=MOAIFont.new(), size=36, dpi=163}

table.all(appFonts, function(appFont, index) 
                    print ("appFont ", appFont.ttf) 
                    appFont.font:loadFromTTF(appFont.ttf, appFont.textcodes, appFont.size, appFont.dpi)  
                end )

local mrTextUi = MOAITextBox.new()
mrTextUi:setFont(appFonts["anonymous"].font)
mrTextUi:setTextSize(appFonts["anonymous"].size) --mrTextUiFont:getScale())
mrTextUi:setString(mrMessages["welcome"])
mrTextUi:setRect(-170, 400, 170, 300)
mrTextUi:setYFlip(true)
mrTextUi:setAlignment(MOAITextBox.LEFT_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
mrAppLayer:insertProp(mrTextUi)

-- hmm .. borked?
--MOAIRenderMgr:setRenderTable(mrRenderables)

-- finally .. the client connect and launch platform
local socket = require "socket"
local ltn12 = require "ltn12"
local PORT = 9001
local MAGIC_HEADER = "MOAI_REMOTE:"
local PING = MAGIC_HEADER.."PING"
local PONG = MAGIC_HEADER.."PONG:"
local LAUNCH = MAGIC_HEADER.."LAUNCH"


local function runnerFunc()

	local sock = assert(socket.udp())

	assert(sock:setsockname("*", PORT))

	assert(sock:settimeout(0))

	while true do
		local data, ip, port = sock:receivefrom()
		if data then
			mrTextUi:setString(mrMessages["data"])


			if data:sub(1, #PING) == PING then
				mrTextUi:setString(PING)
				sock:sendto(PONG..(MOAIEnvironment.devName or "unknown") , ip, port)
				mrTextUi:setString(mrMessages["sendto"])
			elseif data:sub(1, #LAUNCH) == LAUNCH then

				mrTextUi:setString(mrMessages["execute"])
				local dataSock = assert(socket.tcp())
				assert(dataSock:connect(ip, 9002))
				local source = socket.source("until-closed", dataSock)
				local archivePath = MOAIEnvironment.documentDirectory.."/prog.moai"
				local file = assert(io.open(archivePath, "wb"))
				local sink = ltn12.sink.file(file)
				while ltn12.pump.step(source, sink) do
					coroutine.yield()
				end
				sock:close()
				dataSock:close()
				local pwd = MOAIFileSystem.getWorkingDirectory()
				MOAIFileSystem.mountVirtualDirectory(pwd, archivePath)
				mrTextUi:setString(mrMessages["returntomain"])
				return dofile("main.lua")
			end
		end
		coroutine.yield()
	end
end

local runner = MOAICoroutine.new()

runner:run(runnerFunc)

