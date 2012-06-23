local socket = require "socket"
local ltn12 = require "ltn12"
local PORT = 9001
local MAGIC_HEADER = "MOAI_REMOTE:"
local PING = MAGIC_HEADER.."PING"
local PONG = MAGIC_HEADER.."PONG:"
local LAUNCH = MAGIC_HEADER.."LAUNCH"

local function search(timeout)
	local sock = assert(socket.udp())
	assert(sock:settimeout(timeout))
	assert(sock:setoption("broadcast", true))
	sock:sendto(PING, "255.255.255.255", 9001)
	while true do
		local data, ip, port = sock:receivefrom()
		if data then
			if data:sub(1, #PONG) == PONG then
				print(ip, data:sub(#PONG + 1))
			end
		else
			break
		end
	end
end

local function deploy(path, address)
	local file = assert(io.open(path, "rb"))
	local cmdSock = assert(socket.udp())
	local dataSock = assert(socket.tcp())
	dataSock:bind("*", 9002)
	assert(dataSock:listen(1))
	cmdSock:sendto(LAUNCH, address, PORT)
	local client = dataSock:accept()
	local sink = socket.sink("close-when-done", client)
	local source = ltn12.source.file(file)
	ltn12.pump.all(source, sink)
end

local cmd = arg[1]
if cmd == "search" then
	local timeout = arg[2] or 1
	search(timeout)
elseif cmd == "deploy" then
	local path = arg[2]
	local address = arg[3]
	deploy(path, address)
else
	print("Invalid command")
end
