# Launches Apple's PasswordManagerBrowserExtensionHelper as Chrome launches a native-messaging host (the origin as its argument,
# stdio framed by a 4-byte length) from a process that is not Chrome, sends one message, and reports what comes back (2026-11-19).
import json, struct, subprocess, sys, time, select
H = "/System/Cryptexes/App/System/Library/CoreServices/PasswordManagerBrowserExtensionHelper.app/Contents/MacOS/PasswordManagerBrowserExtensionHelper"
p = subprocess.Popen([H, "chrome-extension://pejdijmoenmkgeppbflobdenhhabjlaj/"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
msg = json.dumps({"cmd": 14, "tabId": 0, "frameId": 0, "url": "https://example.com/"}).encode()
time.sleep(0.5)
try:
    p.stdin.write(struct.pack("<I", len(msg)) + msg); p.stdin.flush()
except BrokenPipeError:
    print("pipe closed before the message")
ready, _, _ = select.select([p.stdout], [], [], 4)
if ready:
    head = p.stdout.read(4)
    if len(head) == 4:
        n = struct.unpack("<I", head)[0]
        print("answer:", p.stdout.read(n)[:400])
    else:
        print("stdout closed, read", head)
else:
    print("no answer in 4 s")
print("exit code:", p.poll())
p.kill()
print("stderr:", p.stderr.read()[:400])
