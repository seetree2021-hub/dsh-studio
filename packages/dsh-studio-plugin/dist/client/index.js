import { jsxs as _jsxs, jsx as _jsx } from "react/jsx-runtime";
/**
 * dsh-studio client 端：DSH Web UI 内的「自动工作室」面板
 * - ctx.slots.inject('settings.section') 注册设置页一级菜单「DSH Studio」
 * - 面板：任务便签四象限（勾选即时写回）+ 面板入口
 * - 数据经 host REST API（/api2/dsh-studio/*）读写同一份 note-data.json
 * 参考模式：dsh-web-plugin-manager（register(spec, Component)）
 */
import { useEffect, useState } from 'react';
export const inject = ['slots'];
function NotePanel(_props) {
    const [data, setData] = useState(null);
    const [error, setError] = useState('');
    const reload = () => {
        fetch('/api2/dsh-studio/data')
            .then((r) => r.json())
            .then((j) => (j.ok ? setData(j.data) : setError(j.error || '加载失败')))
            .catch((e) => setError(String(e)));
    };
    useEffect(() => { reload(); }, []);
    const toggle = (g, i) => {
        if (!data)
            return;
        const next = JSON.parse(JSON.stringify(data));
        next.groups[g].items[i].done = !next.groups[g].items[i].done;
        fetch('/api2/dsh-studio/data', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ data: next }),
        })
            .then((r) => r.json())
            .then((j) => { if (j.ok)
            setData(next); });
    };
    if (error) {
        return _jsxs("div", { style: { padding: 16, color: '#c0392b' }, children: ["DSH Studio\uFF1A", error] });
    }
    if (!data) {
        return _jsx("div", { style: { padding: 16 }, children: "DSH Studio \u52A0\u8F7D\u4E2D\u2026" });
    }
    return (_jsxs("div", { style: { padding: 8, maxWidth: 860 }, children: [_jsxs("h3", { style: { margin: '0 0 4px' }, children: [data.date ?? '', " \u00B7 ", data.title ?? 'DSH Studio'] }), data.aiNote ? (_jsxs("div", { style: { opacity: 0.65, fontSize: 12, marginBottom: 10 }, children: ["AI \u00B7 ", data.aiNote] })) : null, _jsx("div", { style: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }, children: data.groups.map((grp, g) => (_jsxs("div", { style: { border: '1px solid #e5dfd0', borderRadius: 10, padding: '8px 10px', background: '#fffdf2' }, children: [_jsxs("div", { style: { display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600, fontSize: 13 }, children: [_jsx("span", { style: { width: 4, height: 14, background: grp.color, borderRadius: 2, display: 'inline-block' } }), grp.name] }), _jsx("div", { style: { marginTop: 6 }, children: grp.items.map((item, i) => (_jsxs("label", { style: { display: 'flex', alignItems: 'center', gap: 8, padding: '3px 0', fontSize: 13, cursor: 'pointer' }, children: [_jsx("input", { type: "checkbox", checked: !!item.done, onChange: () => toggle(g, i) }), _jsx("span", { style: { textDecoration: item.done ? 'line-through' : 'none', opacity: item.done ? 0.55 : 1 }, children: item.text }), item.slot ? _jsx("span", { style: { fontSize: 10, opacity: 0.5, marginLeft: 'auto' }, children: item.slot }) : null, item.link ? (_jsx("a", { href: item.link, title: item.link, onClick: (e) => e.stopPropagation(), style: { fontSize: 10, color: '#2f6fa3' }, children: "\u6587\u6863" })) : null] }, i))) })] }, g))) })] }));
}
export function apply(ctx) {
    ctx.slots.inject('settings.section', () => ctx.slots.register({
        name: 'settings.section',
        id: 'dsh-studio',
        order: 30,
        label: () => 'DSH Studio',
    }, NotePanel));
}
