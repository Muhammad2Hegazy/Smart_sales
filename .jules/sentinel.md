## 2025-05-15 - [CRITICAL] Authentication Bypass in Forgot Password
**Vulnerability:** Unauthenticated password reset allowed any user to reset any other user's password (including admin) from the login screen.
**Learning:** A "Forgot Password" feature was implemented as a simple dialog that didn't verify the user's identity or authorization. In a local POS system, this provides a trivial way to gain admin access.
**Prevention:** Restrict password resets to Administrative users within the secure parts of the application. Avoid providing global password reset mechanisms on the login screen unless they are backed by strong secondary authentication (e.g., OTP, master code).
