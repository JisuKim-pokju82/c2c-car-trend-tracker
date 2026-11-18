#!/usr/bin/env python3
import json
import os
import sys

def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/kr_cloud_fetch.json"
    result = {"encar_dom": None, "encar_imp": None, "encar_all_count": 0, "kb_opt": None, "kb_html": ""}
    chrome_bin = "/usr/bin/google-chrome"
    if not os.path.exists(chrome_bin):
        chrome_bin = "/usr/bin/google-chrome-stable"

    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as p:
            browser = p.chromium.launch(
                executable_path=chrome_bin if os.path.exists(chrome_bin) else None,
                headless=True,
                args=["--no-sandbox", "--disable-blink-features=AutomationControlled", "--disable-dev-shm-usage"]
            )
            ctx = browser.new_context(
                locale="ko-KR",
                timezone_id="Asia/Seoul",
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
            )
            ctx.add_init_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined});")
            page = ctx.new_page()

            # 1. Try Encar via real Chrome context
            try:
                page.goto("http://www.encar.com/", wait_until="domcontentloaded", timeout=15000)
                page.wait_for_timeout(2500)
                encar_data = page.evaluate("""async () => {
                    const getJson = async (u) => {
                        const r = await fetch(u, { credentials: 'include' });
                        const txt = await r.text();
                        return JSON.parse(txt);
                    };
                    const dom = await getJson('https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.Y._.Separation.A.)&sr=%7CModifiedDate%7C0%7C500');
                    const imp = await getJson('https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.N._.Separation.A.)&sr=%7CModifiedDate%7C0%7C500');
                    const tot = await getJson('https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.A.)');
                    return { dom, imp, allCount: tot.Count || 0 };
                }""")
                result["encar_dom"] = encar_data.get("dom")
                result["encar_imp"] = encar_data.get("imp")
                result["encar_all_count"] = encar_data.get("allCount", 0)
            except Exception as e:
                print(f"[cloud_browser_fetch] Encar browser attempt note: {e}", file=sys.stderr)

            # 2. Try KB ChaChaCha via real Chrome context
            try:
                page.goto("https://www.kbchachacha.com/public/search/main.kbc", wait_until="domcontentloaded", timeout=15000)
                page.wait_for_timeout(2000)
                kb_data = page.evaluate("""async () => {
                    const r1 = await fetch('https://www.kbchachacha.com/public/search/optionSale.json', { credentials: 'include' });
                    const opt = await r1.json();
                    const r2 = await fetch('https://www.kbchachacha.com/public/search/list.empty?page=1&sort=-orderDate&directYn=Y', { credentials: 'include' });
                    const html = await r2.text();
                    return { opt, html };
                }""")
                result["kb_opt"] = kb_data.get("opt")
                result["kb_html"] = kb_data.get("html", "")
            except Exception as e:
                print(f"[cloud_browser_fetch] KB browser attempt note: {e}", file=sys.stderr)

            browser.close()
    except Exception as e:
        print(f"[cloud_browser_fetch] Outer note: {e}", file=sys.stderr)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False)

if __name__ == "__main__":
    main()
