# TezShare ⚡

Fast, local file sharing app — phone to phone, phone to laptop, without internet.

## Kaise kaam karta hai
- Har device WiFi/Hotspot pe apne aap ek dusre ko "dhoondh" leta hai (auto-discovery).
- Agar auto-discovery na chale, "IP se jodo" button se manually IP daal ke connect kar sakte ho.
- File bhejne ke liye seedha local network use hota hai — koi internet, koi cloud nahi.
- File ka naam bilkul same rehta hai, koi renaming nahi hoti.

## Is folder ko GitHub pe kaise daalna hai aur build kaise banani hai
Poori Hinglish guide iske sath ke chat mein di gayi hai. Short version:
1. Is poore folder ka content apni GitHub repo `tezshare` mein daalo (GitHub Desktop se, sabse aasan).
2. Codemagic.io pe jao, apni repo select karo — `codemagic.yaml` already isme hai, wahi build ka process bata dega.
3. "Android APK" workflow start karo → APK milega.
4. "Windows EXE" workflow start karo → Windows app milega.

## Project structure
- `lib/main.dart` — app ka entry point
- `lib/screens/` — home screen aur received files screen
- `lib/services/` — device discovery + file transfer logic
- `lib/widgets/` — reusable UI pieces
- `lib/theme/` — colors aur app ka look
- `codemagic.yaml` — cloud build instructions (Android + Windows dono)
