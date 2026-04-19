'use strict';
'require view';
'require form';
'require rpc';
'require ui';
'require poll';

var callStatus = rpc.declare({
	object: 'luci.fzu-network',
	method: 'status',
	expect: { online: false, msg: '', user: '-', ip: '-', mac: '-', log: '' }
});

var callClearLog = rpc.declare({
	object: 'luci.fzu-network',
	method: 'clearlog',
	expect: {}
});

function renderStatusTable(status) {
	return E('div', { 'class': 'cbi-section status-section' }, [
		E('h3', {}, _('状态')),
		E('div', { 'class': 'cbi-section-node' }, [
			E('table', { 'class': 'table' }, [
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left', 'style': 'width:33%' }, _('认证状态')),
					E('td', { 'class': 'td' }, status.online
						? E('span', { 'style': 'color:green;font-weight:bold' }, _('在线'))
						: E('div', {}, [
							E('span', { 'style': 'color:red;font-weight:bold' }, _('离线')),
							' ',
							E('em', {}, status.msg || '')
						])
					)
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('登录账号')),
					E('td', { 'class': 'td' }, status.user || '-')
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('IP 地址')),
					E('td', { 'class': 'td' }, status.ip || '-')
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('MAC 地址')),
					E('td', { 'class': 'td' }, status.mac || '-')
				])
			])
		])
	]);
}

function renderLog(status) {
	return E('div', { 'class': 'cbi-section' }, [
		E('h3', {}, _('日志')),
		E('div', { 'class': 'cbi-section-node' }, [
			E('pre', {
				'id': 'fzu-log',
				'style': 'max-height:300px;overflow:auto;font-size:12px;white-space:pre-wrap;word-break:break-all'
			}, status.log || _('（暂无日志）')),
			E('div', { 'style': 'margin-top:8px' }, [
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'click': ui.createHandlerFn(null, function() {
						return callClearLog().then(function() {
							var pre = document.getElementById('fzu-log');
							if (pre) pre.textContent = _('（暂无日志）');

						});
					})
				}, _('清除日志'))
			])
		])
	]);
}

return view.extend({
	load: function() {
		return callStatus();
	},

	render: function(status) {
		var m, s, o;

		m = new form.Map('fzu-network', '', '');

		s = m.section(form.NamedSection, 'base', 'base', _('设置'));
		s.anonymous = true;

		o = s.option(form.Flag, 'enable', _('启用'));
		o.rmempty = false;

		o = s.option(form.Value, 'school_no', _('学号'));
		o.rmempty = false;

		o = s.option(form.Value, 'password', _('密码'));
		o.password = true;
		o.rmempty = false;

		return m.render().then(function(formNode) {
			var statusNode = renderStatusTable(status);
			var node = E('div', {}, [
				statusNode,
				formNode,
				renderLog(status)
			]);

			poll.add(function() {
				return callStatus().then(function(st) {
					var newStatus = renderStatusTable(st);
					statusNode.parentNode.replaceChild(newStatus, statusNode);
					statusNode = newStatus;
					var pre = node.querySelector('#fzu-log');
					if (pre) pre.textContent = st.log || _('（暂无日志）');
				});
			}, 5);

			return node;
		});
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
