import { describe, expect, it } from "vitest";
import {
  DEFAULT_LOCALE,
  SUPPORTED_LOCALES,
  isSupportedLocale,
  loadLazyLocaleTranslation,
  resolveNavigatorLocale,
} from "../../ui/src/i18n/lib/registry.ts";

// Control UI 已切换为中文独占模式（zh-CN）。
// 该测试同步覆盖新行为：SUPPORTED_LOCALES 仅含 zh-CN，
// resolveNavigatorLocale 恒返回 zh-CN，懒加载接口整体保留但恒为 null。
describe("ui i18n locale registry (zh-CN lock)", () => {
  it("exposes zh-CN as the only supported locale", () => {
    expect(SUPPORTED_LOCALES).toEqual(["zh-CN"]);
    expect(DEFAULT_LOCALE).toBe("zh-CN");
  });

  it("isSupportedLocale accepts zh-CN and rejects others", () => {
    expect(isSupportedLocale("zh-CN")).toBe(true);
    expect(isSupportedLocale("en")).toBe(false);
    expect(isSupportedLocale("de")).toBe(false);
    expect(isSupportedLocale(null)).toBe(false);
    expect(isSupportedLocale(undefined)).toBe(false);
  });

  it("resolveNavigatorLocale always returns zh-CN", () => {
    expect(resolveNavigatorLocale("de-DE")).toBe("zh-CN");
    expect(resolveNavigatorLocale("es-ES")).toBe("zh-CN");
    expect(resolveNavigatorLocale("pt-PT")).toBe("zh-CN");
    expect(resolveNavigatorLocale("en-US")).toBe("zh-CN");
    expect(resolveNavigatorLocale("zh-HK")).toBe("zh-CN");
    expect(resolveNavigatorLocale("")).toBe("zh-CN");
  });

  it("loadLazyLocaleTranslation is a no-op that returns null", async () => {
    expect(await loadLazyLocaleTranslation("zh-CN")).toBeNull();
    expect(await loadLazyLocaleTranslation("en")).toBeNull();
    expect(await loadLazyLocaleTranslation("de")).toBeNull();
  });
});
