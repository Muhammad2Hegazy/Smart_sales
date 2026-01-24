## 2025-05-14 - [CRITICAL] Remove hardcoded MAC address backdoor
**Vulnerability:** A hardcoded developer MAC address ('E0:0A:F6:C3:BA:FF') was used to bypass device authorization checks in the authentication and device management layers.
**Learning:** Hardcoded bypasses ("backdoors") are often added for developer convenience but represent a critical security risk if discovered. Bootstrapping a system should use a "First-Device Registration" or "Trust On First Use" (TOFU) policy instead.
**Prevention:** Never use hardcoded identifiers or secrets for authorization. Implement a secure initial setup process that allows the first authorized administrator to register the primary device when the system is in an uninitialized state.
