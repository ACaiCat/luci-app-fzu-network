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

local dv_ip = s:option(DummyValue, "_ip", "IP地址")
function dv_ip.cfgvalue(self, section) return info_ip end

local dv_mac = s:option(DummyValue, "_mac", "MAC地址")
function dv_mac.cfgvalue(self, section) return info_mac end

-- 基本设置
s = m:section(TypedSection, "base", "基本设置")
s.anonymous = true

enable = s:option(Flag, "enable", "启用")
enable.rmempty = false

school_no = s:option(Value, "school_no", "学号")
school_no.rmempty = false

password = s:option(Value, "password", "密码")
password.password = true
password.rmempty = false

time = s:option(Value, "time", "检测间隔", "Crontab表达式")
time.rmempty = false
time.default = "*/5 * * * *"

user_agent = s:option(Value, "user_agent", "User Agent")
user_agent.rmempty = false

local spacer = s:option(DummyValue, "_spacer", "")
spacer.rawhtml = true
function spacer.cfgvalue(self, section) return '<div style="margin-bottom:8px"></div>' end

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

function m.on_after_commit(map)
	luci.sys.call("/etc/init.d/fzu-network restart >/dev/null 2>&1 &")
end

-- 清空日志按钮 + 自动刷新状态的 JS
local refresh_js = s:option(DummyValue, "_refresh_js", "")
refresh_js.rawhtml = true
function refresh_js.cfgvalue(self, section)
	return [[<a href="javascript:void(0)" onclick="clearLog()" style="float:right;font-size:0.85em;">清空日志</a>
<script type="text/javascript">
function clearLog() {
	var xhr = new XMLHttpRequest();
	xhr.open('GET', L.url('admin/services/fzu-network/clearlog'), true);
	xhr.onreadystatechange = function() {
		if (xhr.readyState === 4) {
			var logEl = document.querySelector('textarea[id$="sylogtext"]');
			if (logEl) logEl.value = '';
		}
	};
	xhr.send();
}
</script>

<script type="text/javascript">
(function() {
	var interval = 5000;
	function updateStatus() {
		var xhr = new XMLHttpRequest();
		xhr.open('GET', L.url('admin/services/fzu-network/status'), true);
		xhr.onreadystatechange = function() {
			if (xhr.readyState === 4 && xhr.status === 200) {
				try {
					var d = JSON.parse(xhr.responseText)[0];
					var stEl = document.querySelector('[data-name="_status"] .cbi-value-field');
					if (stEl) stEl.innerHTML = d.online
						? '<span style="color:green;font-weight:bold;">● 已在线</span>'
						: '<span style="color:red;font-weight:bold;">● 未在线</span> &nbsp; <em>' + d.msg + '</em>';
					var userEl = document.querySelector('[data-name="_user"] .cbi-value-field');
					if (userEl) userEl.textContent = d.user;
					var ipEl = document.querySelector('[data-name="_ip"] .cbi-value-field');
					if (ipEl) ipEl.textContent = d.ip;
					var macEl = document.querySelector('[data-name="_mac"] .cbi-value-field');
					if (macEl) macEl.textContent = d.mac;
					var logEl = document.querySelector('textarea[id$="sylogtext"]');
					if (logEl) { logEl.value = d.log; logEl.scrollTop = logEl.scrollHeight; }
				} catch(e) {}
			}
		};
		xhr.send();
	}
	setTimeout(function tick() { updateStatus(); setTimeout(tick, interval); }, interval);
})();
</script>
]]
end

return m


