# Contributing to WinTimeFix

Thank you for your interest in improving **WinTimeFix**! Contributions from the community help make this tool better for everyone encountering Windows clock and time sync issues.

---

## 📌 Ways to Contribute

- **Report Bugs:** Open an issue if you encounter an error code, permission problem, or unsupported Windows version.
- **Suggest Features:** Propose ideas such as GUI interfaces, additional NTP server options, or scheduled task integrations.
- **Submit Pull Requests:** Bug fixes, script improvements, and documentation enhancements are welcome.

---

## 🧪 Testing Guidelines

Before submitting a Pull Request:
1. Test your modifications on clean installs of **Windows 10** and **Windows 11**.
2. Verify that non-elevated executions properly invoke the UAC prompt.
3. Test edge cases such as:
   - Manually setting the clock back 2 years to ensure `MaxPosPhaseCorrection` works.
   - Disconnecting network to verify error handling.
   - Running in environments where UDP 123 is blocked to verify HTTPS fallback.

---

## 📋 Code Style

- Keep PowerShell code compatible with Windows PowerShell 5.1 and PowerShell 7+.
- Write clear comments for any Windows Registry keys or Win32 API calls.
- Use explicit error handling (`try/catch` and `-ErrorAction`).

