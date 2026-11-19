#!/usr/bin/env python3
import json
import os
import sys

def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/kr_cloud_fetch.json"
    result = {
        "encar_dom_count": 0,
        "encar_dom_items": [],
        "encar_imp_count": 0,
        "encar_imp_items": [],
        "encar_all_count": 0,
        "kb_opt": None,
        "kb_html": ""
    }
    chrome_bin = "/usr/bin/google-chrome"
    if not os.path.exists(chrome_bin):
        chrome_bin = "/usr/bin/google-chrome-stable"

    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as p:
            browser = p.chromium.launch(
                executable_path=chrome_bin if os.path.exists(chrome_bin) else None,
                headless=True,
                args=[
                    "--headless=new",
                    "--no-sandbox",
                    "--disable-blink-features=AutomationControlled",
                    "--disable-dev-shm-usage",
                    "--window-size=1440,900"
                ]
            )
            ctx = browser.new_context(
                locale="ko-KR",
                timezone_id="Asia/Seoul",
                viewport={"width": 1440, "height": 900},
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
                extra_http_headers={
                    "sec-ch-ua": '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
                    "sec-ch-ua-mobile": "?0",
                    "sec-ch-ua-platform": '"Windows"',
                    "Accept-Language": "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7"
                }
            )
            ctx.add_init_script("""
                Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                window.chrome = { runtime: {} };
                Object.defineProperty(navigator, 'languages', {get: () => ['ko-KR', 'ko', 'en-US', 'en']});
                Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
            """)
            page = ctx.new_page()

            captured_api = []
            def on_resp(resp):
                if "api.encar.com/search/car/list" in resp.url:
                    try:
                        captured_api.append((resp.status, resp.url, resp.text()[:200]))
                    except Exception:
                        pass
            page.on("response", on_resp)

            try:
                page.goto("https://car.encar.com/list/car?page=1", wait_until="domcontentloaded", timeout=25000)
                page.wait_for_timeout(5000)
                print(f"[cloud_browser_fetch] car.encar.com captured_api count={len(captured_api)}, sample={captured_api[:1]}", file=sys.stderr)
            except Exception as e0:
                print(f"[cloud_browser_fetch] car.encar.com warmup note: {e0}", file=sys.stderr)

            try:
                first_url = "https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.Y._.Separation.A.)&sr=%7CModifiedDate%7C0%7C500"
                page.goto(first_url, wait_until="domcontentloaded", timeout=25000)

                ready_json = False
                last_html = ""
                for _ in range(30):
                    try:
                        txt = page.evaluate("() => document.body ? document.body.innerText.trim() : ''")
                        last_html = page.evaluate("() => document.documentElement ? document.documentElement.innerHTML.slice(0, 260) : ''")
                        if txt.startswith("{") and '"Count"' in txt:
                            ready_json = True
                            break
                    except Exception:
                        pass
                    page.wait_for_timeout(500)

                if not ready_json:
                    clean_snip = last_html.replace("\n", " ").replace("\r", " ")
                    print(f"[cloud_browser_fetch] api.encar.com non-JSON html={clean_snip}", file=sys.stderr)
                else:
                    encar_data = page.evaluate("""async () => {
                        const getJson = async (path) => {
                            const r = await fetch(path, { credentials: 'include' });
                            return await r.json();
                        };
                        const domFirst = await getJson('/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.Y._.Separation.A.)&sr=%7CModifiedDate%7C0%7C500');
                        const domCount = domFirst.Count || 0;
                        let domItems = domFirst.SearchResults || [];
                        for (let off = 500; off < domCount; off += 500) {
                            const b = await getJson('/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.Y._.Separation.A.)&sr=%7CModifiedDate%7C' + off + '%7C500');
                            if (b.SearchResults) domItems = domItems.concat(b.SearchResults);
                        }

                        const impFirst = await getJson('/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.N._.Separation.A.)&sr=%7CModifiedDate%7C0%7C500');
                        const impCount = impFirst.Count || 0;
                        let impItems = impFirst.SearchResults || [];
                        for (let off = 500; off < impCount; off += 500) {
                            const b = await getJson('/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.N._.Separation.A.)&sr=%7CModifiedDate%7C' + off + '%7C500');
                            if (b.SearchResults) impItems = impItems.concat(b.SearchResults);
                        }

                        const tot = await getJson('/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.A.)');
                        return { domCount, domItems, impCount, impItems, allCount: tot.Count || 0 };
                    }""")
                    result["encar_dom_count"] = encar_data.get("domCount", 0)
                    result["encar_dom_items"] = encar_data.get("domItems", [])
                    result["encar_imp_count"] = encar_data.get("impCount", 0)
                    result["encar_imp_items"] = encar_data.get("impItems", [])
                    result["encar_all_count"] = encar_data.get("allCount", 0)
            except Exception as e:
                print(f"[cloud_browser_fetch] Encar fetch note: {e}", file=sys.stderr)

            browser.close()
    except Exception as e:
        print(f"[cloud_browser_fetch] Outer note: {e}", file=sys.stderr)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False)

if __name__ == "__main__":
    main()
