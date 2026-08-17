window.__ModuleLoader__.load({
	id: "dsh-studio",
	factory: (require) => {
		var module = { exports: {} };
		var exports = module.exports;
		Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });
		let react = require("react");
		let react_jsx_runtime = require("react/jsx-runtime");
		//#region src/client/index.tsx
		/**
		* dsh-studio client 端：DSH Web UI 内的「自动工作室」面板
		* - ctx.slots.inject('settings.section') 注册设置页一级菜单「DSH Studio」
		* - 面板：任务便签四象限（勾选即时写回）+ 面板入口
		* - 数据经 host REST API（/api2/dsh-studio/*）读写同一份 note-data.json
		* 参考模式：dsh-web-plugin-manager（register(spec, Component)）
		*/
		const inject = ["slots"];
		function NotePanel(_props) {
			const [data, setData] = (0, react.useState)(null);
			const [error, setError] = (0, react.useState)("");
			const reload = () => {
				fetch("/api2/dsh-studio/data").then((r) => r.json()).then((j) => j.ok ? setData(j.data) : setError(j.error || "加载失败")).catch((e) => setError(String(e)));
			};
			(0, react.useEffect)(() => {
				reload();
			}, []);
			const toggle = (g, i) => {
				if (!data) return;
				const next = JSON.parse(JSON.stringify(data));
				next.groups[g].items[i].done = !next.groups[g].items[i].done;
				fetch("/api2/dsh-studio/data", {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({ data: next })
				}).then((r) => r.json()).then((j) => {
					if (j.ok) setData(next);
				});
			};
			if (error) return /* @__PURE__ */ (0, react_jsx_runtime.jsxs)("div", {
				style: {
					padding: 16,
					color: "#c0392b"
				},
				children: ["DSH Studio：", error]
			});
			if (!data) return /* @__PURE__ */ (0, react_jsx_runtime.jsx)("div", {
				style: { padding: 16 },
				children: "DSH Studio 加载中…"
			});
			return /* @__PURE__ */ (0, react_jsx_runtime.jsxs)("div", {
				style: {
					padding: 8,
					maxWidth: 860
				},
				children: [
					/* @__PURE__ */ (0, react_jsx_runtime.jsxs)("h3", {
						style: { margin: "0 0 4px" },
						children: [
							data.date ?? "",
							" · ",
							data.title ?? "DSH Studio"
						]
					}),
					data.aiNote ? /* @__PURE__ */ (0, react_jsx_runtime.jsxs)("div", {
						style: {
							opacity: .65,
							fontSize: 12,
							marginBottom: 10
						},
						children: ["AI · ", data.aiNote]
					}) : null,
					/* @__PURE__ */ (0, react_jsx_runtime.jsx)("div", {
						style: {
							display: "grid",
							gridTemplateColumns: "1fr 1fr",
							gap: 12
						},
						children: data.groups.map((grp, g) => /* @__PURE__ */ (0, react_jsx_runtime.jsxs)("div", {
							style: {
								border: "1px solid #e5dfd0",
								borderRadius: 10,
								padding: "8px 10px",
								background: "#fffdf2"
							},
							children: [/* @__PURE__ */ (0, react_jsx_runtime.jsxs)("div", {
								style: {
									display: "flex",
									alignItems: "center",
									gap: 6,
									fontWeight: 600,
									fontSize: 13
								},
								children: [/* @__PURE__ */ (0, react_jsx_runtime.jsx)("span", { style: {
									width: 4,
									height: 14,
									background: grp.color,
									borderRadius: 2,
									display: "inline-block"
								} }), grp.name]
							}), /* @__PURE__ */ (0, react_jsx_runtime.jsx)("div", {
								style: { marginTop: 6 },
								children: grp.items.map((item, i) => /* @__PURE__ */ (0, react_jsx_runtime.jsxs)("label", {
									style: {
										display: "flex",
										alignItems: "center",
										gap: 8,
										padding: "3px 0",
										fontSize: 13,
										cursor: "pointer"
									},
									children: [
										/* @__PURE__ */ (0, react_jsx_runtime.jsx)("input", {
											type: "checkbox",
											checked: !!item.done,
											onChange: () => toggle(g, i)
										}),
										/* @__PURE__ */ (0, react_jsx_runtime.jsx)("span", {
											style: {
												textDecoration: item.done ? "line-through" : "none",
												opacity: item.done ? .55 : 1
											},
											children: item.text
										}),
										item.slot ? /* @__PURE__ */ (0, react_jsx_runtime.jsx)("span", {
											style: {
												fontSize: 10,
												opacity: .5,
												marginLeft: "auto"
											},
											children: item.slot
										}) : null,
										item.link ? /* @__PURE__ */ (0, react_jsx_runtime.jsx)("a", {
											href: item.link,
											title: item.link,
											onClick: (e) => e.stopPropagation(),
											style: {
												fontSize: 10,
												color: "#2f6fa3"
											},
											children: "文档"
										}) : null
									]
								}, i))
							})]
						}, g))
					})
				]
			});
		}
		function apply(ctx) {
			ctx.slots.inject("settings.section", () => ctx.slots.register({
				name: "settings.section",
				id: "dsh-studio",
				order: 30,
				label: () => "DSH Studio"
			}, NotePanel));
		}
		//#endregion
		exports.apply = apply;
		exports.inject = inject;
		return module.exports;
	}
});
