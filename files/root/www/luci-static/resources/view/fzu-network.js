"use strict";
"require view";
"require form";
"require dom";
"require rpc";
"require ui";
"require poll";

var callStatus = rpc.declare({
  object: "luci.fzu-network",
  method: "status",
});

var callClearLog = rpc.declare({
  object: "luci.fzu-network",
  method: "clearlog",
  expect: {},
});

var callRestart = rpc.declare({
  object: "luci.fzu-network",
  method: "restart",
});

var callCheck = rpc.declare({
  object: "luci.fzu-network",
  method: "check",
});

function fetchStatus() {
  return callStatus().then(function (st) {
    return st || {};
  });
}

/* 把最新状态写回已被渲染的表格和日志框 */
function applyStatus(st) {
  st = st || {};
  var tbl = document.getElementById("fzu-status-table");
  if (tbl) dom.content(tbl, statusRows(st));
  var pre = document.getElementById("fzu-log");
  if (pre) pre.textContent = st.log || "";
}

function statusRows(st) {
  st = st || {};
  return [
    E("tr", { class: "tr" }, [
      E(
        "td",
        {
          class: "td left",
          style: "width:10em;white-space:nowrap;padding-left:12px",
        },
        _("认证状态"),
      ),
      E(
        "td",
        { class: "td", style: "text-align:left;padding-left:12px" },
        st.online
          ? E("span", { style: "color:green;font-weight:bold" }, _("在线"))
          : E("span", {}, [
              E("span", { style: "color:red;font-weight:bold" }, _("离线")),
              "  ",
              E("em", {}, st.msg ? "(" + st.msg + ")" : ""),
            ]),
      ),
    ]),
    E("tr", { class: "tr" }, [
      E(
        "td",
        {
          class: "td left",
          style: "width:10em;white-space:nowrap;padding-left:12px",
        },
        _("登录账号"),
      ),
      E(
        "td",
        { class: "td", style: "text-align:left;padding-left:12px" },
        st.user || "-",
      ),
    ]),
    E("tr", { class: "tr" }, [
      E(
        "td",
        {
          class: "td left",
          style: "width:10em;white-space:nowrap;padding-left:12px",
        },
        _("IP 地址"),
      ),
      E(
        "td",
        { class: "td", style: "text-align:left;padding-left:12px" },
        st.ip || "-",
      ),
    ]),
    E("tr", { class: "tr" }, [
      E(
        "td",
        {
          class: "td left",
          style: "width:10em;white-space:nowrap;padding-left:12px",
        },
        _("MAC 地址"),
      ),
      E(
        "td",
        { class: "td", style: "text-align:left;padding-left:12px" },
        st.mac || "-",
      ),
    ]),
    E("tr", { class: "tr" }, [
      E(
        "td",
        {
          class: "td left",
          style: "width:10em;white-space:nowrap;padding-left:12px",
        },
        _("下次检查"),
      ),
      E(
        "td",
        { class: "td", style: "text-align:left;padding-left:12px" },
        st.remain >= 0
          ? st.remain + _(" 秒后")
          : E("span", { style: "color:#888" }, _("服务未运行")),
      ),
    ]),
  ];
}

return view.extend({
  load: function () {
    return fetchStatus();
  },

  render: function (status) {
    var m, s, o;

    m = new form.Map("fzu-network", _("福州大学校园网"), _("校园网工程A+"));

    /* 状态 section */
    s = m.section(form.NamedSection, "base", "base", _("状态"));
    s.anonymous = true;

    o = s.option(form.DummyValue, "_status_table");
    o.rawhtml = true;
    o.cfgvalue = function () {
      return E(
        "table",
        {
          class: "table",
          id: "fzu-status-table",
          style: "border-collapse:collapse;font-size:1rem",
        },
        statusRows(status),
      );
    };

    o = s.option(form.DummyValue, "_check_btn");
    o.rawhtml = true;
    o.cfgvalue = function () {
      return E(
        "button",
        {
          class: "btn cbi-button cbi-button-action",
          click: ui.createHandlerFn(null, function () {
            return callCheck()
              .then(function (res) {
                res = res || {};
                /* 成功不打扰，只在失败时提示 */
                if (res.result !== "ok") {
                  ui.addNotification(
                    null,
                    E("p", {}, res.msg || _("下发命令失败")),
                    "error",
                  );
                }
              })
              .catch(function (err) {
                ui.addNotification(
                  null,
                  E("p", {}, _("下发命令失败") + ": " + err),
                  "error",
                );
              })
              .then(function () {
                /* 命令是异步下发的，稍等一会再取状态 */
                return new Promise(function (resolve) {
                  window.setTimeout(resolve, 1500);
                });
              })
              .then(function () {
                return fetchStatus().then(applyStatus);
              });
          }),
        },
        _("刷新登录"),
      );
    };

    /* 设置 section */
    s = m.section(form.NamedSection, "base", "base", _("设置"));
    s.anonymous = true;

    o = s.option(form.Flag, "enable", _("启用"));
    o.rmempty = false;

    o = s.option(form.Value, "school_no", _("学号"));
    o.rmempty = false;

    o = s.option(form.Value, "password", _("密码"));
    o.password = true;
    o.rmempty = false;

    o = s.option(form.Value, "user_agent", _("User-Agent"));
    o.placeholder = "Mozilla/5.0 ...";
    o.rmempty = true;

    o = s.option(
      form.Value,
      "interval",
      _("检查间隔"),
      _("单位秒，范围 10-86400"),
    );
    o.datatype = "range(10, 86400)";
    o.placeholder = "180";
    o.rmempty = true;

    o = s.option(form.DummyValue, "_spacer_ua");
    o.rawhtml = true;
    o.cfgvalue = function () {
      return E("div", { style: "margin:4px 0" });
    };

    /* 日志 section */
    s = m.section(form.NamedSection, "base", "base", _("日志"));
    s.anonymous = true;

    o = s.option(form.DummyValue, "_log");
    o.rawhtml = true;
    o.cfgvalue = function () {
      return E(
        "pre",
        {
          id: "fzu-log",
          style:
            "max-height:200px;overflow-y:auto;font-size:12px;line-height:1.4;white-space:pre-wrap;word-break:break-all;background:var(--pre-bg,#f8f8f8);border:1px solid #ddd;border-radius:4px;padding:10px;margin:0",
        },
        status.log || "",
      );
    };

    o = s.option(form.DummyValue, "_log_btn");
    o.rawhtml = true;
    o.cfgvalue = function () {
      return E(
        "button",
        {
          class: "btn",
          style: "background:#e53935;color:#fff;border-color:#e53935",
          click: ui.createHandlerFn(null, function () {
            return callClearLog().then(function () {
              var pre = document.getElementById("fzu-log");
              if (pre) pre.textContent = "";
            });
          }),
        },
        _("清除日志"),
      );
    };

    o = s.option(form.DummyValue, "_spacer_log");
    o.rawhtml = true;
    o.cfgvalue = function () {
      return E("div", { style: "margin:4px 0" });
    };

    return m.render().then(function (node) {
      poll.add(function () {
        return fetchStatus().then(applyStatus);
      }, 5);
      return node;
    });
  },

  handleReset: null,
});
