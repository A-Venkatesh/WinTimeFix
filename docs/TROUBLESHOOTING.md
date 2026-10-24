# WinTimeFix - Technical Architecture & Troubleshooting Guide

This document explains the internal mechanisms of Windows Time Service (`W32Time`), why synchronization fails in modern Windows 10/11 environments, and how `WinTimeFix` resolves each failure mode.

---

## 1. Registry Architecture of W32Time

Windows Time service configuration is stored primarily under:
`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time`

### Key Configuration Branches:

### `...\W32Time\Config`
* **`MaxPosPhaseCorrection`** (DWORD): The maximum positive time difference (in seconds) that `W32Time` will accept from an NTP server.
  * *Default:* `54000` (15 hours).
  * *Fix:* `4294967295` (`0xFFFFFFFF`), allowing resync even if the clock is off by days or years.
* **`MaxNegPhaseCorrection`** (DWORD): The maximum negative time difference (in seconds) accepted.
  * *Default:* `54000` (15 hours).
  * *Fix:* `4294967295` (`0xFFFFFFFF`).
* **`UtilizeSslTimeData`** (DWORD): Secure Time Seeding (introduced in Windows 10).
  * *Default:* `1` (Enabled).
  * *Fix:* `0` (Disabled). When enabled, Windows attempts to seed the clock using timestamps from outbound TLS handshakes. Faulty web proxies, stale caches, or misconfigured servers can corrupt the clock and break NTP.

### `...\W32Time\Parameters`
* **`NtpServer`** (REG_SZ): Space-delimited list of NTP servers with mode flags.
* **`Type`** (REG_SZ): Set to `NTP` for stand-alone clients or `NT5DS` for Active Directory domain members.

### `...\W32Time\TimeProviders\NtpClient`
* **`SpecialPollInterval`** (DWORD): Interval (in seconds) between synchronization attempts when the `0x1` flag is used.
  * *Default:* `604800` (7 days).
  * Recommended: `3600` (1 hour) or `86400` (1 day).

---

## 2. NTP Peer Flags Explained

In the peer string:
`time.google.com,0x9 pool.ntp.org,0x9`

The `0x9` hexadecimal flag is a bitmask:
* `0x01` (`SpecialInterval`): Uses `SpecialPollInterval` instead of dynamic polling.
* `0x08` (`Client`): Sends requests in standard NTP **Client Mode** rather than symmetric active mode.
* Combined: `0x01 + 0x08 = 0x09`.

This ensures reliable communication across routers and NAT without asymmetric session states.

---

## 3. Common Error Codes

### `The service has not been started. (0x80070426)`
Occurs when invoking `w32tm /config` while `w32time` service is stopped.  
*Solution:* Apply settings directly to the registry before service startup, or ensure `net start w32time` completes before issuing `/config /update`.

### `The computer did not resync because no time data was available.`
Occurs when:
1. `MaxPosPhaseCorrection` or `MaxNegPhaseCorrection` rejected the time sample because the local clock was off by more than 15 hours.
2. UDP Port 123 is blocked on the network.
3. DNS resolution failed for the configured NTP servers.

### `The peer is unreachable.`
Indicates that packets sent to UDP 123 timed out without an NTP response. Commonly caused by corporate proxies, VPN kill-switches, or ISP-level UDP 123 filtering.

---

## 4. HTTPS Fallback Synchronization

When UDP 123 is permanently blocked by a network or ISP:
1. Standard NTP cannot establish a session.
2. `WinTimeFix` issues an HTTP `HEAD` request to major public HTTPS endpoints (`https://www.google.com`, `https://www.cloudflare.com`).
3. These servers return the accurate atomic time in the standard HTTP `Date` header (RFC 7231).
4. `WinTimeFix` parses the UTC string and sets the system clock using `Set-Date`.

