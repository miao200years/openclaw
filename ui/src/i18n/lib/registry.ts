// 语言锁定：Control UI 仅提供简体中文（zh-CN）。
// 保留 Locale 联合类型以兼容既有 locale 文件的类型签名，
// 但运行时仅暴露并返回 "zh-CN"，忽略任何其他语言请求。
import type { Locale, TranslationMap } from "./types.ts";

export const DEFAULT_LOCALE: Locale = "zh-CN";

export const SUPPORTED_LOCALES: ReadonlyArray<Locale> = ["zh-CN"] as const;

export function isSupportedLocale(value: string | null | undefined): value is Locale {
  return value === "zh-CN";
}

/**
 * 中文独占模式下，navigator 语言探测永远返回 zh-CN。
 * 保留参数签名以兼容调用方。
 */
export function resolveNavigatorLocale(_navLang?: string): Locale {
  return "zh-CN";
}

/**
 * 中文独占模式下不再有"非默认语言"，懒加载路径直接返回 null，
 * 保留函数是为了兼容 translate.ts 的旧调用点。
 */
export async function loadLazyLocaleTranslation(_locale: Locale): Promise<TranslationMap | null> {
  return null;
}
