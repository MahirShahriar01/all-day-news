# 8. Admin User Guide

This guide is for the person who manages the content of **All in One News**. No technical knowledge is needed. Everything you change here appears in users' apps **within about a minute** (the next time they open the app or pull to refresh). **No app update is needed.**

---

## 8.1 Signing in

1. Open `https://<your-domain>/admin/` in Chrome, Edge, Safari or Firefox (computer or tablet recommended; it also works on a phone).
2. Enter your **e-mail** and **password** → **Sign in**.
3. The first administrator's details were set when the server was installed. **Change that password immediately** (§8.11).

* After 5 wrong passwords, sign-in is locked for 5 minutes (this protects against password guessing).
* Forgotten password: ask an **owner** to set a new one (*Administrators → Edit*), or ask your technical contact to run `python -m app.cli reset-password you@example.com`.
* **Sign out** is at the bottom of the left menu. Sessions end automatically after 12 hours.

## 8.2 The dashboard

The first page shows:
* **Counts** of websites, categories, featured items and media files. Click a box to go there.
* **Quick start** with links to the most common tasks.
* **Recent activity**: who changed what and when.
* A warning if some websites have no category.

The menu on the left (☰ on small screens) has three groups: **Content**, **Appearance** and **Settings**.

---

## 8.3 Categories

Categories are the tabs in the app (News, Live Streaming, Sports, Technology, Entertainment, Education, Information, …).

**Create a category**
1. **Categories → ＋ New category**.
2. **Name**: e.g. *Live Streaming*.
3. **Description** (optional): shown in the category header.
4. **Icon**: pick a built-in icon (📰 📺 ⚽ 🎓 …), **or** upload your own **Icon image** (square PNG, 256×256 or larger).
5. **Background image** (optional): a wide picture (about 1200×600) shown behind the category title.
6. **Colour** (optional): the tab and header colour. Click the colour square to pick one, or **Clear** for automatic.
7. **Visible in the app**: switch off to hide the category (and its websites) without deleting anything.
8. **Save**.

**Change the order:** drag the **⠿** handle up or down. The order is saved immediately. With a keyboard, focus ⠿, press Space, move with the arrow keys and press Space again.

**Show/hide:** use the switch on the right of each category.

**Delete:** 🗑 → choose what happens to its websites: **move them** to another category (recommended), keep them **without a category**, or **delete them too**.

---

## 8.4 Websites (channels and services)

**Add a website**
1. **Websites → ＋ Add website** (or *Dashboard → Add website*).
2. **Title**: the name on the card, e.g. *BBC News*.
3. **Category**: where it appears.
4. **Website address (URL)**: the full address, copied from your browser's address bar, starting with `https://`. Example: `https://www.bbc.com/news`.
5. **Short description**: one or two sentences.
6. **Logo / icon**: click **Choose…** → upload or pick from the library. Best: square PNG/WebP, 256×256 or larger, transparent or white background.
7. **Background image** (optional): used on featured cards and in the *Image* card style.
8. **Animation (GIF / video)** (optional): an animated GIF or a short MP4/WebM (under 5 MB, a few seconds, loops silently) shown on featured cards.
9. **Accent colour**: the card's colour when there is no logo (the app shows the first letters of the name on that colour).
10. **Badge**: a short label like `LIVE`, `NEW` or `24/7`. `LIVE` gets a pulsing dot.
11. **Search keywords**: extra words users might search for, separated by commas (e.g. *cricket, scores, live*).
12. **How it opens**:
    * **App default**: uses the setting in *Browser* (§8.9).
    * **In-app browser tab** (recommended): fast, secure, users stay signed in to the site.
    * **Embedded browser**: the app's own browser screen. **Only for websites you own or have permission to show**; app stores can reject apps that embed other people's sites.
    * **External browser / app**: leaves the app; good for sites that only work in their own app.
13. **★ Featured**: show it prominently at the top of the home screen.
14. **Visible in the app**: switch off to hide it temporarily.
15. **Save website**. The preview on the right shows how the featured card will look.

**Find websites:** filter by category with the drop-down, or type in the search box (title, URL or keyword).

**Change the order inside a category:** choose that category in the filter, then drag **⠿**.

**Quick actions on each row:** ★ feature/unfeature · switch show/hide · **Edit** · 🗑 delete.

**Bulk actions:** tick several websites, then **Show**, **Hide**, **★ Feature**, **Unfeature**, **Move to…** another category, or **Delete**.

---

## 8.5 Featured & bookmarks

Featured websites appear at the top of the app as large cards (a sliding carousel or a grid, see §8.8).

* **Featured → ＋ Add to featured** → tick websites → **Add**.
* Drag **⠿** to set the order. The **first** one is shown first.
* **Remove** takes it out of Featured; the website itself stays.
* Featured cards look best with a **background image** or **animation**.

*(Users also have their own personal "Favourites" in the app; those are private to each phone and not managed here.)*

---

## 8.6 Media library

All uploaded pictures and videos in one place.

* **Upload:** drag files onto the dotted box or click it. You can upload several at once.
* Allowed: **PNG, JPG, WebP, GIF** (animated GIFs work) and **MP4, WebM** videos, up to 25 MB each (your server may use another limit).
* Click a file to see its size, **Copy link** or **Delete**.
* If a file is still used by a website or category, you are warned before deleting.

**Recommended sizes**

| Use | Size | Format |
|---|---|---|
| Website logo / category icon | 256×256 to 512×512, square | PNG or WebP (transparent OK) |
| App logo | 512×512, square | PNG |
| Featured / category background | 1200×600 | JPG or WebP |
| Home screen background | 1080×1920 (portrait) | JPG, WebP or GIF |
| Animation | ≤ 5 MB, ≤ 10 s | GIF, MP4 or WebM |

Keep files small: users on mobile data download them.

---

## 8.7 Branding

**Appearance → Branding**
* **App name**: shown at the top of the app's home screen and the About page.
* **Tagline**: the short line under the name.
* **App logo**: shown next to the name and on the About page.
* **Splash image** (optional).

The preview phone on the right updates as you type. Press **Save changes** (top right). "Unsaved changes" reminds you if you forget.

*Note:* the name under the app **icon** on the phone and the icon itself are part of the store build and change only with a new app version (see the Build guide).

## 8.8 Colours & style, and Home screen

**Appearance → Colours & style**
* **Quick presets**: Neon Night, Crimson News, Ocean, Clean Light. One click sets all colours; adjust afterwards if you like.
* **Appearance**: Dark, Light, or Follow phone.
* **Colours**: Primary (buttons, highlights), Secondary, Accent (badges), Text, Background, Surface (cards), Gradient start/end (logo tile, featured cards, selected tab).
* **Card style**: *Glass* (see-through, futuristic), *Solid*, or *Image* (website background images on the cards).
* **Corner roundness**: from square to very round.
* **Animations** on/off. Users who switched off animations on their phone never see them anyway.

**Appearance → Home screen**
* **Home background image** and its **visibility** (keep it low, 20–40%, so text stays readable).
* **Featured section** on/off, its **title**, and **Carousel** or **Grid** style.
* **Cards per row**: 2, 3 or 4 (tablets show more automatically).
* **Search bar**, **category tabs** and **descriptions on cards** on/off.
* **📣 Announcement banner**: a message at the top of the home screen, optionally with a link (e.g. "Election night live coverage from 8 pm").

## 8.9 Browser

How websites open when users tap them. **In-app browser tab** is recommended. See the explanation on that page. You can also allow or prevent **"Open in browser"** and **sharing links**, and show or hide the toolbar of the embedded browser.

## 8.10 Privacy & legal (required by the app stores)

Fill in **Publisher / company name**, **Support e-mail**, and either:
* leave **Privacy policy URL** empty to use the built-in page at `https://<your-domain>/privacy-policy` (generated from **Privacy policy text**, or a sensible default if empty), **or**
* paste the address of your own privacy policy.

**About text** appears on the app's About page. Use `# Title`, `## Heading` and blank lines between paragraphs in the privacy policy text. Open the link under the field to check the result.

---

## 8.11 Your account and other administrators

**My account:** change your password (at least 10 characters; a short sentence works well). **Sign out on all devices** is useful if you used a shared computer.

**Administrators** (owners only):
* **Add administrator**: e-mail, name, password, role:
  * **Owner**: everything, including managing administrators.
  * **Editor**: content, media and appearance, but not administrators.
* **Edit**: change the name or role, set a new password, or **deactivate** the account (they are signed out immediately).
* There is always at least one active owner.

---

## 8.12 Everyday recipes

| I want to… | Do this |
|---|---|
| Add a new live TV channel | Websites → Add → Category *Live Streaming*, Badge `LIVE`, ★ Featured if it is important |
| Temporarily hide a channel that is down | Websites → switch it off |
| Highlight a special event | Home screen → Announcement banner, and feature the channel |
| Rebrand the app | Branding (name, logo) + Colours & style (preset or colours) |
| Reorder tabs | Categories → drag ⠿ |
| Remove the demo content | Websites → select all → Delete; Categories → delete the demo categories |
| See what the app receives | Click **API feed ↗** in the top bar |

## 8.13 Good practice

* Only add websites you are allowed to feature, and respect their brands and logos.
* Prefer `https://` addresses.
* Check new channels on a phone after adding them.
* Keep descriptions short and factual.
* Hide rather than delete when unsure; hiding can be undone.
