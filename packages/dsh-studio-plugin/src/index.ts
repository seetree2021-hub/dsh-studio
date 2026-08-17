/**
 * dsh-studio host 端：cordis 插件
 * 提供 REST API 读写 note-data.json（任务便签数据）与面板配置
 * 参考模式：dsh-web-plugin-manager（ctx.inject(['webServer']) + webServer.register + handler(req,res)）
 */
import { Context } from '@deepseek-ai/cordis'
import z from '@deepseek-ai/schemastery'
import fs from 'node:fs'
import path from 'node:path'

export const name = 'dsh-studio'
export const inject = ['webServer']

export interface Config {
  dataPath: string
  panels: { text: string; target: string; color: string }[]
}
export const Config = z.object({
  dataPath: z.string().default(''),
  panels: z
    .array(
      z.object({
        text: z.string().required(),
        target: z.string().required(),
        color: z.string().default('#6B8EB2'),
      }),
    )
    .default([]),
}) as unknown as typeof z

const PREFIX = '/api2/dsh-studio'

function readJsonBody(req: any): Promise<any> {
  return new Promise((resolve, reject) => {
    let raw = ''
    req.on('data', (c: Buffer) => { raw += c })
    req.on('end', () => {
      try { resolve(raw ? JSON.parse(raw) : {}) } catch (e) { reject(e) }
    })
    req.on('error', reject)
  })
}
function sendJson(res: any, status: number, value: unknown) {
  res.writeHead(status, { 'content-type': 'application/json' })
  res.end(JSON.stringify(value))
}

export function apply(ctx: Context, config: any) {
  const dataPath = config?.dataPath || path.join(process.cwd(), 'note-data.json')

  ctx.inject(['webServer'], (webCtx) => {
    webCtx.effect(() => {
      const webServer: any = webCtx.get('webServer')
      const disposers: any[] = []
      const mount = (op: string, handler: (req: any, res: any) => Promise<void>) => {
        disposers.push(webServer.register({ kind: 'exact', path: `${PREFIX}/${op}`, handler }))
      }

      mount('health', async (_req, res) => sendJson(res, 200, { ok: true, name, dataPath }))
      mount('panels', async (_req, res) => sendJson(res, 200, { ok: true, panels: config?.panels ?? [] }))

      // 读/写便签数据（GET 读，POST 写）
      mount('data', async (req, res) => {
        try {
          if (req.method === 'POST') {
            const body = await readJsonBody(req)
            const payload = body?.data ?? body
            if (!payload || typeof payload !== 'object') {
              return sendJson(res, 400, { ok: false, error: '请求体需包含 data 对象' })
            }
            fs.mkdirSync(path.dirname(dataPath), { recursive: true })
            if (fs.existsSync(dataPath)) fs.copyFileSync(dataPath, dataPath + '.bak')
            fs.writeFileSync(dataPath, JSON.stringify(payload, null, 2), 'utf-8')
            return sendJson(res, 200, { ok: true })
          }
          if (!fs.existsSync(dataPath)) {
            return sendJson(res, 404, { ok: false, error: `数据文件不存在: ${dataPath}` })
          }
          const parsed = JSON.parse(fs.readFileSync(dataPath, 'utf-8'))
          return sendJson(res, 200, { ok: true, data: parsed })
        } catch (e: any) {
          return sendJson(res, 400, { ok: false, error: e?.message ?? String(e) })
        }
      })

      return () => { for (const d of disposers) d() }
    }, 'dsh-studio: routes')
  })
}
