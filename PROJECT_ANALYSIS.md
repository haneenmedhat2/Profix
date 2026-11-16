# Profix — iOS Project Analysis

## 1. Overview

**Profix** is an iOS **service-provider booking marketplace** that connects clients with on-demand service providers (handymen, plumbers, electricians, etc.). Users can browse categories, find providers, book jobs, chat in real time, pay, track orders, leave reviews, and manage their profile/wallet.

- **Platform:** iOS (UIKit, Swift)
- **Languages supported:** English, Arabic, Urdu (full RTL)
- **Architecture:** Modular MVVM with Combine
- **Primary entry point:** `Profix/Core/AppDelegate.swift` → `SceneDelegate.swift` → `SplashVC`

---

## 2. Top-Level Structure

```
Profix/
├── App/              # Feature modules (Auth, Home, Chat, Orders, …)
├── Core/             # AppDelegate, SceneDelegate
├── Networking/       # Endpoint / NetworkService / Response handling
├── Storage/          # UserDefaults property wrappers
├── Shared/           # Reusable UI, helpers, extensions
├── Resources/        # Assets, fonts, Lottie animations
├── Localization/     # en / ar / ur-Arab strings + RTL logic
├── Validation/       # Input validation + regex patterns
├── Base.lproj/       # Base storyboards
├── Info.plist
└── Profix.entitlements
```

### 2.1 Core
- `AppDelegate.swift` — Firebase init, Google Maps API registration, IQKeyboardManager setup, FCM registration.
- `SceneDelegate.swift` — Window + root VC (SplashVC) setup.

### 2.2 Networking
Custom `Endpoint`-based abstraction layered over **Alamofire**.

| File / Group | Role |
|---|---|
| `Endpoints/` | Typed route definitions (`HomeEndPoints`, `AuthEndpoints`, `ChatEndPoints`, …) |
| `HandelRequest/` | `Endpoint<T>`, `Requestable` protocol, `UploadData` for multipart |
| `HandleResponse/` | `DefaultResponseHandler`, decoding, `ResponseError` |
| `BaseResponse/` | Generic `BaseResponse<T>` + `ServerResponseKey` enum |
| `NetworkService.swift` | Facade: `request<T>()`, `requestFullResponse<T>()` |

Flow: `Endpoint<T>` → `NetworkService.request()` → `ResponseHandler` → `DefaultNetworkExecuter` → Alamofire → Decoder → `T`.

Error cases surfaced: `success`, `fail`, `exception`, `unauthenticated`, `blocked`, `needApproval`, `needActive`.

### 2.3 Storage
- `UserDefaultsExtensions.swift` — property wrappers (`ValueDefault`, `ModelsDefault`) that persist tokens, user, onboarding flags, language choice, etc.

### 2.4 Shared
- **View/** — ~29 reusable UI components: `Alert`, `BaseNav`, `GeneralButton`, `Loader`, `LanguagePopup`, `OrderCell`, etc.
- **Helper/** — `LocationManager`, `ImagePicker`, `FilePicker`, `AppHelper`, `Session`, `PaymentWebViewController`.
- **Extension/** — UIKit ergonomics (String, UIView, UITableView, UICollectionView, …).
- **Types/** — common type aliases and enums.

### 2.5 Localization
- `Language.swift` — language switching, LTR/RTL semantic attribute on the app window.
- `.strings` resources for `en`, `ar`, `ur-Arab`.

### 2.6 Validation
- `ValidationService.swift` — email / phone / password rules.
- `ValidationError.swift` — localized error copy.
- `RegularExpression.swift` — regex patterns.

### 2.7 Resources
- `Assets.xcassets` — images, colors, app icons.
- `Fonts/` — **IBM Plex Sans Arabic**.
- `LottieFile/` — JSON animations.

---

## 3. Feature Modules (`Profix/App/`)

| Module | Description |
|---|---|
| **Intro** | Splash + onboarding; routes to auth or main tab bar |
| **Auth** | Login, Signup, ForgetPassword, Verification (OTP), ResetPassword |
| **Home** | Categories, subcategories, provider search/filter, provider details, booking, order summary, CompleteBooking |
| **Orders** | MyOrders list + OrderDetails with status tracking |
| **Chat** | Rooms list + real-time chat (SocketIO). Supports text, image, file, video, audio, map messages |
| **Notification** | Notification center UI + badge count manager |
| **FCM** | Push-notification registration, token refresh, type-based routing (e.g. `delegateAcceptDate`, `delegateRefusedOrder`) |
| **More** | Profile, Settings (password / phone / profile update), Wallet, ContactUs, AboutUs, Privacy, Terms, Complaints |

Main tab bar: **Home · Orders · Chat · More** (`Shared/View/AppTabBar/AppTabBarController.swift`).

---

## 4. Architecture Pattern — MVVM + Combine

- **ViewModel per feature** (`HomeVM`, `ChatVM`, `OrderSummaryVM`, …) inheriting from `BaseViewModel`.
- `@Published` properties + `PassthroughSubject` for reactive state.
- Protocol-backed contracts (e.g. `HomeVMProtocol`, `NetworkServiceProtocol`).
- **Base classes:**
  - `BaseViewController` — shared VC lifecycle and utilities.
  - `BaseViewModel` — common network, loading, error, and auth handling.
- **UI layer:** UIKit with a mix of **XIB** files and storyboards — no SwiftUI.
- **Concurrency:** Swift `async/await` inside ViewModels alongside Combine.

Example data flow (Home):

```
SplashVC
  → AppTabBarController
    → HomeVC (XIB)  ──observes──>  HomeVM (@Published)
                                        │
                                        ▼
                      HomeEndPoints.getHomeData()
                                        │
                              NetworkService.request
                                        │
                                 Alamofire → JSON
                                        │
                      BaseResponse<[HomeResponse]> → decode
                                        │
                              @Published update → UI
```

---

## 5. Third-Party Dependencies

Inferred from imports (Podfile/Package.swift not present in tree):

| Library | Purpose |
|---|---|
| Alamofire | HTTP networking |
| Firebase/Core | Firebase bootstrap |
| Firebase/Messaging | Push notifications (FCM) |
| GoogleMaps | Location picking in bookings |
| SocketIO | Real-time chat |
| IQKeyboardManagerSwift / IQKeyboardToolbarManager | Keyboard handling |
| Lottie | Animations |

---

## 6. Notable Integrations

- **Firebase Cloud Messaging** — token refresh via `MessagingDelegate`; payload type routing to destination screens.
- **Google Maps** — location selection in booking flow; `GMSServices` initialized in `AppDelegate`.
- **SocketIO** — chat connection via `ChatSocketConnection.swift`; differentiates client vs. provider message rendering.
- **Payments** — `PaymentWebViewController` for gateway web flow; wallet module for balance.
- **Geolocation** — `AppLocationManager` feeds lat/long to provider-search queries.
- **Notifications** — badge-count manager keeps the app icon and tab in sync with unread notifications.

---

## 7. Key Files

| File | Role |
|---|---|
| `Profix/Core/AppDelegate.swift` | App bootstrap, Firebase / Maps / IQKeyboard / FCM |
| `Profix/Core/SceneDelegate.swift` | Window + root VC |
| `Profix/App/Intro/Splash/SplashVC.swift` | Splash → auth / onboarding / home |
| `Profix/Shared/View/AppTabBar/AppTabBarController.swift` | Main tab bar |
| `Profix/Networking/NetworkService.swift` | Network façade |
| `Profix/Storage/UserDefaultsExtensions.swift` | Persistence wrappers |
| `Profix/Localization/Language.swift` | Language + RTL switch |
| `Profix/Validation/ValidationService.swift` | Input validation |

---

## 8. Design Patterns in Use

- **Dependency Injection** — `NetworkService` and `ResponseHandler` injected into ViewModels.
- **Protocol-Oriented** — boundary contracts for network, VMs, and response handling.
- **Reactive state** — Combine publishers drive UI updates.
- **Generic response wrapper** — `BaseResponse<T>` standardises API contracts.
- **Typed errors** — `ResponseError` with localized user-facing messages.
- **Modular features** — each feature self-contained under `App/<Feature>/` with View / ViewModel / Model.

---

## 9. Localization & RTL

- Strings resources for `en`, `ar`, `ur-Arab`.
- `Language.swift` switches `UIView.appearance().semanticContentAttribute` and persists the chosen language.
- IBM Plex Sans Arabic is bundled to ensure consistent rendering across Arabic and Urdu.

---

## 10. Summary

Profix is a production-grade, modular iOS marketplace for service bookings. It uses a clean MVVM+Combine architecture on UIKit, with a custom typed networking layer over Alamofire, Firebase push notifications, SocketIO-based real-time chat, Google Maps for location, and full RTL localization for Arabic and Urdu.
