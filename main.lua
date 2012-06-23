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
			if data:sub(1, #PING) == PING then
				sock:sendto(PONG..MOAIEnvironment.devName, ip, port)
			elseif data:sub(1, #LAUNCH) == LAUNCH then
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
				return dofile("main.lua")
			end
		end
		coroutine.yield()
	end
end

local runner = MOAICoroutine.new()
runner:run(runnerFunc)
