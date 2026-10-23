# Lovely Chat — Flutter starter

This is a **UI/demo starter**, not a working live-streaming or financial service. It includes screens for voice-room pricing, videos, chat, wallet exchange preview, and role panels. No real users, media, streaming, transfers, payments or withdrawals are enabled.

## Android APK via GitHub (no local Flutter install)
1. Create a new **private** GitHub repository named `lovely-chat`.
2. Upload the **contents** of this folder (including `.github/workflows/android.yml`) to the repository root, and commit to `main`.
3. Open **Actions → Build Android APK → Run workflow**.
4. When the job finishes, open the run → **Artifacts → lovely-chat-android-apk**. Extract the ZIP and install the APK on Android.

GitHub Actions runs `flutter create` to generate Android/iOS platform files, then builds the APK. If GitHub asks you to enable Actions, approve it in repository settings.

## iPhone
Run **Actions → Validate iOS build (unsigned)** to compile-check on a macOS runner. This does **not** produce an installable iPhone app. iOS distribution needs Apple Developer enrollment, provisioning/signing, and typically TestFlight/App Store distribution.

## Next production steps
- Backend authentication with server-enforced roles (Owner, Admin, Super Admin, BD, Agency, Host, Manager, Seller, User).
- Real-time voice/video infrastructure, short-video storage/CDN, moderation and reporting.
- Ledger-based wallet and transactional transfers with anti-fraud controls, seller verification and applicable payout compliance.
- Commission/target rules reviewed and approved before financial implementation.
- No secrets in GitHub repo; production builds use secure secrets and API endpoints.
