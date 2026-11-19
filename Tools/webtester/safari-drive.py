#!/usr/bin/env python3
"""Drives Safari through safaridriver (W3C WebDriver) over the web tester: the automatic tests and the API inventory, then
every test under Asks clicked for real (WebDriver's click is a user gesture), JavaScript dialogs answered, and the test
extension installed (WebDriver's "Load Web Extension", where Safari has it). Its results are saved as `safari-driven`
(`navigator.webdriver` is true in them) beside a person's `safari`.

Safari must not be running: safaridriver launches its own, and refuses a Safari a person opened ("Safari was not launched
for automation"). Remote automation must be allowed once (Safari › Settings › Developer › Allow remote automation, or
`safaridriver --enable`).

Usage: safari-drive.py BASE_URL EXTENSION_FOLDER [driver port]
"""
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request

BASE = sys.argv[1].rstrip("/")
EXTENSION = sys.argv[2]
PORT = int(sys.argv[3]) if len(sys.argv) > 3 else 4447
DRIVER = f"http://127.0.0.1:{PORT}"
LABEL = "safari-driven"

# Asks that open what WebDriver cannot answer (a system picker, a sheet, a device chooser): left for a person.
FOR_A_PERSON = {
    "ask-open-file", "ask-save-file", "ask-folder", "ask-input-file", "ask-print", "ask-share", "ask-eyedropper",
    "ask-bluetooth", "ask-usb", "ask-hid", "ask-serial", "ask-passkey-create", "ask-passkey-get", "ask-speaker",
    "ask-screen", "ask-screen-audio", "ask-screen-tab",
}
# Asks that raise a permission prompt: run last, each given a short while (a prompt nobody answers is a timeout).
PROMPTING = {
    "ask-camera", "ask-microphone", "ask-both", "ask-device-names", "ask-geolocation", "ask-notification", "ask-midi",
    "ask-listen", "ask-clip-read", "ask-clip-items",
}


def request(method, path, body=None, timeout=60):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(DRIVER + path, data=data, method=method, headers={"content-type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as answer:
            return json.loads(answer.read() or b"{}").get("value")
    except urllib.error.HTTPError as error:
        value = json.loads(error.read() or b"{}").get("value", {})
        raise RuntimeError(f"{value.get('error', error.code)}: {value.get('message', '')}") from None


def script(session, source, *args):
    return request("POST", f"/session/{session}/execute/sync", {"script": source, "args": list(args)})


def answer_dialog(session):
    """Accepts a JavaScript dialog if one is open (a prompt gets a text first); whether there was one."""
    try:
        text = request("GET", f"/session/{session}/alert/text", timeout=5)
    except RuntimeError:
        return False
    try:
        request("POST", f"/session/{session}/alert/text", {"text": "driven"}, timeout=5)
    except RuntimeError:
        pass
    request("POST", f"/session/{session}/alert/accept", {}, timeout=5)
    print(f"    dialog answered: {text!r}")
    return True


def click_and_wait(session, test, wait):
    element = request("POST", f"/session/{session}/element", {"using": "css selector", "value": f'[data-try="{test}"]'})
    key = next(iter(element.values()))
    request("POST", f"/session/{session}/element/{key}/click", {}, timeout=30)
    deadline = time.time() + wait
    while time.time() < deadline:
        answer_dialog(session)
        try:
            state = script(session, "return document.querySelector(`[data-test='${arguments[0]}']`).dataset.state", test)
        except RuntimeError:
            state = None
        if state and state not in ("waiting", "running"):
            return state
        time.sleep(0.5)
    return "no answer (a prompt waiting for a person?)"


def main():
    driver = subprocess.Popen(["safaridriver", "-p", str(PORT)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    session = None
    try:
        for _ in range(50):
            try:
                urllib.request.urlopen(DRIVER + "/status", timeout=1)
                break
            except OSError:
                time.sleep(0.1)
        try:
            session = request("POST", "/session", {"capabilities": {"alwaysMatch": {"browserName": "safari"}}}, timeout=40)["sessionId"]
        except Exception as error:
            print(f"no session: {error}")
            print("Quit Safari first (safaridriver launches its own), and allow remote automation once.")
            return 1
        print(f"session {session}")

        request("POST", f"/session/{session}/url", {"url": f"{BASE}/index.html?browser={LABEL}&auto=1"})
        for _ in range(120):
            if script(session, "return document.body.dataset.done") == "yes":
                break
            time.sleep(0.5)
        print("automatic tests and the inventory: saved")

        asks = script(session, "return [...document.querySelectorAll('[data-try]')].map((b) => b.dataset.try)")
        plain = [a for a in asks if a not in FOR_A_PERSON and a not in PROMPTING]
        for test in plain + [a for a in asks if a in PROMPTING]:
            state = click_and_wait(session, test, 20 if test in PROMPTING else 15)
            print(f"  {test:28} {state}")
            # Whatever a test opened (full screen, a window), the page comes back to the front.
            answer_dialog(session)
            try:
                handles = request("GET", f"/session/{session}/window/handles")
                for handle in handles[1:]:
                    request("POST", f"/session/{session}/window", {"handle": handle})
                    request("DELETE", f"/session/{session}/window")
                request("POST", f"/session/{session}/window", {"handle": handles[0]})
            except RuntimeError:
                pass
        for test in sorted(set(asks) & FOR_A_PERSON):
            print(f"  {test:28} left for a person (a system picker or sheet)")
        script(session, "document.getElementById('save').click()")
        time.sleep(2)
        print("asks: saved")

        # The test extension, by WebDriver's Load Web Extension (W3C WebExtensions community group), where Safari has it.
        try:
            loaded = request("POST", f"/session/{session}/webextension", {"type": "path", "path": EXTENSION}, timeout=30)
            print(f"extension loaded: {loaded}")
            time.sleep(12)
        except RuntimeError as error:
            print(f"extension not loaded through the driver: {error}")
        return 0
    finally:
        if session:
            try:
                request("DELETE", f"/session/{session}", timeout=20)
            except Exception:
                pass
        driver.terminate()


if __name__ == "__main__":
    sys.exit(main())
