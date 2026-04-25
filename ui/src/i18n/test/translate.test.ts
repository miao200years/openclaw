import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createStorageMock } from "../../test-helpers/storage.ts";
import { pt_BR } from "../locales/pt-BR.ts";
import { zh_CN } from "../locales/zh-CN.ts";
import { zh_TW } from "../locales/zh-TW.ts";

type TranslateModule = typeof import("../lib/translate.ts");

// 中文独占模式下的 i18n 测试。
// 产品形态已从"运行时多语言切换"调整为"仅支持 zh-CN"，
// 因此这里不再测试英文或其他 locale，仅验证 zh-CN 行为与 API 兼容性。
describe("i18n (zh-CN lock)", () => {
  let translate: TranslateModule;

  beforeEach(async () => {
    vi.resetModules();
    vi.stubGlobal("localStorage", createStorageMock());
    vi.stubGlobal("navigator", { language: "en-US" } as Navigator);
    translate = await import("../lib/translate.ts");
    localStorage.clear();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("defaults to zh-CN regardless of navigator.language", () => {
    expect(translate.i18n.getLocale()).toBe("zh-CN");
  });

  it("returns the key when translation is missing", () => {
    expect(translate.t("non.existent.key")).toBe("non.existent.key");
  });

  it("returns the simplified Chinese translation by default", () => {
    expect(translate.t("common.health")).toBe("健康状况");
  });

  it("replaces parameters in translated strings", () => {
    // overview.stats.cronNext 中包含 {time} 占位符。
    const result = translate.t("overview.stats.cronNext", { time: "10:00" });
    expect(result).toContain("10:00");
  });

  it("silently ignores setLocale requests targeting non-zh-CN locales", async () => {
    // 任何尝试切换到其他语言的调用都应被静默忽略，保持 zh-CN。
    await translate.i18n.setLocale("en");
    expect(translate.i18n.getLocale()).toBe("zh-CN");
    expect(translate.t("common.health")).toBe("健康状况");

    await translate.i18n.setLocale("zh-TW");
    expect(translate.i18n.getLocale()).toBe("zh-CN");
  });

  it("accepts setLocale(\"zh-CN\") as a no-op", async () => {
    await translate.i18n.setLocale("zh-CN");
    expect(translate.i18n.getLocale()).toBe("zh-CN");
    expect(translate.t("common.health")).toBe("健康状况");
  });

  it("normalizes any legacy non-zh-CN localStorage value on startup", async () => {
    vi.resetModules();
    const storage = createStorageMock();
    vi.stubGlobal("localStorage", storage);
    vi.stubGlobal("navigator", { language: "en-US" } as Navigator);
    storage.setItem("openclaw.i18n.locale", "en");

    const fresh = await import("../lib/translate.ts");
    expect(fresh.i18n.getLocale()).toBe("zh-CN");
    expect(storage.getItem("openclaw.i18n.locale")).toBe("zh-CN");
  });

  it("skips node localStorage accessors that warn without a storage file", async () => {
    vi.resetModules();
    vi.unstubAllGlobals();
    vi.stubGlobal("navigator", { language: "en-US" } as Navigator);
    const warningSpy = vi.spyOn(process, "emitWarning").mockImplementation(() => {});

    const fresh = await import("../lib/translate.ts");

    expect(fresh.i18n.getLocale()).toBe("zh-CN");
    expect(warningSpy).not.toHaveBeenCalledWith(
      "`--localstorage-file` was provided without a valid path",
      expect.anything(),
      expect.anything(),
    );
  });

  it("keeps the version label available in shipped locales", () => {
    // 保留对 pt-BR / zh-TW locale 文件结构的静态检查，
    // 避免未使用的 locale 文件因疏忽漏掉关键字段。
    expect((pt_BR.common as { version?: string }).version).toBeTruthy();
    expect((zh_CN.common as { version?: string }).version).toBeTruthy();
    expect((zh_TW.common as { version?: string }).version).toBeTruthy();
  });
});
