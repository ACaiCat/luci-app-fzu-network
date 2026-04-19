local fs = require("nixio.fs")
require("luci.sys")

local m, s

-- 查询校园网在线状态
local status_json = luci.sys.exec(
	"curl -s -X POST -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' " ..
	"--data-urlencode 'userIndex=' " ..
	"'http://172.16.0.46/eportal/InterFace.do?method=getOnlineUserInfo' 2>/dev/null"
)

local online = false
local info_result, info_msg, info_user, info_ip, info_mac = "未知", "无法连接到认证服务器", "-", "-", "-"

if status_json and #status_json > 0 then
	local ok, data = pcall(function()
		-- 简单解析 JSON 字段
		local function jget(str, key)
			return str:match('"' .. key .. '"%s*:%s*"([^"]*)"') or "-"
		end
		return {
			result  = jget(status_json, "result"),
			message = jget(status_json, "message"),
			user    = jget(status_json, "userName"),
			ip      = jget(status_json, "userIp"),
			mac     = jget(status_json, "userMac"),
		}
	end)
	if ok and data then
		info_result = data.result
		info_msg    = data.message
		info_user   = data.user
		info_ip     = data.ip
		info_mac    = data.mac
		online = (data.result == "success")
	end
end

m = Map("fzu-network", "福州大学校园网", "自动登录福州大学校园网认证。")

-- 在线状态展示
s = m:section(TypedSection, "base", "当前连接状态")
s.anonymous = true

local st = s:option(DummyValue, "_status", "认证状态")
st.rawhtml = true
function st.cfgvalue(self, section)
	if online then
		return '<span style="color:green;font-weight:bold;">● 已在线</span>'
	else
		return '<span style="color:red;font-weight:bold;">● 未在线</span> &nbsp; <em>' .. info_msg .. '</em>'
	end
end

local dv_user = s:option(DummyValue, "_user", "登录账号")
function dv_user.cfgvalue(self, section) return info_user end

local dv_ip = s:option(DummyValue, "_ip", "IP 地址")
function dv_ip.cfgvalue(self, section) return info_ip end

local dv_mac = s:option(DummyValue, "_mac", "MAC 地址")
function dv_mac.cfgvalue(self, section) return info_mac end

-- 基本设置
s = m:section(TypedSection, "base", "基本设置")
s.anonymous = true

enable = s:option(Flag, "enable", "启用")
enable.rmempty = false

school_no = s:option(Value, "school_no", "学号 / 工号")
school_no.rmempty = false

password = s:option(Value, "password", "密码")
password.password = true
password.rmempty = false

time = s:option(Value, "time", "检测间隔", "单位：分钟，范围：1-59")
time.rmempty = false
time.default = "5"

user_agent = s:option(Value, "user_agent", "User Agent")
user_agent.rmempty = false

-- 运行日志
s = m:section(TypedSection, "base", "运行日志")
s.anonymous = true

local log_file = "/var/log/fzu-network.log"
tvlog = s:option(TextValue, "sylogtext")
tvlog.rows = 16
tvlog.readonly = "readonly"
tvlog.wrap = "off"

function tvlog.cfgvalue(self, section)
	local content = ""
	if log_file and nixio.fs.access(log_file) then
		content = luci.sys.exec("tail -n 100 %s" % log_file)
	end
	return content
end

tvlog.write = function(self, section, value) end

local apply = luci.http.formvalue("cbi.apply")
if apply then
	io.popen("/etc/init.d/fzu-network restart")
end

return m


