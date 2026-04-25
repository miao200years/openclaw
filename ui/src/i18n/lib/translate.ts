import { getSafeLocalStorage } from "../../local-storage.ts";
import { zh_CN } from "../locales/zh-CN.ts";
import { DEFAULT_LOCALE, SUPPORTED_LOCALES, isSupportedLocale } from "./registry.ts";
import type { Locale, TranslationMap } from "./types.ts";

type Subscriber = (locale: Locale) => void;

export { SUPPORTED_LOCALES, isSupportedLocale };

/**
 * I18nManager —— 中文独占版本。
 *
 * 设计要点：
 * - Control UI 锁定为简体中文（zh-CN），不再支持运行时语言切换。
 * - zh-CN 翻译在模块加载时同步就绪，消除首屏英文闪烁问题。
 * - 保留 setLocale / subscribe / registerTranslation 等 API，
 *   以便既有组件无需修改即可继续工作，但任何非 zh-CN 的目标
 *   语言都会被静默忽略。
 */
class I18nManager {
  private locale: Locale = "zh-CN";
  private translations: Partial<Record<Locale, TranslationMap>> = { "zh-CN": zh_CN };
  private subscribers: Set<Subscriber> = new Set();

  constructor() {
    // 清理历史版本遗留在 localStorage 中的其他语言偏好，
    // 避免用户升级后依然读到不再支持的 locale 值。
    this.normalizeStoredLocale();
  }

  private normalizeStoredLocale() {
    const storage = getSafeLocalStorage();
    if (!storage) {
      return;
    }
    try {
      const saved = storage.getItem("openclaw.i18n.locale");
      if (saved !== "zh-CN") {
        storage.setItem("openclaw.i18n.locale", "zh-CN");
      }
    } catch {
      // 私有/受限存储场景忽略。
    }
  }

  public getLocale(): Locale {
    return this.locale;
  }

  /**
   * 中文独占模式下仅接受 "zh-CN"，其他目标语言请求将被忽略。
   * 保留 async 签名以保持 API 兼容。
   */
  public async setLocale(locale: Locale) {
    if (locale !== "zh-CN") {
      return;
    }
    // 已经是 zh-CN，无需触发通知。
    return;
  }

  public registerTranslation(locale: Locale, map: TranslationMap) {
    this.translations[locale] = map;
  }

  public subscribe(sub: Subscriber) {
    this.subscribers.add(sub);
    return () => this.subscribers.delete(sub);
  }

  private notify() {
    this.subscribers.forEach((sub) => sub(this.locale));
  }

  public t(key: string, params?: Record<string, string>): string {
    const keys = key.split(".");
    let value: unknown = this.translations[this.locale] || this.translations[DEFAULT_LOCALE];

    for (const k of keys) {
      if (value && typeof value === "object") {
        value = (value as Record<string, unknown>)[k];
      } else {
        value = undefined;
        break;
      }
    }

    if (typeof value !== "string") {
      return key;
    }

    if (params) {
      return value.replace(/\{(\w+)\}/g, (_, k) => params[k] || `{${k}}`);
    }

    return value;
  }
}

export const i18n = new I18nManager();
export const t = (key: string, params?: Record<string, string>) => i18n.t(key, params);
