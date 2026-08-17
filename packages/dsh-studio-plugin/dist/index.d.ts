/**
 * dsh-studio host 端：cordis 插件
 * 提供 REST API 读写 note-data.json（任务便签数据）与面板配置
 * 参考模式：dsh-web-plugin-manager（ctx.inject(['webServer']) + webServer.register + handler(req,res)）
 */
import { Context } from '@deepseek-ai/cordis';
import z from '@deepseek-ai/schemastery';
export declare const name = "dsh-studio";
export declare const inject: string[];
export interface Config {
    dataPath: string;
    panels: {
        text: string;
        target: string;
        color: string;
    }[];
}
export declare const Config: typeof z;
export declare function apply(ctx: Context, config: any): void;
