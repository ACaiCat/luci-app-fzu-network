module("luci.controller.fzu-network",package.seeall)
function index()
entry({"admin","services","fzu-network"},cbi("fzu-network"),"福大校园网",58)
end
