module("luci.controller.fzu_network",package.seeall)
function index()
	entry({"admin","services","fzu-network"},cbi("fzu-network"),"福大校园网",58)
	entry({"admin","services","fzu-network","status"},call("action_status")).leaf=true
	entry({"admin","services","fzu-network","clearlog"},call("action_clearlog")).leaf=true
end

function action_status()
	local sys = require("luci.sys")
	local fs  = require("nixio.fs")
	local http = require("luci.http")

	local status_json = sys.exec(
		"curl -s --connect-timeout 3 -X POST " ..
		"-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' " ..
		"--data-urlencode 'userIndex=' " ..
		"'http://172.16.0.46/eportal/InterFace.do?method=getOnlineUserInfo' 2>/dev/null"
	)

	local online = false
	local msg, user, ip, mac = "无法连接到认证服务器", "-", "-", "-"

	if status_json and #status_json > 0 then
		local function jget(str, key)
			return str:match('"' .. key .. '"%s*:%s*"([^"]*)"') or "-"
		end
		local result = jget(status_json, "result")
		msg  = jget(status_json, "message")
		user = jget(status_json, "userName")
		ip   = jget(status_json, "userIp")
		mac  = jget(status_json, "userMac")
		online = (result == "success")
	end

	local log_content = ""
	if fs.access("/var/log/fzu-network.log") then
		log_content = sys.exec("tail -n 100 /var/log/fzu-network.log")
	end

	http.prepare_content("application/json")
	http.write('[{"online":' .. (online and "true" or "false") ..
		',"msg":"'  .. msg  .. '"' ..
		',"user":"' .. user .. '"' ..
		',"ip":"'   .. ip   .. '"' ..
		',"mac":"'  .. mac  .. '"' ..
		',"log":"'  .. (log_content:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '')) .. '"}]')
end

function action_clearlog()
	local http = require("luci.http")
	os.execute("> /var/log/fzu-network.log")
	http.prepare_content("application/json")
	http.write('{"ok":true}')
end
