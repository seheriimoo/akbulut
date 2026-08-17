# NOCTA V1 MASTER AUDIT

Read-only audit of `/Users/seher/slowave_run/slowave` · 17 Aug 2026 · scored on working product integrity, not file count. No code was changed.

Skor kartı ve blocker’lar ayrıca sohbet yanında açılabilen canvas’ta: [Nocta V1 master audit](/Users/seher/.cursor/projects/Users-seher-slowave-run-slowave/canvases/nocta-v1-master-audit.canvas.tsx)

---

## 1. Executive Summary

Nocta V1’in **gece döngüsü gerçek ve bağlı**: Welcome → Consent → HCOS sohbet → paywall kapısı → Player → Night Complete. Konuşma motoru projedeki en olgun parça ve V1 için dondurulmuş.

Bu, mağazaya çıkacak **satılabilir bir ürün değil**. Abonelik kodu var, canlı satın alma yok. Crash raporu kodu var, Sentry DSN yok. iOS bundle id doğru; TestFlight IPA yok. Android hâlâ `com.example.slowave` ve yalnızca Apple `appl_` anahtarı kabul ediyor.

Dokümandaki “ship checklist” kodun önünde: legal URL’ler ve 3.1.2 metni kodda var; RevenueCat + TestFlight hâlâ owner işi.

---

## 2. Overall Completion

**NOCTA V1 TOTAL COMPLETION: 54%**

Bu oran dosya sayısına göre değil. Ölçü: kullanıcıya ulaşan, bağlı, hata yolu olan, test edilmiş davranış. Simulator’da OpenAI key ile gece bitirmek ~68%. App Store’a ücretli çıkmak ~38%. Play Store ~12%. Ağırlıklı V1 (iOS + Play vaadi): **54%**.

---

## 3. Component Scorecard

Canvas’taki tablo kaynak. Özet:

| Component | Completion | Status | Main Gap |
|---|---|---|---|
| Conversation / HCOS | 84 | Strong | Frozen; live OpenAI testleri dart-define ister |
| Insight / routing | 80 | Wired | Compiler + Guard canlı yolda |
| State detection | 78 | Wired | Eski `AIService` detector’ları kullanılmıyor |
| Sleep transition | 76 | Wired | 1.6s gecikme; paywall ses sınırında |
| Privacy / legal | 74 | Mostly | Sayfalar canlı; ASC nutrition UNKNOWN |
| AI integration | 72 | Wired | IPA’ya `OPENAI_API_KEY` basılmalı |
| Onboarding | 72 | Minimal | Welcome + consent; eski TR onboarding ölü |
| Safety / consent | 70 | Partial | Disclaimer var; kriz router yok (V1 için kabul) |
| Performance | 70 | OK | Kullanılmayan büyük audio master’lar |
| Error handling | 68 | Partial | Fail-closed chat; sessiz hatalar |
| Audio / player | 68 | Partial | TTS ölü; GlobalSleep vs 45dk timer |
| Persistence | 65 | Partial | Beliefs/needs/triggers kaydedilmiyor |
| Testing | 64 | Unit-strong | 471 geçti / 5 key fail; CI yok; cihaz IT yok |
| Memory | 62 | Partial | Store, MemoryEngine’den ince |
| Core night loop | 58 | Path exists | Satış yok; paywall bitmemiş |
| UI / UX | 52 | Partial | Ürün chrome EN; paywall ship-ready değil |
| Personalization | 48 | Thin | `LearningEngine` kullanılmıyor |
| Language TR–EN | 45 | Partial | Biliş TR/EN; ürün UI İngilizce |
| Subscription / paywall | 42 | Blocked | Kod hazır; RC key + canlı purchase yok |
| Production config | 40 | Partial | RC + Sentry placeholder |
| iOS release | 38 | Blocked | TestFlight yok; IAP review-ready değil |
| Android release | 12 | Not started | `com.example.slowave`; `appl_` only |
| Analytics | 8 | Missing | Sentry kodu DSN’siz; ürün analitiği yok |

---

## 4. What Is Actually Complete

- **Canlı rota** `lib/main.dart` `AppRouter`: `/` Welcome, `/consent`, `/ai-chat`, `/privacy`, `/terms`. Begin, consent yoksa gate’e gider (`ConsentStore.hasAcceptedBaseline`).
- **HCOS production entry** `HcosLiveEntry.createOrchestrator()` → `CognitiveOrchestrator.processTurn`. Chat bunu kullanıyor (`lib/screens/ai_chat_screen.dart`).
- **OpenAI transport** `OpenAIVendorProvider` + `LanguageModelClient` (10s timeout, bir transient retry). Empty/malformed JSON `VendorError`.
- **UtteranceGuard + ConversationCompiler** HOW düzleminde bağlı; quality fixture’ları S01–S20 structural PASS.
- **Consent + legal**: `ConsentGateScreen`, `ComplianceTexts`, hosted URL’ler `https://seheriimoo.github.io/akbulut/privacy/` ve `/terms/`.
- **Paywall kod sözleşmesi**: `BillingCatalog` (`nocta_premium`, `default`, `nocta_premium_monthly`, `nocta_premium_yearly`), 3.1.2 footer, Privacy/Terms linkleri, restore, retry.
- **Player load-fail UI** + chat stay/retry (`playerOk == false` / `null` early leave).
- **Free 30m / premium 45m** `PremiumProductAccess` ile player timer + asset.
- **iOS kimlik**: display name Nocta, bundle `com.seher.slowave`, `UIBackgroundModes audio`, `PrivacyInfo.xcprivacy`, `ITSAppUsesNonExemptEncryption=false`.
- **Crash scrubbing** yazılmış (`CrashReporting.sanitizeForReporting`).

---

## 5. Partially Complete Systems

- **Paywall**: Ekran var; `AppConfig.hasRevenueCatApiKey` false iken “Purchases are not configured for this build.” Kullanıcı bunu ASC screenshot’ında gördü.
- **Memory**: `MemoryEngine` model’i günceller; `LivingMindStore.saveAfterNight` yalnızca `totalSessions`, `last_blocker`, mental/emotional patterns yazar. Beliefs/needs/triggers/preferences disk’e gitmiyor.
- **Audio**: Bed çalıyor (`audioplayers` + `SleepAudioSession`). `FlutterTts` oluşturuluyor, `speak` yok, sadece `stop`. `just_audio` yalnızca ölü engine’lerde.
- **Language**: Chat chrome TR/EN (`SessionUiLanguageResolver`). Welcome, consent, paywall, night complete, player İngilizce.
- **Sleep beds**: loneliness/relationship → `CoreDefaultAir_BG_GlobalSleep.m4a` (kısa). Premium’da aynı dosya, timer 45dk. UNKNOWN: döngü mü, sessizlik mi.
- **Sentry**: Bootstrap var; DSN boşsa upload yok.
- **IAP mağaza**: Yıllık ürün + 640×920 screenshot duruyor. Aylık screenshot/fiyat ASC’de yarım. **Add for Review basılmadı** (doğru).

---

## 6. Missing Systems

- Canlı RevenueCat `appl_` + offering attach (dashboard).
- Production Sentry DSN.
- TestFlight / imzalı IPA tarifi (repo’da CI yok; `.github` yalnızca legal site).
- App Store vitrin screenshot’ları (IAP review screenshot vitrin değil).
- Ürün analitiği (Firebase/Amplitude yok — V1 için şart değil).
- Hesap / account deletion (hesap yok; 5.1.1(v) muhtemelen N/A).
- Android Play Billing / `goog_` key. `AppConfig.isUsableRevenueCatAppleSdkKey` non-`appl_` reddeder.
- Kriz/safety router (bilinçli V1 dışı; disclaimer var).
- Sleep Mirror: kodda yok.

---

## 7. Broken / Risky Systems

- **`flutter analyze` 414 issue.** Çoğu `NOCTA_HISTORY/` ve terk edilmiş ekranlar. Canlı yolda compile error: `lib/screens/choice_screen.dart` (`AppRoutes.sleepAnalysis` / `directSleep` yok), `lib/screens/sleep_result_screen.dart` (`AppRoutes.premium` yok). Bunlar router’da değil; import edilirse build kırılır.
- **Legacy `lib/engines/conversation_engine.dart`**: `UnimplementedError` on reframe/release/understand/transition. Canlı path `lib/core/brain/conversation_engine.dart` kullanıyor. İsim çakışması kafa karıştırır.
- **Chat turn catch**: LLM fail → `_expressionQuiet`, kullanıcıya zayıf sinyal. Key yoksa gece “cevap yok” gibi durur.
- **Release binary secrets**: Key dart-define ile IPA’ya gömülmezse production chat ölür. `AppConfig.load()` yalnızca compile-time define okur.
- **IAP capability**: `Runner.entitlements` boş; pbxproj’de StoreKit/IAP satırı yok. Plugin ekliyor olabilir. **UNKNOWN / NEEDS VERIFICATION** (Xcode Signing & Capabilities).
- **Android INTERNET**: main manifest’te yok, debug/profile’da var. Plugin merge muhtemel. **UNKNOWN** release APK için.
- **Paywall screenshot içeriği**: “Purchases are not configured” Apple reviewer’a gider. IAP metadata için yeter; app review screenshot’ı olarak zayıf.

---

## 8. Dead / Unused / Duplicate Code

Canlı router’a bağlı olmayanlar (kanıt: `AppRouter` + import taraması):

- `lib/screens/welcome_screen.dart`, `choice_screen.dart`, `preparing_screen.dart`, `sleep_plan_screen.dart`, `sleep_analysis_screen.dart`, `sleep_result_screen.dart`, `sleep_loading_screen.dart`, `sleep_screen.dart`, `lib/screens/player_screen.dart` (stub Player), `lib/continue_screen.dart`
- `lib/features/welcome/welcome_screen.dart`, `lib/features/onboarding/onboarding_screen.dart` (TR “Uyku Ayarı”), `lib/features/intake/intake_flow.dart` (TODO: paywall)
- `lib/services/ai_service.dart` (`@Deprecated`, Sprint 6 cutover)
- `lib/engines/observe_engine.dart`, `session_engine.dart`, `audio_engine.dart`, `lib/core/audio_engine/audio_engine.dart`, `lib/core/cognitive/message_understanding_engine.dart`, `lib/core/brain/learning_engine.dart`
- Düzinelerce `*.bak`, `*.backup`, `main.dart.step0*_backup`, `NOCTA_HISTORY/`
- `assets/audio/voice/session_01.mp3` pubspec’te; canlı player kullanmıyor
- Disk’te 60m / clean / master m4a’lar pubspec’te değil

`SleepWaveApp` class adı ve RC grup adı “SleepWave Pro” hâlâ duruyor. Display name Nocta.

---

## 9. Test Status

Çalıştırıldı (2026-08-17, bu makine):

```
flutter test  →  +471  -5
flutter analyze → 414 issues (exit 1)
integration_test/ → bu koşuda çalıştırılmadı
```

**5 fail, hepsi live OpenAI capture** (secrets inject edilmeden):

- `test/integration/openai_live_conversation_test.dart`
- `test/integration/night_to_audio_openai_capture_test.dart`
- `test/integration/full_night_openai_capture_test.dart`
- `test/integration/gold_depth_v1_openai_capture_test.dart`
- `test/integration/multi_scenario_openai_capture_test.dart`

Bunlar skip değil; key yoksa fail. Varsayılan `flutter test` ile kırmızı durmaları CI’yı kırar.

**Skipped:** 0  
**Flaky adayları:** OpenAI capture (ağ/model). Quality climb testleri LLM’siz structural; “ürün kalitesi” değil.

**Testi zayıf / yok kritikler:** gerçek purchase/restore, lock-screen audio, IPA dart-define, Android release, paywall widget, dead-route isolation, account-free privacy nutrition.

`test/widget_test.dart` boş `void main() {}`.

“Test geçiyor” ≠ “ürün hazır.” 471 test çoğunlukla HCOS sözleşmesi. Billing contract testleri fake port kullanıyor.

---

## 10. P0 Release Blockers

1. **OPENAI_API_KEY release IPA’da** — `AppConfig` / `--dart-define-from-file`. Yoksa chat ölür.
2. **RevenueCat `appl_` + dashboard** — entitlement `nocta_premium`, offering `default`, ürünler `nocta_premium_monthly` + `nocta_premium_yearly` ( `_v1` ve `sleepwave.pro.monthly` değil).
3. **ASC aylık IAP metadata** — $9.99, localization, `nocta_review_640x920.jpg`. **Add for Review yok** (ilk abonelik app version ile gider).
4. **Sandbox purchase + restore** gerçek cihazda.
5. **İmzalı IPA → TestFlight** + **Sentry DSN** (TestFlight crash’leri görünmez).

---

## 11. P1 V1 Must-Haves

- Paywall/UI’yı göndereceğin hale getir (TR istersen chrome; şimdi EN). Review bu binary’yi görür.
- Restore ikinci Apple ID / cihaz.
- Lock screen / background audio cihaz doğrulaması (`UIBackgroundModes audio` sadece plist kanıtı).
- App Store vitrin screenshot + açıklama (IAP review screenshot değil).
- ASC privacy nutrition labels ↔ `PrivacyInfo.xcprivacy`.
- Premium GlobalSleep süre/asset uyumu.
- Analyzer’ı kıran ölü ekranları canlı import’tan izole et / taşı (refactor cehennemi değil; landmine temizliği).
- Xcode **In-App Purchase** capability doğrula.

---

## 12. P2 Should-Haves

- 1.6s chat→player delay (`ai_chat_screen.dart`).
- Portrait lock (`Info.plist` hâlâ landscape açık).
- Dead code / `NOCTA_HISTORY` quarantine (analyze gürültüsü).
- `flutter_tts` + `just_audio` temizliği.
- `session_01.mp3` ve kullanılmayan 60m master’ları ship asset’ten çıkar (IPA şişmesi).
- README / pubspec “A new Flutter project.”
- Support e-posta deliverability.
- `SleepWaveApp` adı.
- Version bump disiplini (`1.0.0+1`).

---

## 13. P3 Post-V1

- Tüm Android / Play track (`applicationId`, signing, `goog_` key, INTERNET, Play IAP).
- Ürün analitiği.
- Hesaplar, Sleep Mirror, HCOS redesign, custom domain.
- Eski TR onboarding / intake / Somnia.
- `LearningEngine` geniş memory.
- Kriz detection (ayrı ürün kararı).

---

## 14. iOS Release Readiness

**38%**

| Item | Evidence | State |
|---|---|---|
| Bundle ID | `com.seher.slowave` | OK |
| Display name | Info.plist `Nocta` | OK |
| Version | `1.0.0+1` | İlk upload OK; her upload bump |
| Background audio | Info.plist | Declared; device UNKNOWN |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` | Present |
| Legal URLs | GitHub Pages | Live |
| IAP products | ASC yearly done; monthly incomplete | Partial |
| IAP capability | empty entitlements | UNKNOWN |
| Signing / IPA | repo’da ExportOptions/CI yok | Missing |
| RC + Sentry | placeholders | Missing |
| TestFlight | yok | Missing |

Mağaza tarafı (repo dışı): Paid Apps Agreement, banking/tax, sandbox Apple ID, ASC listing, review notes — **UNKNOWN / owner**.

---

## 15. Android Release Readiness

**12%**

- `applicationId = "com.example.slowave"` (`android/app/build.gradle.kts` TODO)
- Release signing = debug
- Label “Nocta”; INTERNET yalnızca debug/profile
- Billing config Apple-only (`appl_`)
- Play Console, Data safety, Play IAP — yok

V1’i iOS-first saymak adil. Play’i aynı anda vaat etmek bu skoru 54’e çekiyor.

---

## 16. Technical Debt That Actually Matters Before V1

Öncelik sırası (refactor değil, risk):

1. Ölü `lib/screens/*` compile error’ları — yanlış import = kırmızı build.
2. Çift `ConversationEngine` / çift `PlayerScreen` / çift `WelcomeScreen`.
3. `NOCTA_HISTORY` analyze’ı kirletiyor; `flutter analyze` CI’da kullanılamaz.
4. MemoryEngine vs LivingMindStore kayıp alanlar — “hafıza var” yanılsaması.
5. Üç audio stack (`audioplayers`, `just_audio`, `flutter_tts`) — TTS init yan etki riski.
6. Secrets: dart-define doğru model; unutmak P0. `secrets.local.json` commit etme (örnek dosya placeholder).

HCOS’a dokunma. Conversation frozen.

---

## 17. Exact Remaining Work

| Task | Pri | Files | Dependency | Acceptance | Size |
|---|---|---|---|---|---|
| Paywall + live chrome’u göndereceğin hale getir | P1 | `paywall_screen.dart`, `main.dart` Welcome, `night_complete_screen.dart`, `player_screen.dart` | HCOS’a dokunma | EN (ve istenirse TR) copy; 3.1.2 duruyor; screenshot’ta “not configured” yok | M |
| OPENAI key release recipe | P0 | `app_config.dart`, `config/README.md` | secrets.local.json | `flutter build ipa --dart-define-from-file=...` ile chat çalışır; key loglanmaz | S |
| RC dashboard + `appl_` | P0 | `config/secrets.local.json` (commit etme), `billing_catalog.dart` | ASC ürün ID’leri | Paywall gerçek fiyat gösterir; purchase entitlement açar | M |
| ASC monthly IAP bitir | P0 | mağaza | 640×920 jpg hazır | `nocta_premium_monthly` metadata tam; Add for Review yok | S |
| Sandbox buy + restore | P0 | `billing_service.dart` | RC + sandbox ID | Satın al → 45m; restore ikinci cihaz | M |
| Sentry DSN | P0 | `crash_reporting.dart`, secrets | Sentry project | TestFlight’tan test event | XS |
| First IPA / TestFlight | P0 | `ios/`, signing | 1–6 | Internal tester yükler | L |
| Device E2E smoke | P0 | canlı path | TestFlight | Consent→chat→paywall/restore→player lock screen→night complete | M |
| GlobalSleep vs timer | P1 | `sleep_bed_catalog.dart`, player | — | Premium süre asset ile uyumlu veya loop belgelenmiş | S |
| IAP capability verify | P0 | Xcode | — | Capability açık | XS |
| App Store listing assets | P1 | ASC | Paywall freeze | 6.7" screenshot’lar gerçek UI | M |
| Privacy nutrition | P1 | ASC + PrivacyInfo | — | Chat, purchase, crash eşleşir | S |
| Dead-screen landmine | P1 | `choice_screen.dart`, `sleep_result_screen.dart`, backups | — | `flutter analyze lib/` canlı path temiz | M |
| Android Play | P3 | `build.gradle.kts`, AppConfig | iOS ship | Ayrı track | XL |

---

## 18. Execution Order

**TASK 01** — Live-path UI’yı freeze et (paywall dahil). Mağaza ekran görüntüleri bundan sonra.  
**TASK 02** — Ölü ekran landmine’larını izole et (analyze/build güvenliği). TASK 01’den bağımsız, paralel olabilir.  
**TASK 03** — ASC monthly IAP metadata. Add for Review yok.  
**TASK 04** — RevenueCat attach + `appl_` (TASK 03 ürün ID’leri kesin olmadan bağlama).  
**TASK 05** — OPENAI + Sentry dart-define release recipe.  
**TASK 06** — Sandbox purchase/restore. TASK 04 olmadan olmaz.  
**TASK 07** — IPA + TestFlight. 05–06 olmadan reviewable değil.  
**TASK 08** — Cihaz E2E + lock screen.  
**TASK 09** — Listing screenshot + nutrition labels. UI freeze (01) sonrası.  
**TASK 10** — App version ile IAP’yi birlikte submit. İlk abonelik kuralı.

HCOS / quality climb / Sleep Mirror: bu sıraya girmez.

---

## 19. Suggested Work Sessions

**DAY 1** (~3s)  
Paywall + Welcome/Night Complete copy/layout. HCOS yok. Simulator’da gece yolu (mevcut OpenAI key).

**DAY 2**  
Ölü ekran izolasyonu. Aylık IAP screenshot + $9.99. RC ürün attach listesi hazırla (dashboard sen).

**DAY 3**  
`appl_` + Sentry DSN secrets.local. Sandbox purchase denemesi. Capability check.

**DAY 4**  
`flutter build ipa --dart-define-from-file`. TestFlight internal. Sentry test event.

**DAY 5**  
Cihaz E2E: consent, TR/EN chat, paywall, restore, lock screen audio, night complete. GlobalSleep süre bug’ı.

**DAY 6**  
App Store listing screenshot’ları (paywall bitmiş hali). Privacy nutrition. Submit checklist. Add for Review yalnızca app version ile.

**DAY 7+ buffer**  
Review cevapları, build number bump, destek e-posta. Android yok.

---

## 20. Final Verdict

1. **Gerçek tamamlanma: 54%.** Gece motoru güçlü; mağaza ürünü değil.
2. **En kritik 5:** (1) IPA’da OpenAI key, (2) RevenueCat `appl_` + ürün bağlama, (3) sandbox purchase/restore, (4) TestFlight IPA, (5) Sentry DSN. Aylık IAP metadata bunlara paralel P0.
3. **İyi görünen ama yarım:** PaywallScreen, CrashReporting, MemoryEngine/LivingMindStore, LearningEngine, OnboardingScreen, Premium GlobalSleep, StoreKit dosyası (lokal; production store değil).
4. **V1’de bırak:** HCOS redesign, Sleep Mirror, Android Play, analytics suite, hesaplar, custom domain, 60m bed’ler, eski Somnia/intake, `NOCTA_HISTORY` arkeolojisi.
5. **App Store minimum:** UI freeze + OpenAI-in-IPA + RC canlı + IAP metadata + TestFlight E2E + listing screenshots + legal URL’ler (legal tamam) + version ile IAP submit. Add for Review şimdi değil.
6. **Play minimum:** yeni applicationId, release signing, `goog_` (AppConfig bugün reddeder), Play ürünleri, INTERNET/release doğrulama, Data safety. Bu V1 iOS’tan ayrı ve büyük.
7. **TEK İLK İŞ:** Canlı path UI’yı (özellikle paywall) göndermek istediğin hale getir. Mağaza ve inceleme o binary’yi fotoğraflar. HCOS’a dokunma. Implementation için onayın lazım.

Onayın olmadan koda geçilmedi.

---

## Appendix — Follow-up from repo exploration (same audit day)

Arka plan tarama ana raporu doğruladı; skor değişmedi. Eklenen net noktalar:

- `config/secrets.local.json`: OpenAI key var; RevenueCat ve Sentry hâlâ placeholder.
- iOS’ta `DEVELOPMENT_TEAM` tanımlı; imza sıfır değil, TestFlight IPA yine yok.
- `lib/ai/sleep_specialist_engine.dart` stub; `lib/core/analytics/` ve `lib/core/subscription/` boş klasör. Canlı yolda değiller.
- `NOCTA_DOCS` kodun önünde: `NOCTA_V1_SCOPE.md` neredeyse boş; HCOS test-case dokümanı artık kullanılmayan Learning/Reasoning bekliyor.
