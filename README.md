# 🛡️ NextDNS Management & Chrome Extension Blocker

A collection of scripts to manage NextDNS installation and control Chrome extension permissions across different platforms.

---

## 📦 NextDNS Installation

### Windows

**Prerequisites:** PowerShell with Administrator privileges

#### Installation Steps

1. **Open PowerShell as Administrator**
   - Press `Win` key
   - Type `PowerShell`
   - Right-click on **Windows PowerShell**
   - Select **Run as administrator**

2. **Run Installation Command**
```powershell
   irm https://raw.githubusercontent.com/Mudales/nextdns/main/get.ps1 | iex
```

> ℹ️ The script will automatically elevate privileges if needed.

---

## 🗑️ NextDNS Uninstallation

### Windows

1. **Open PowerShell as Administrator**
   - Press `Win` key
   - Type `PowerShell`
   - Right-click on **Windows PowerShell**
   - Select **Run as administrator**

2. **Run Uninstaller Command**
```powershell
   irm https://raw.githubusercontent.com/Mudales/nextdns/main/uninstaller.ps1 | iex
```

---

## 🚫 Chrome Extension Blocker

Block all Chrome extensions except for a predefined whitelist. Perfect for managed environments or parental controls.

### 🍎 macOS

**Prerequisites:** Terminal with `sudo` access
```bash
curl -fsSL https://raw.githubusercontent.com/Mudales/nextdns/main/EXTblock.sh | sudo bash
```

**What it does:**
- Blocks all Chrome extension installations
- Allows only whitelisted extensions:
  - Adobe Acrobat (PDF viewer)
  - Google Translate
  - Google Docs Offline
  - Google Drive

**Verify:** Open Chrome and navigate to `chrome://policy`

---

### 🪟 Windows

**Prerequisites:** PowerShell (Administrator privileges will be requested automatically)
```powershell
irm https://raw.githubusercontent.com/Mudales/nextdns/main/EXTblock.ps1 | iex
```

**What it does:**
- Configures Windows Registry to block all extensions
- Maintains whitelist for approved extensions
- Auto-elevates to Administrator if needed

**Verify:** Open Chrome and navigate to `chrome://policy`

---



**Supported Browsers:**
- Google Chrome
- Chromium

**Verify:** Open Chrome/Chromium and navigate to `chrome://policy`

---

## 📋 Whitelisted Extensions

By default, the following extensions are allowed:

| Extension | ID | Purpose |
|-----------|----|---------| 
| Adobe Acrobat | `efaidnbmnnnibpcajpcglclefindmkaj` | PDF viewing |
| Google Translate | `aapbdbdomjkkjkaonfhkkikfgjllcleb` | Translation |
| Google Docs Offline | `kbfnbcaeplbcioakkpcpgfkobkghlhen` | Offline docs |
| Google Drive | `ddkjiahejlhfcafbddmgiahcphecmpfh` | Cloud storage |

### 🔧 Customizing the Whitelist

To add or remove extensions, edit the respective script and modify the extension ID list before running.

---

## ⚠️ Important Notes

- **Restart Chrome/Chromium** after running the extension blocker scripts
- Scripts only affect Chrome/Chromium extension policies
- Other browser settings remain unchanged
- On macOS/Linux, you may need to enter your password for `sudo` access
- On Windows, a UAC prompt may appear for administrator access

---

## 🐛 Troubleshooting

### Extensions still installing?

1. Verify the policy was applied: `chrome://policy`
2. Completely quit and restart Chrome (not just close the window)
3. Check if Chrome is managed by another policy system

### Script fails to run?

**Windows:**
- Ensure PowerShell execution policy allows scripts
- Try: `Set-ExecutionPolicy Bypass -Scope Process -Force`

**macOS/Linux:**
- Ensure you have `sudo` privileges
- Check internet connectivity
- Verify `curl` is installed

---

## 📄 License

This project is open source and available for personal use.

---

## 🤝 Contributing

Issues and pull requests are welcome! Feel free to contribute improvements or report bugs.

---

## 📞 Support

For issues or questions, please open an issue on GitHub.
