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
                args=["--no-sandbox", "--disable-blink-features=AutomationControlled", "--disable-dev-shm-usage"]
            )
            ctx = browser.new_context(
                locale="ko-KR",
                timezone_id="Asia/Seoul",
                viewport={"width": 1440, "height": 900},
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
            )
            ctx.add_init_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined});")
            page = ctx.new_page()

            def nav_json(url):
                resp = page.goto(url, wait_until="domcontentloaded", timeout=20000)
                status = resp.status if resp else 0
                body = resp.text() if resp else page.inner_text("body")
                try:
                    return json.loads(body)
                except Exception:
                    # Wait 4s in case JS bot-challenge cookie sets and reloads
                    page.wait_for_timeout(4000)
                    txt2 = page.evaluate("() => document.body ? document.body.innerText : ''")
                    try:
                        return json.loads(txt2)
                    except Exception:
                        snippet = (body or txt2)[:220].replace("\n", " ")
                        raise RuntimeError(f"HTTP {status} at {page.url}: {snippet}")

            # 1. Warm up session cookie on encar main/fem, then navigate directly to api.encar.com (no CORS!)
            try:
                r0 = page.goto("http://www.encar.com/index.do", wait_until="domcontentloaded", timeout=20000)
                page.wait_for_timeout(2500)
                print(f"[cloud_browser_fetch] www.encar.com status={r0.status if r0 else 0}, title={page.title()}", file=sys.stderr)
            except Exception as e0:
                print(f"[cloud_browser_fetch] www.encar.com warmup note: {e0}", file=sys.stderr)

            try:
                dom_first = nav_json("https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.Y._.Separation.A.)&sr=%7CModifiedDate%7C0%7C500")
                dom_count = int(dom_first.get("Count") or 0)
                dom_items = list(dom_first.get("SearchResults") or [])
                for off in range(500, dom_count, 500):
                    b = nav_json(f"https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.Y._.Separation.A.)&sr=%7CModifiedDate%7C{off}%7C500")
                    if b.get("SearchResults"):
                        dom_items.extend(b["SearchResults"])

                imp_first = nav_json("https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.N._.Separation.A.)&sr=%7CModifiedDate%7C0%7C500")
                imp_count = int(imp_first.get("Count") or 0)
                imp_items = list(imp_first.get("SearchResults") or [])
                for off in range(500, imp_count, 500):
                    b = nav_json(f"https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.N._.Separation.A.)&sr=%7CModifiedDate%7C{off}%7C500")
                    if b.get("SearchResults"):
                        imp_items.extend(b["SearchResults"])

                tot = nav_json("https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.A.)")
                result["encar_dom_count"] = dom_count
                result["encar_dom_items"] = dom_items
                result["encar_imp_count"] = imp_count
                result["encar_imp_items"] = imp_items
                result["encar_all_count"] = int(tot.get("Count") or 0)
            except Exception as e:
                print(f"[cloud_browser_fetch] Encar direct nav note: {e}", file=sys.stderr)

            # 2. KB ChaChaCha fallback if needed
            try:
                kb_opt = nav_json("https://www.kbchachacha.com/public/search/optionSale.json")
                r2 = page.goto("https://www.kbchachacha.com/public/search/list.empty?page=1&sort=-orderDate&directYn=Y", wait_until="domcontentloaded", timeout=20000)
                result["kb_opt"] = kb_opt
                result["kb_html"] = r2.text() if r2 else page.content()
            except Exception as e:
                print(f"[cloud_browser_fetch] KB direct nav note: {e}", file=sys.stderr)

            browser.close()
    except Exception as e:
        print(f"[cloud_browser_fetch] Outer note: {e}", file=sys.stderr)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False)

if __name__ == "__main__":
    main()
