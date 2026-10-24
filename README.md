<div align="center">

# ⏱️ WinTimeFix

**A robust, automated utility to fix broken Windows 10 & 11 time synchronization.**

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20Server-blue?logo=windows)](https://microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-5391FE?logo=powershell)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## ⚡ The Problem

Windows 11 frequently fails to synchronize the system clock with errors such as:
- *"Time synchronization failed. An error occurred while Windows was synchronizing with time.windows.com."*
- *"The computer did not resync because no time data was available."*
- *"The peer is unreachable."*

### Why does this happen?
1. **The 15-Hour Phase Limit:** Windows silently rejects NTP synchronization if your clock has drifted by more than 15 hours (54,000s) — typical after dead CMOS batteries, hardware maintenance, or dual-booting with Linux.
2. **Secure Time Seeding Bug:** Windows 10/11's `UtilizeSslTimeData` feature can guess the time from TLS handshake headers, causing the clock to unpredictably jump into the future/past and lock out NTP.
3. **Flaky Default Peer:** `time.windows.com` often suffers from timeouts and packet drops.
4. **Blocked UDP Port 123:** Many ISPs, university/hotel networks, and VPNs completely block outbound NTP (UDP 123).

---

## 🚀 Quick Start

### Method 1: One-Line Run (PowerShell Admin)

Open **PowerShell (Run as Administrator)** or Windows Terminal (Admin) and run:

```powershell
irm https://raw.githubusercontent.com/A-Venkatesh/WinTimeFix/main/src/WinTimeFix.ps1 | iex
```

---

### Method 2: Download & Run

1. [**Download the latest ZIP**](https://github.com/A-Venkatesh/WinTimeFix/archive/refs/heads/main.zip) and extract it.
2. Right-click `src\WinTimeFix.bat` and select **Run as administrator** (or double-click it and accept the UAC prompt).

---

## 🛠️ What WinTimeFix Does

1. **Service Reset:** Unregisters and re-registers `w32time` to clear corrupt states and caches.
2. **Phase Limit Removal:** Sets `MaxPosPhaseCorrection` and `MaxNegPhaseCorrection` to `0xFFFFFFFF` so any time offset is accepted.
3. **Disables SSL Seeding:** Turns off `UtilizeSslTimeData` to prevent random time jumps from HTTPS connections.
4. **Redundant NTP Pool:** Configures 4 redundant public NTP servers (`Google`, `Cloudflare`, `NTP Pool`, `Windows`) in active client mode (`0x9`).
5. **Firewall Rule:** Verifies outbound Windows Defender Firewall rules for UDP 123.
6. **HTTPS Fallback:** If your network/ISP blocks UDP port 123, it automatically queries atomic timestamp headers over HTTPS (Port 443) to accurately set the clock.

---

## ⚙️ Advanced Usage

```powershell
# Force synchronization via HTTPS only (bypasses NTP / UDP 123 completely)
.\src\WinTimeFix.ps1 -ForceHttps

# Use custom NTP servers
.\src\WinTimeFix.ps1 -NtpServers "time.nist.gov,0x9", "time.google.com,0x9"

# Silent execution in deployment scripts
.\src\WinTimeFix.ps1 -NonInteractive
```

---

## 🔍 Useful Diagnostic Commands

Run these in an elevated terminal to check the status of your Windows Time service:

```powershell
# View sync status and active peer
w32tm /query /status

# List configured NTP servers and their round-trip delay
w32tm /query /peers

# Force an immediate manual resync
w32tm /resync /force
```

For an in-depth explanation of Windows Time registry parameters and error codes, see [**docs/TROUBLESHOOTING.md**](docs/TROUBLESHOOTING.md).

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!  
Feel free to check out the [Issues page](https://github.com/A-Venkatesh/WinTimeFix/issues) or read [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).

