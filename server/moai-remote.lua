local APP_NAME = "MOAI Remote Application Server"
local socket = require "socket"
local ltn12 = require "ltn12"
local PORT = 9001
local MAGIC_HEADER = "MOAI_REMOTE:"
local PING = MAGIC_HEADER.."PING"
local PONG = MAGIC_HEADER.."PONG:"
local LAUNCH = MAGIC_HEADER.."LAUNCH"
local dataSock = assert(socket.tcp())

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
	-- we'd like to go a bit faster  ..
	ltn12.BLOCKSIZE = ltn12.BLOCKSIZE * 16
	local file = assert(io.open(path, "rb"))
	local cmdSock = assert(socket.udp())
	dataSock:bind("*", 9002)
	assert(dataSock:listen(1))
	print("Deploying " .. path .. " to " .. address)
	cmdSock:sendto(LAUNCH, address, PORT)
	local client = dataSock:accept()
	local sink = socket.sink("close-when-done", client)
	local source = ltn12.source.file(file)
	local current = file:seek()
	local filesize = file:seek("end")
	file:seek("set", current)
	local pumps = filesize / ltn12.BLOCKSIZE
	while ltn12.pump.step(source, sink) do
		print(pumps .. "\n")
		pumps = pumps - 1
	end
	--ltn12.pump.all(source, sink, function() print(".") return true end)
	print("\n")
    dataSock:close()
    print("Deployed " .. path .. " to " .. address)
end

-- command entries, where an entry is a entry["command"], its [.f]unction, [.h]elp text..
local entries = {}
entries["search"] = {
help = "search for MoaiRemote clients with [timeout]..",
fn = function ()
	local timeout = arg[2] or 1
	search(timeout)
end}
entries["deploy"] = {
help = "deploy [moaiZipFile] to MoaiRemote [clientIPaddress]",
fn = function()
	local path = arg[2]
	local address = arg[3]
	deploy(path, address)
    dataSock:close()
end}
entries["help"] = {
help = "help for all commands [arg1] [arg2], etc",
fn = function()
	print("\n" .. arg[0] .. " = " .. APP_NAME)
	for command,entry in pairs(entries) do
		print ("\t" .. command .. " : " .. entry.help)
	end
end}

local cmd = arg[1]
local entry_function = entries[cmd or "help"]
if entry_function then
	--print ("Executing : " .. entry_function.c)
	entry_function.fn() 
else 
	print ("eh?")
end
