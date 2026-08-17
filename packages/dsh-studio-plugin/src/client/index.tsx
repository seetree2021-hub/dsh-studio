/**
 * dsh-studio client 端：DSH Web UI 内的「自动工作室」面板
 * - ctx.slots.inject('settings.section') 注册设置页一级菜单「DSH Studio」
 * - 面板：任务便签四象限（勾选即时写回）+ 面板入口
 * - 数据经 host REST API（/api2/dsh-studio/*）读写同一份 note-data.json
 * 参考模式：dsh-web-plugin-manager（register(spec, Component)）
 */
import { useEffect, useState } from 'react'

export const inject = ['slots']

interface NoteItem { text: string; done: boolean; slot?: string; topic?: string; link?: string }
interface NoteGroup { name: string; color: string; items: NoteItem[] }
interface NoteData {
  title?: string
  date?: string
  aiNote?: string
  groups: NoteGroup[]
}

function NotePanel(_props?: any) {
  const [data, setData] = useState<NoteData | null>(null)
  const [error, setError] = useState('')

  const reload = () => {
    fetch('/api2/dsh-studio/data')
      .then((r) => r.json())
      .then((j) => (j.ok ? setData(j.data) : setError(j.error || '加载失败')))
      .catch((e) => setError(String(e)))
  }
  useEffect(() => { reload() }, [])

  const toggle = (g: number, i: number) => {
    if (!data) return
    const next = JSON.parse(JSON.stringify(data)) as NoteData
    next.groups[g].items[i].done = !next.groups[g].items[i].done
    fetch('/api2/dsh-studio/data', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data: next }),
    })
      .then((r) => r.json())
      .then((j) => { if (j.ok) setData(next) })
  }

  if (error) {
    return <div style={{ padding: 16, color: '#c0392b' }}>DSH Studio：{error}</div>
  }
  if (!data) {
    return <div style={{ padding: 16 }}>DSH Studio 加载中…</div>
  }

  return (
    <div style={{ padding: 8, maxWidth: 860 }}>
      <h3 style={{ margin: '0 0 4px' }}>{data.date ?? ''} · {data.title ?? 'DSH Studio'}</h3>
      {data.aiNote ? (
        <div style={{ opacity: 0.65, fontSize: 12, marginBottom: 10 }}>AI · {data.aiNote}</div>
      ) : null}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        {data.groups.map((grp, g) => (
          <div key={g} style={{ border: '1px solid #e5dfd0', borderRadius: 10, padding: '8px 10px', background: '#fffdf2' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600, fontSize: 13 }}>
              <span style={{ width: 4, height: 14, background: grp.color, borderRadius: 2, display: 'inline-block' }} />
              {grp.name}
            </div>
            <div style={{ marginTop: 6 }}>
              {grp.items.map((item, i) => (
                <label key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '3px 0', fontSize: 13, cursor: 'pointer' }}>
                  <input type="checkbox" checked={!!item.done} onChange={() => toggle(g, i)} />
                  <span style={{ textDecoration: item.done ? 'line-through' : 'none', opacity: item.done ? 0.55 : 1 }}>
                    {item.text}
                  </span>
                  {item.slot ? <span style={{ fontSize: 10, opacity: 0.5, marginLeft: 'auto' }}>{item.slot}</span> : null}
                  {item.link ? (
                    <a href={item.link} title={item.link} onClick={(e) => e.stopPropagation()} style={{ fontSize: 10, color: '#2f6fa3' }}>
                      文档
                    </a>
                  ) : null}
                </label>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export function apply(ctx: any) {
  ctx.slots.inject('settings.section', () =>
    ctx.slots.register(
      {
        name: 'settings.section',
        id: 'dsh-studio',
        order: 30,
        label: () => 'DSH Studio',
      },
      NotePanel,
    ),
  )
}
