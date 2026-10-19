# HousyPoint V1: How the app works (reference for V2)

Source: `Housy_Point__V1/housy_point` (Flutter, Provider state management, Dio). API details: see [API_REFERENCE.md](API_REFERENCE.md). Codes like `A2` and `L1` point to entries in that file.

---

## 1. Big picture

HousyPoint is a real estate app (India, mainly NCR/Gurugram) with these features:

| Feature | What the user does | Main APIs |
|---|---|---|
| Browse listings | Resale / Rent / Commercial, filtered by city, builder and BHK | L1, L2, L3 |
| Distress deals | Below-market properties | L4 |
| New launches | New projects in the city | C5, M6 |
| Builders & projects | Builder list → projects → project detail | M2–M6 |
| Sell property | Multi-step wizard to list for resale | W1–W7 |
| Rent out property | Multi-step wizard to list for rent | W1–W6, W8 |
| Buy requirement | Wizard to post what the user wants to buy | W9 |
| Saved / Contacted | Wishlist and "show interest" | S1–S4 |
| PDI (home inspection) | Book a pre-delivery inspection: 5 steps + payment details | P1–P10 |
| Consultation | Book an expert consultation | K1–K5 |
| Compare projects | Pick 2 projects and compare them side by side | M2, M5, M6, L1 |
| Home loan | Bank rates, EMI calculator | H1–H5 |
| Refer & Earn | Referral code, earnings, withdrawals | R1–R7 |
| Search | Global search over properties, projects and builders | M7 |

---

## 2. App startup flow

```
main()
 ├─ Firebase.initializeApp
 ├─ FCMService.initialize                (push notifications)
 ├─ RemoteConfigService.initialize       (launcher_icon_alias)
 ├─ runApp(MultiProvider[15 providers])
 └─ background: save API key in secure storage, migrate the old token from prefs to secure storage

MyApp
 ├─ SplashScreen (animated)
 ├─ AppLinks deep link listener (/listing/<id>, /listings/?listing_id=)
 ├─ Connectivity listener → "Waiting for internet" screen
 ├─ AppUpdateChecker → GET /api/version (A9)
 └─ _getInitialScreen():
      wait for AuthScreenProvider.isInitialized (max 10s)
      ├─ token + phone present → GET /api/auth/profile/ (A3) to check the token
      │     ├─ 401 → clear the token → Onboarding
      │     ├─ requiresProfileUpdate → RegistrationScreen
      │     └─ OK → HomeScreen
      └─ no token → OnBoardingScreen
```

**Providers registered in main.dart:** AuthScreenProvider, ThemeProvider, CityProvider, UspFilterProvider, ShortlistProvider, BottomStepManagerProvider, MenuProvider, HomeScreenProvider, DistressDealProvider, PropertySliderProvider, PropertyProvider, FeaturedProjectListingsProvider, ReferralScreenProvider, PDIProvider, UpdateServiceProvider.

---

## 3. Onboarding & auth flow

```
OnBoardingScreen
  ├─ GET /api/app/start-posters/ (C1): image/video slides, auto-scroll, sorted by display_order
  ├─ asks for notification permission (FCM)
  └─ "Get started" → AuthFlowScreen (3 steps, BottomStepManagerProvider)

AuthFlowScreen
  step 0  AuthScreen      : country picker + phone (length depends on country, +91 = 10)
                            → POST /api/auth/send-otp/ (A1)
  step 1  OtpScreen       : 5-digit OTP, resend
                            → POST /api/auth/login/ (A2)
                            ├─ referral code present → POST /api/referrals/process-code (A7)
                            ├─ requires_profile_update → step 2
                            └─ else → HomeScreen (pushAndRemoveUntil)
  step 2  RegistrationScreen: first name, last name, email, address
                            → PUT /api/auth/profile/ (A4) → HomeScreen
```

**Local storage (V1):**
- Secure storage: `bearerToken`, `API_KEY`
- SharedPreferences: `isAuthenticated, userId, firstName, lastName, email, phone, address, dateJoined, expires, requiresProfileUpdate, userRole, referralCode, selected_city, deviceId, deviceName, deviceType, fcm token, rating keys, skipped_version`
- Legacy keys `bearerToken` / `auth_token` in prefs are still read by some services (QuizApiService, PDIApiService, FCM).

**Logout:** POST `/api/auth/logout/` (A5) → clear storage → Onboarding.

---

## 4. Home screen (bottom nav)

`HomeScreen` uses a custom bottom nav with 5 tabs:

| Tab | Screen | Notes |
|---|---|---|
| Home | `HomeContent` | main feed, described below |
| Referral | `NavReferralScreen` | Refer & Earn (section 11) |
| Saved | `ShortlistedScreen` | 2 tabs: **Contacted** (S3) and **Saved** (S1) |
| Listing | bottom sheet | 4 options: Resale / Rent / Resale Commercial / Rent Commercial → listing screen |
| Profile | `ProfileScreen` | Your Listings, Settings, Support, etc. |

### 4.1 HomeContent: top to bottom

```
SliverAppBar
  ├─ FrontPosterBanner                 GET /api/app/front-posters/ (C2)
  ├─ City selector                     CityProvider ← GET /api/cities/ (M1), saved in prefs
  ├─ Search button                     → SearchHeaderDialog → GET /api/search (M7)
  └─ UspFilter                         tabs RESALE | RENT | RESALE COMMERCIAL | RENT COMMERCIAL
                                       builder dropdown ← GET /api/builders/?city= (M2)
                                       BHK/subtype counts ← GET /api/listings/counts/ (L3)
                                       tap a BHK → BhkListingScreen (L1/L2)
Body
  ├─ ConsultationHomeCard              K1 options → bottom sheet → K2 book
  ├─ DistressDealPropertyScreen        GET /api/distress-deals/?city= (L4), 4 tabs
  ├─ DynamicNewLaunchSection           GET /api/new-launch/all/?city= (C5) → project detail (M6)
  ├─ AddPropertySection                cards: Sell / Rent / Buy → wizards (section 6)
  ├─ ReferralCardHomeScreen            → Referral tab
  ├─ PDIHomeCardWidget                 → PDIMainScreen (section 8)
  ├─ AnimatedProjectComparisonCard     → CompareProjectsScreen (section 10)
  ├─ TrustedDeveloperMarque            GET /api/builders/?page=1&limit=20 (logos)
  └─ LoveHousyPointScreen              (static)
FAB SpeedDial: Sell | Rent | Buy
End drawer: MenuScreen
```
Disabled in V1 (commented out): FeaturePremiumCard (C4), ExclusiveInventory, HomeLoanDesign, PopularDestinations.

The home screen calls `_checkForUpdates()` (A9) and the rating prompt (RatingService).

### 4.2 MenuScreen (end drawer)
- Header: user name, or "Log In"
- **Featured:** Find Home, Builders (`BuilderScreen`)
- **Properties:** Residential Resale, Residential Rental, Commercial Resale, Commercial Rental → listing screens
- **Services:** grid (consultation, loan, inspection, …)
- **Quick Actions:** Compare, Refer & Earn, Inspection (opens housypointhomeinspection.com)
- Buy / Sell / Rent buttons → wizards
- Footer: Privacy Policy, Terms, Rate Us

---

## 5. Listing browse flow

```
UspFilter / Menu / Listing tab
   └─ BhkListingScreen (allListings/bhk_listing_screen.dart)
        query: city + property_type + bhk|commercial_subtype + builder + project
        endpoint: RESALE* → /api/listings/properties   RENT* → /api/listings/rentals
        pagination: follow `next` (infinite scroll)
        └─ FeaturedPropertyCard
              ├─ ❤ Save    → POST /api/wishlist/toggle/ (S2)
              ├─ Contact   → POST /api/interests/show_interest/ (S4) + WhatsApp / call
              ├─ Share     → https://housypoint.com/listings/?type=..&listing_id=..&ref=<code> (R2 gives the code)
              └─ tap       → BuilderProjectDetailScreen
                               ├─ GET /api/projects/{id} (M6)
                               ├─ configurations, amenities, landmarks, master layout, brochure download
                               ├─ Google Maps link
                               └─ other listings in the project (L1 ?project=)
```

Builders flow: `BuilderScreen` (M2 paginated + M5) → `BuilderProjectsScreen` (M3 + M4, Residential/Commercial tabs) → `BuilderProjectDetailScreen`.

---

## 6. Sell / Rent / Buy wizards (`views/screens/Quiz/`)

### 6.1 Sell (`SellPropertyScreen` → `sell_property_widget.dart`, state `SellPropertyState`)
```
1. Property type       Residential / Commercial              (W1)
2. Sub type            Apartment, Plot, Villa… / Office, Shop…
3. Builder             paginated list + "Other" text         (W2)
4. Project             by builder + "Other"                  (W3)
5. Configuration       BHK + size                            (W4), or manual entry
6. Unit details        unit no, tower, floor, exit facing, furnishing
                       (Plot: area, dimension, exit, construction)
7. Images              project images (W5) + own photos from camera/gallery
8. Location            location, sector, country/state/city
9. Price               asking price, negotiable → optional Price insights (L5)
10. Submit             upload custom images (W6) → POST /api/wizard/property-listing/ (W7)
```
### 6.2 Rent (`rent_property_widget.dart`)
Same as Sell, but the price step asks for rent, security deposit, maintenance and corporate leasing. It also has a "Currently rented?" section (lock-in, lease duration, rent/sqft, tenant) plus BBA cost sheet and floor plan files. Submit: W6 → W8.

### 6.3 Buy (`buy_property_screen.dart`)
Steps: Resale vs New Launch → property type → subtype/BHK (or commercial status) → size → condition/age or construction type → budget, usage, timeline, description → POST `/api/wizard/buy-interest/` (W9). Login is required. It also shows matching listings (L1, `page_size=10`).

### 6.4 Your Listings
Profile → Your Listings → GET `/api/user/listings/` (W10). Four groups: property, rent, commercial sale, commercial rent.

---

## 7. Saved / Contacted

`ShortlistProvider`
- On open: S1 (wishlist) and S3 (interests), each item is `{ listing: Project }`
- Toggle save is optimistic: update the UI first, roll back if the API fails
- Show interest → S4, then refresh

---

## 8. PDI home inspection (`views/screens/HomeInspection/`)

`PDIMainScreen` is a 5-step wizard with a progress indicator (`PDIProvider` validates each step):

```
Step 0 Location   PdiLocationSelector   city list (P1)
Step 1 Project    PdiProjectSelection   builder (P2) → project (P3), or "Other"; unit no, floor;
                                        optional floor plan upload (P7)
Step 2 Plan       PdiPlanSelection      plans (P4): basic / pro / advanced, price + old price
Step 3 Schedule   PdiScheduleSelection  dates (P5) → time slots (P6)
Step 4 Confirm    PdiBookingSummary     price + 18% GST = final_price → POST /api/pdi/book/ (P8)
                  └─ BookingConfirmationScreen (booking id, date, time, plan, price)
```
Orders: `PdiBookingOrders` (P9) → `PDIBookingDetailsScreen` (P10 + P4 for plan info, WhatsApp support).

---

## 9. Consultation

- `ConsultationHomeCard` loads options (K1). If that fails, it uses fallback options.
- `ConsultationBottomsheet` form: name, phone, email, service type, consultation type, time slot, date, notes, extra services → K2.
- Support screen (`profile/support.dart`) also uses K1, plus WhatsApp, call and a Maps link.
- K3/K4/K5 (list, detail, cancel) exist in the service; no V1 screen uses them yet.

---

## 10. Compare projects

`CompareProjectsScreen`: pick a builder (M2, `page_size=100`) → project (M5 `?builder=&project_type=Residential`) for 2 slots → `ProjectComparisonResultScreen` (M6 for each project, plus resale listings for each builder: L1 `?builder=&is_resale=true`).

---

## 11. Refer & Earn (`views/screens/referEarn/`)

```
NavReferralScreen
  └─ R1 partners/current
       ├─ 404 → ReferralScreen (explainer + share)
       └─ 200 → ReferralUserDashboard
                 ├─ R2 detailed_stats (code, tier, users, earnings, share links)
                 ├─ R3 pdi-stats
                 ├─ R4 earnings history
                 ├─ MyReferrals   → R2 + R7 referred users; share via WhatsApp, Facebook, Twitter
                 └─ Earnings      → R2, R3, R4, R5 withdrawals; "Withdraw" form → R6
```
The referral code is also added to listing share links (via R2).

---

## 12. Home loan (`views/screens/homeLoanScreen/`)
HomeLoanScreen (H1), bank comparison, loan calculator (EMI), know more (H4/H5), and a loan posters card (C3). It is reachable through the route `/homeLoan_screen`; its home card is disabled.

---

## 13. Profile

`ProfileScreen` → Your Listings (W10), Settings, Support, PDI orders, Logout.
- **Settings:** GET profile (A3); each field is edited in place with PUT (A4); Delete account opens a web URL.
- **Support:** consultation options, WhatsApp, call, office map.

---

## 14. Named routes (V1 `AppRoutes`)

`/home_screen, /registration_screen, /menu_screen, /homeLoan_screen, /onboard_screen, /compare_projects_screen, /pdi_main_screen, /referral_user_dashboard, /builders_screen, /profile_screen`. An unknown route falls back to HomeScreen. Most navigation is direct `MaterialPageRoute`/`CupertinoPageRoute`.

---

## 15. V1 issues to fix in V2

1. **Many Dio instances**: about 20 separate `Dio()` objects, each with its own headers and timeouts. V2 should use one `ApiClient` with interceptors for the API key, the bearer token, 401 → logout, and logging.
2. **Token stored in three places** (secure `bearerToken`, prefs `bearerToken`, prefs `auth_token`). AuthProvider deletes the prefs copy, but `PDIApiService` and `QuizApiService` read the token from prefs, so their requests can go out without a token. V2 should keep the token only in secure storage, with a single token source.
3. **http/https mixed**: several calls use `http://housypoint.com`. Use https only.
4. **Hardcoded API key** in `main.dart`. Move it to `--dart-define` or env.
5. **Deep link bug**: `/listing` is pushed by name but never registered, so it falls back to Home. V2 should add a proper listing-detail route (go_router recommended).
6. **Device token API path bug** (`/api/api/user/...`) and an empty device token. Note `/api/auth/fcm-token/` (V1's FCM call) is a 404 too; V2 uses `/api/auth/update-fcm-token/`.
7. **Inconsistent response shapes**: PDI bookings come back as a list or as `{bookings}`, dates as a list or `{dates}`, earnings history nested `results.results`. Write tolerant parsers or ask the backend to standardize.
8. **`sendOTP` returns true on most errors** (anything except an invalid phone), so the user reaches the OTP screen even when sending failed.
9. **`QuizApiService.getFullImageUrl`** returns only the CDN base and drops the path. Fix it in V2.
10. **`PDIApiService` uses `validateStatus < 500`**, so 4xx responses do not throw and need to be checked manually.
11. **API calls inside widgets** (referral, builders, compare, settings). V2 should move them into a repository/service layer.
12. **The app store URL is a placeholder** (`id123456789`) in the update dialog.
13. **GST (18%) is calculated on the client** for PDI. Better to have the backend return it.

---

## 16. Suggested V2 structure

```
lib/
  core/
    config/api_config.dart        // ApiConfig + Endpoints (see API_REFERENCE §13)
    network/api_client.dart       // single Dio + interceptors
    storage/secure_store.dart
    router/app_router.dart        // go_router + deep links
  data/
    models/                       // Project, Builder, City, PdiPlan, Booking, Consultation, Bank...
    repositories/                 // auth, listing, wizard, wishlist, pdi, consultation, loan, referral, content
  features/
    onboarding/ auth/ home/ listings/ project_detail/ builders/
    sell/ rent/ buy/ saved/ pdi/ consultation/ compare/ loan/ referral/ profile/ search/
```
Suggested build order: core network + auth → home (city, posters, counts) → listings + detail → saved → sell/rent/buy wizards → PDI → referral → consultation/compare/loan.
