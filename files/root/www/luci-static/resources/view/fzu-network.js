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
  ];
}

return view.extend({
  load: function () {
    return callStatus().then(function (st) {
      return st || {};
    });
  },

  render: function (status) {
    var m, s, o;

    m = new form.Map("fzu-network", _("福州大学校园网"), _("校园网工程A+"));
    m.chain("fzu-network");

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

    o = s.option(form.Value, "time", _("检查间隔"));
    o.placeholder = "*/5 * * * *";
    o.rmempty = false;

    o = s.option(form.Value, "user_agent", _("User-Agent"));
    o.placeholder = "Mozilla/5.0 ...";
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
            "max-height:500px;overflow-y:auto;font-size:12px;line-height:1.4;white-space:pre-wrap;word-break:break-all;background:var(--pre-bg,#f8f8f8);border:1px solid #ddd;border-radius:4px;padding:10px;margin:0",
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
        return callStatus().then(function (st) {
          st = st || {};
          var tbl = document.getElementById("fzu-status-table");
          if (tbl) dom.content(tbl, statusRows(st));
          var pre = document.getElementById("fzu-log");
          if (pre) pre.textContent = st.log || "";
        });
      }, 5);
      return node;
    });
  },

  handleSaveApply: function (ev, mode) {
    return this.handleSave(ev).then(function () {
      return callRestart();
    });
  },

  handleReset: null,
});
