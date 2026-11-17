---
status: accepted
date: 2026-11-17
---

# 0053 — Profiles: a web identity and a Pinned grid, chosen for a Space

Roadmap 0021, step P-a. R4 decided what a profile is ("a web identity: one WebKit data store… A Space has one profile;
several Spaces may share it"), that the Pinned grid is the profile's, where profiles are managed, and what changing and
deleting one do. The rest was decided by the builder while the owner was away (2026-11-17: "work on the profiles, please
take decisions, update the settings, and don't await for me"). Each point is his to change.

## Decision

1. **There is always the first profile**, named "Personal" until it is renamed. A Space that names no profile, or one
   that is gone, is of the first. What Sunset kept before profiles is the first's: the website data store there always
   was, and what was pinned.
2. **A profile's pages have their own website data** (cookies, logins, storage): the WebKit data store that has the
   profile's id. A private page's store is never a profile's.
3. **The Pinned grid is the profile's** (ADR-0050 said "the app's, per profile later"): the same in each of its Spaces,
   and what is open in it shows as open in all of them (the owner's note n80, for what is pinned). A window shows the
   grid of the profile of the Space it shows.
4. **A Space is given a profile in its editor**: a fourth row, Profile, there only once a second profile exists (the
   owner asked for three fields). A new Space is of the profile of the Space it is made from. With another profile a
   Space's pages are stopped and made again where they were, with that profile's data: Save is the confirmation R4 asks
   for, and the sheet says so.
5. **Profiles are made, named and removed in Settings > Web > Profiles.** Removing one asks first: its Spaces become the
   first profile's and their pages load again, what was pinned in it is closed, and its website data is erased. The
   first profile cannot be removed.
6. **They are kept with the session**, sealed, each with its grid; not in the configuration file.

## Not done, said plainly

- **History, what sites may do, how a site sees Sunset (ADR-0051) and zoom are still shared by all profiles.** R4 puts
  them in the profile. Only the website data and the Pinned grid are per profile today.
- **Downloads** go to the same place and list whatever the profile.
- **n80 for Favorites**: "tabs open in a profile should show active in every space of the said same profile… goes for
  pinned and favorites". Done for what is pinned. Favorites are the Space's (R4), and a new Space has a *copy* of them
  (the owner, ADR-0047): the copy and its original are two entries, and one being open does not show on the other. To
  make them one, either Favorites become the profile's, or copies stay linked to what they were copied from; it is his
  to choose (t152).
- A profile has a name only: no icon, no colour. Nothing in the sidebar or the tab bar names the profile shown (R4:
  "the profile and the Space in one button"). The Spaces menu does not list profiles.
- A link opened from outside goes to the Space shown, whatever its profile (R4: rules by site are R5's).
- Each profile in use adds WebKit's storage and network processes (R4: "to be measured"): not measured.

## Not seen

Nothing of it on screen: the screen was locked while it was built (accessibility then shows menus only). Tested: the
model (`ProfilesModelTests`), the session (`SessionProfilesTests`), and a page's data store by its profile
(`WebContentTests`). The Settings page, the editor's Profile row, a page loading again in another profile, and the
erasing of a removed profile's data were not seen run.
