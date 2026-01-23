# Sentinel Journal - Security Learnings

## 2025-05-15 - Hardcoded Backdoor Removal and Secure Initialization
**Vulnerability:** A hardcoded developer MAC address ('E0:0A:F6:C3:BA:FF') was used as a backdoor to bypass device registration and authentication checks.
**Learning:** Hardcoded secrets are often used during development to simplify setup, but they create significant security risks if they remain in production. The system needed a way to authorize the very first device in a clean installation.
**Prevention:** Replaced the backdoor with a "first-device" registration policy. The system now allows the first login attempt ONLY if no devices are registered in the system AND the user has the 'admin' role. This allows legitimate initial setup while maintaining security.
