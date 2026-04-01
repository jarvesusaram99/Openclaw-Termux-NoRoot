# 🤖 OpenClaw Termux No Root

**Control any Android phone via Telegram using Gemini AI — no root required.**

Powered by [OpenClaw](https://github.com/AidanPark/openclaw-android) + Shizuku + Termux

---

### 📺 Watch the Full Setup Tutorial

<a href="https://youtu.be/QePlp8CJ-qA" target="_blank">
  <img src="https://markdown-videos-api.jorgenkh.no/youtube/QePlp8CJ-qA" alt="Watch the OpenClaw Setup Tutorial on YouTube" width="100%" />
</a>

---

## ✨ Features

- 💬 **Telegram Bot** — Send commands from anywhere
- 🧠 **Gemini AI** — Understands natural language
- 📱 **30+ Commands** — WiFi, Bluetooth, calls, SMS, screenshots, volume & more
- 🔒 **No Root** — Uses Shizuku for ADB-level access
- ⚡ **1-Click Install** — Single script sets up everything

---

## 📋 Prerequisites

| Requirement | Details |
|---|---|
| **Android Phone** | Android 11+ |
| **Shizuku** | [F-Droid](https://f-droid.org/packages/moe.shizuku.privileged.api/) or [Play Store](https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api) |
| **Termux** | [F-Droid](https://f-droid.org/en/packages/com.termux/) ⚠️ *Don't use the Play Store version* |
| **Telegram Bot Token** | Get from [@BotFather](https://t.me/BotFather) |
| **Gemini API Key** | Free from [Google AI Studio](https://aistudio.google.com/apikey) |

---

## 🏁 Setup

### Step 1 — Prepare Your Phone

1. Go to `Settings → About Phone` → tap **"Build Number"** 7 times to enable Developer Options.
2. Go to `Settings → Developer Options` → turn on **Wireless Debugging**.
3. Install **Termux** from [F-Droid](https://f-droid.org/en/packages/com.termux/).
4. Install **Shizuku** from [F-Droid](https://f-droid.org/packages/moe.shizuku.privileged.api/) or Play Store.

### Step 2 — Start Shizuku & Export Files

1. Open **Shizuku** → tap **"Pairing"** under Wireless Debugging.
2. In Wireless Debugging settings, tap **"Pair device with pairing code"** and enter the code.
3. Tap **"Start"** until it says **"Shizuku is running"**.
4. Tap **"Use Shizuku in terminal apps"** → **"Export files"**.
5. Create a folder named **`Shizuku`** in your internal storage and save files there.

> **⚠️ Important:** The folder must be named exactly `Shizuku` (capital S) in your main storage.

### Step 3 — Run the Installer

Open **Termux** and paste:

```bash
curl -sL https://raw.githubusercontent.com/jarvesusaram99/Openclaw-Termux-NoRoot/main/auto_setup.sh | bash
```

### Step 4 — Add Your Credentials

```bash
openclaw onboard
openclaw auth add google --key "YOUR_GEMINI_KEY_HERE"
```

### Step 5 — Launch! 🎉

```bash
openclaw gateway
```

Now open **Telegram**, find your bot, and try:
- `"What's my battery?"`
- `"Open Chrome"`
- `"Search YouTube for lofi beats"`
- `"Turn off WiFi"`

---

## 📱 Commands

| Command | What it does |
|---|---|
| `battery` | Check battery level |
| `wifi on/off` | Toggle WiFi |
| `bluetooth on/off` | Toggle Bluetooth |
| `brightness 0-255` | Set brightness |
| `volume-up / volume-down` | Adjust volume |
| `mute` | Toggle mute |
| `lock` | Lock screen |
| `screenshot` | Take a screenshot |
| `open-app <package>` | Launch any app |
| `kill-app <package>` | Force-stop an app |
| `list-apps` | List installed apps |
| `open-url <url>` | Open URL in browser |
| `youtube-search <query>` | Search YouTube |
| `call <number>` | Make a call |
| `send-sms <number> <msg>` | Compose SMS |
| `whatsapp-send <number> <msg>` | Send WhatsApp message |
| `info` | Device model & Android version |

---

## 🔧 Troubleshooting

| Problem | Solution |
|---|---|
| `rish: command not found` | Re-run `bash ~/storage/shared/Shizuku/copy.sh` |
| Shizuku not responding | Open Shizuku app → ensure it says "Running" → run `shizuku` in Termux |
| Network errors | Run `export NODE_OPTIONS=--dns-result-order=ipv4first` |
| `rish_shizuku.dex` not found | In Shizuku → "Use in terminal apps" → "Export files" → save to `Shizuku` folder |

---

## 🙏 Credits

- **[OpenClaw Android](https://github.com/AidanPark/openclaw-android)** by [AidanPark](https://github.com/AidanPark) — The AI gateway that powers this project.
- **[Shizuku](https://github.com/RikkaApps/Shizuku)** — ADB-level access without root.
- **[Termux](https://github.com/termux/termux-app)** — Linux terminal for Android.
- **[Google Gemini](https://ai.google.dev/)** — AI brain for natural language understanding.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
