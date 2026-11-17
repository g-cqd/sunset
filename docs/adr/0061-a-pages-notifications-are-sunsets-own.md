---
status: accepted
date: 2026-11-17
---

# 0061 — A page's notifications are Sunset's own `Notification`, posted to the system

The owner, 2026-11-17 (roadmap 0035 D): "Web notifications don't work with system notifications".

## What was wrong

WebKit's `Notification` was switched on (`_setNotificationsEnabled`, web step g) and its permission question answered, but
in an app WebKit has nowhere to post a notification: probed in a real page with the site allowed,
`requestPermission()` gave `denied`, `Notification.permission` stayed `default`, and a notification fired `error`.

## Decision

1. **A script at the document's start puts Sunset's `Notification` in the page's world** (`WebNotifications`, main frame
   only): `permission`, `requestPermission()` (promise and callback), `new Notification(title, options)` with `show`,
   `error`, `click` and `close` events.
2. **The policy is Sunset's, by what WebKit says of the frame** (white paper §9): the site is the frame's security origin,
   never what the page sends; a frame inside the page gets nothing; the site's standing answer decides
   (`web.permissions.notifications`, the same panel as before when it was not answered; Allow Once lasts the page's life);
   at most one notification a second per page; title and body are one line each, without control or format characters,
   cut to 120 and 400 characters (`WebNotification`).
3. **The app posts it** to the notification centre (`AppWebNotifications`), the site as its subtitle; the system asks once
   whether Sunset may notify. It is shown while Sunset is in front too (a download's or a terminal's are not, as before).
   **A click** shows the page's tab (or kept entry) in the window that holds it, in front, and fires the page's `click`.

## Not done

- Notifications from service workers (push while no page is open): not supported.
- `tag`, `close()` and `icon` since roadmap 0036 E; `actions` and `requireInteraction` are not passed on.
- The click is not seen working: posting needs Sunset.app's identity and the person's leave, not probed from a test.
