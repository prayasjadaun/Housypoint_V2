# HousyPoint — API Reference (extracted from V1)

Source: `Housy_Point__V1/housy_point/lib` (v1.0.4+15). Every endpoint below is actually called somewhere in V1; the "Used in" column points to the V1 file so you can look up edge cases.

---

## 1. Global config

| Key | Value |
| --- | --- |
| Host | `https://housypoint.com` |
| API base | `https://housypoint.com/api/` |
| Media CDN | `https://housymediabucket.blr1.cdn.digitaloceanspaces.com/media/` |
| API key header | `X-API-Key: 2wirbRenwJCGrCJU98k6wLG1PpXUPFSE` (hardcoded in V1 `main.dart`) |
| Auth header | `Authorization: Bearer <token>` (token from `/api/auth/login/`) |
| Content-Type | `application/json` (multipart for uploads) |
| Timeouts (V1) | 10s for most calls, 30s for wizard and consultation, 15s for PDI |

> V1 mixes `http://` and `https://` for the same host. In V2, use `https://` everywhere.
> In V2, move the API key out of source code (`--dart-define` or `.env`).

### Headers by group

| Group | X-API-Key | Bearer |
| --- | --- | --- |
| `send-otp`, `login` | ✅ | — |
| Listings, counts, cities, builders (UspFilterProvider) | ✅ | — |
| Buy interest | ✅ | ✅ |
| Profile, logout, FCM, wizard, wishlist, interests, PDI, consultations, referrals, user listings | — | ✅ |
| Posters, new launch, loans, projects, search | optional | optional |

### Pagination (DRF-style), used by builders, projects, listings

```json
{ "count": 120, "next": "https://housypoint.com/api/...?page=2", "previous": null, "page_count": 6, "results": [ ... ] }
```

Query params: `page`, `page_size` (some screens send `limit`). For the next page, call the `next` URL directly.

### Image URLs

If an `image_url` is relative (`project_images/...`, `uploads/...`), prefix it with the media CDN.

---

## 2. Auth & user

| # | Method | Endpoint | Auth | Used in |
| --- | --- | --- | --- | --- |
| A1 | POST | `/api/auth/send-otp/` | API key | `services/authProvider/auth_screen_provider.dart` |
| A2 | POST | `/api/auth/login/` | API key | same |
| A3 | GET | `/api/auth/profile/` | Bearer | auth provider (token check), `profile/settings.dart` |
| A4 | PUT | `/api/auth/profile/` | Bearer | registration + settings |
| A5 | POST | `/api/auth/logout/` | Bearer | auth provider |
| A6 | POST | `/api/auth/fcm-token/` | Bearer | `services/fcm_service.dart` |
| A7 | POST | `/api/referrals/process-code` | Bearer | auth provider (after login) |
| A8 | POST | `/api/user/device-token/update/` | Bearer | `quiz_api_service.dart` ⚠️ see note |
| A9 | GET | `/api/version` | Bearer (optional) | `providers/app_update_service_provider.dart` |

**A1. Send OTP**

```json
// request (phone = country code + number, no "+")
{ "phone": "919876543210" }
// error example
{ "error": "Invalid phone number format" }
```

**A2. Login (verify OTP)**: the OTP is **5 digits**

```json
// request
{
  "phone": "919876543210", "otp": "12345",
  "device_id": "...", "device_name": "Samsung SM-A515F", "device_type": "Android 13",
  "app_version": "1.0.4+15",
  "referral_code": "ABC123"            // optional
}
// response
{
  "token": "...", "expires": "...", "requires_profile_update": true,
  "user": { "id": 1, "first_name": "", "last_name": "", "email_id": "", "phone": "", "address": "", "date_joined": "", "referral_code": "" },
  "referral_code": "...",             // sometimes here
  "referral": { "code": "..." }       // or here
}
```

If `requires_profile_update == true`, show the Registration screen. Otherwise go to Home.

**A4. Update profile**: all fields are optional (Settings sends one field at a time)

```json
{ "first_name": "", "last_name": "", "email_id": "", "phone": "", "address": "" }
// response: { "user": { ... } }
```

**A6. FCM token**: `{ "fcm_token": "..." }`
**A7. Process referral**: `{ "referral_code": "ABC123" }` → `{ "success": true, "user": { "referral_code": "..." }, "message": "" }`
**A8. Device token**: `{ "device_id", "device_token", "device_type": "android|ios" }`. ⚠️ In V1 the Dio base is `/api`, so the real URL becomes `/api/api/user/device-token/update/`, which is a bug. V1 also always sends `device_token` as `""`. In V2, A6 is enough.
**A9. Version**: `{ "success": true, "app_version": "1.0.5" }`. The app compares it with the local version and shows the update dialog. Skip lasts 24h (prefs `skipped_version`, `skip_until_time`).

**Web links (open in browser)**

- Delete account: `https://housypoint.com/accounts/delete/`
- Privacy: `https://housypoint.com/privacy_policy/`
- Terms: `https://housypoint.com/terms_conditions/`
- Home inspection site: `https://housypointhomeinspection.com/`

---

## 3. App content (posters / banners)

| # | Method | Endpoint | Response | Used in |
| --- | --- | --- | --- | --- |
| C1 | GET | `/api/app/start-posters/` | `[FrontPoster]` | `onBoardScreen/onboard_screen.dart` |
| C2 | GET | `/api/app/front-posters/` | `[FrontPoster]` | `services/front_poster_service.dart` (home banner) |
| C3 | GET | `/api/app/home-loan-posters/` | `[{ media_url, display_order }]` | `homeLoanScreen/loan_card_home_screen.dart` |
| C4 | GET | `/api/images/all/` | `{ success, uploads: [...] }` | `PremiumFeature/feature_premium_card.dart` (disabled on home) |
| C5 | GET | `/api/new-launch/all/?city=` | `{ success, data: [NewLaunch] }` | `homeContentScreen/new_launch_home_card.dart` |

```json
// FrontPoster
{ "id": 1, "title": "", "media_type": "image|video", "media_url": "", "display_order": 1, "display_second": 5 }
// NewLaunch
{ "id": 1, "name": "", "city": "", "min_price": 0, "overview_price_range": "", "first_image_url": "", "builder_logo_url": "" }
```

Sort by `display_order`. If onboarding returns an empty list, go straight to the auth flow.

---

## 4. Master data: cities, builders, projects, search

| # | Method | Endpoint | Query | Used in |
| --- | --- | --- | --- | --- |
| M1 | GET | `/api/cities/` | — | `providers/city_provider.dart`, `usp_filter_provider.dart`, `pdi_api_service.dart` |
| M2 | GET | `/api/builders/` | `city, page, page_size, search, limit` | many |
| M3 | GET | `/api/builders/{id}/` | — | `builderProjectsScreen/builder_projects_screen.dart` |
| M4 | GET | `/api/builders/{id}/projects/` | `project_type=Residential\|Commercial, city` | builder projects, PDI |
| M5 | GET | `/api/projects/` | `builder, city, project_type, project_status, new_launch, search, page, page_size\|limit` | builders screen, compare, wizard, PDI |
| M6 | GET | `/api/projects/{id}` | — | `services/project_details_api_service.dart` (project detail) |
| M7 | GET | `/api/search` | `q, search_type=all, include_location=true, include_area=true, include_bhk=true` | `homeContentScreen/search_header_screen.dart` |

```json
// M1 City (plain list, not paginated)
{ "id": 1, "name": "Gurugram", "sector": "", "state": { "name": "Haryana", "country": { "name": "India" } } }
// M2 Builder (paginated)
{ "id": 1, "builder_name": "DLF", "builder_logo": "https://..." }
// M4 Project (plain list) / M5 (paginated)
{ "id": 1, "name": "", "project_type": "Residential", "project_status": "", "city_name": "", "builder_id": 1, "project_logo_image": "" }
// M7 Search
{ "properties": [ ... ], "projects": [ ... ], "builders": [ ... ] }
```

**Project detail fields (M6 + listing cards use the same `Project` model):**
`id, listing_id, name, project, project_type, project_status, builder, builder_name, builder_logo, builder_other, project_other, city, city_name, state, country, sector, location, location_map_link, distance, asking_price, market_price, price, rent, rent_price, price_negotiable, is_negotiable, bhk, size, sqft, configuration, detail, project_configurations, residential_subtype, commercial_subtype, floor_number, block_tower, exit_location, currently_rented, config_bhk_other, config_size_other, image, image_url, image_urls, images, first_image, selected_project_images, layout_image, layout_image_url, master_layout_image, project_logo_image, project_logo_url, brochure_file, amenities, landmarks, overview_price_range, overview_payment_plan, overview_rera_details, project_about, description, contact_name, contact_number, contact_email`

---

## 5. Listings (Resale / Rent / Commercial)

| # | Method | Endpoint | Used in |
| --- | --- | --- | --- |
| L1 | GET | `/api/listings/properties` | USP filter, BHK listing, exclusive inventory, compare, distress, buy screen |
| L2 | GET | `/api/listings/rentals` | same as above, for rent |
| L3 | GET | `/api/listings/counts/` | `usp_filter_provider.dart` (BHK counts on home) |
| L4 | GET | `/api/distress-deals/` | `propertiesProvider/distress_deal_provider.dart` |
| L5 | GET | `/api/price-suggestions/` | `Quiz/price_insights_screen.dart` |

**L1/L2 query params** (send `X-API-Key`):

| Param | Values |
| --- | --- |
| `city` | city name (e.g. `Gurugram`) |
| `property_type` | `residential` \| `commercial` |
| `bhk` | `1`, `2`, `3`, `4`, `5+`, `studio` … (first word of "2 BHK") |
| `commercial_subtype` | `office`, `shop`, `food court`, `hotel`, `restaurant`, `studio` |
| `builder` / `builder_name` | builder id / name |
| `project` | project id |
| `is_resale` | `true` (compare screen) |
| `page`, `page_size` | 15 to 30 in V1 |

Rule: tab RESALE/COMMERCIAL RESALE → `properties`; RENT/COMMERCIAL RENT → `rentals`.

**L3 counts**: `?city=&builder=`

```json
{
  "total": { ... },
  "residential_bhk": { "sale": { "five_plus": 0, "four": 0, "three": 0, "two": 0, "one": 0, "studio": 0 }, "rent": { ... } },
  "commercial_subtypes": { "sale": { "office": 0, "shop": 0, "food court": 0, "hotel": 0, "restaurant": 0, "studio": 0 }, "rent": { ... } }
}
```

**L4 distress deals**: `?city=` → `{ "resale": [], "rent": [], "resale_commercial": [], "rent_commercial": [] }`

**L5 price suggestions**: `?builder_id=&project_id=&configuration_id=&listing_type=`

**Share link format** (listing):
`https://housypoint.com/listings/?type=resale|rental&listing_id=<id>&city=<city>&ref=<referral_code>`

---

## 6. Sell / Rent / Buy wizard (QuizApiService)

Base `https://housypoint.com/api`, Bearer token. File: `services/quiz_api_service.dart`.

| # | Method | Endpoint | Purpose |
| --- | --- | --- | --- |
| W1 | GET | `/api/wizard/options/` | property types / subtypes for the wizard |
| W2 | GET | `/api/builders?page=` | builder picker (paginated) |
| W3 | GET | `/api/projects?builder=&project_type=&page=` | project picker |
| W4 | GET | `/api/wizard/projects/{projectId}/configurations/` | `[{ id, detail: "3 BHK", size: 1650 }]` |
| W5 | GET | `/api/wizard/projects/{projectId}/images/` | `[{ id, image_url }]` (relative → CDN) |
| W6 | POST | `/api/upload-images/` | multipart, field `custom_images` (repeat per file) → `{ success, image_ids: [..] }` or `[{ id }]` |
| W7 | POST | `/api/wizard/property-listing/` | **Sell** submit |
| W8 | POST | `/api/wizard/rent-listing/` | **Rent** submit |
| W9 | POST | `/api/wizard/buy-interest/` | **Buy** requirement (X-API-Key + Bearer, 401 → logout) |
| W10 | GET | `/api/user/listings/` | "Your Listings" in profile |

**W7 Sell payload**

```json
{
  "property_type": "residential|commercial",
  "residential_subtype": "apartment|plot|...",      // or "commercial_subtype"
  "asking_price": 12500000,
  "price_negotiable": true,
  "builder_id": 1,            // or "builder_other": "Name"
  "project_id": 10,           // or "project_other": "Name"

  // non-plot:
  "has_config_id": true,
  "configuration_id": 55,     // or config_bhk_other + config_size_other + config_size_other_unit_type
  "unit_number": "A-1203", "block_tower": "A", "floor_number": "12",
  "exit_location": "east",
  "furnishing": "semi-furnished",   // commercial: "commercial_furnishing"

  // plot:
  "plot_area": 200, "plot_dimensions": "20x40", "plot_exit_location": "north", "plot_construction": "...",

  "custom_image_ids": [101, 102],          // from W6
  "selected_project_images": [7, 8],       // ids from W5
  "location": "", "sector": "", "country": "", "state": "", "city": ""
}
```

Response may contain a new `token` / `auth_token` / `access_token`. V1 saves it.

**W8 Rent payload**

```json
{
  "property_type": "residential", "residential_subtype": "apartment",
  "rent_price": 45000, "security_deposit": 90000, "maintenance": 3000,
  "price_negotiable": true, "corporate_leasing_interest": false,
  "unit_number": "max 10 chars", "block_tower": "max 10 chars", "floor_number": "5", "exit_location": "north",
  "furnishing": "fully-furnished",
  "builder_id": 1, "project_id": 10,
  "configuration_id": 55,                  // or config_bhk_other / config_size_other / config_size_other_unit_type (required either way)
  "custom_image_ids": [], "selected_project_images": [],
  "location": "", "sector": "", "country": "max 10 chars", "state": "", "city": "",
  "currently_rented": "yes", "lockin_period": 11, "lease_duration": 24, "rent_per_sqft": 40, "rented_to_whome": "",
  "bba_cost_sheet": "<path>", "floor_plan": "<path>",
  "description": "Property listed through Housy Point app"
}
```

**W9 Buy interest payload**

```json
{
  "property_type": "residential|commercial",
  "budget": 15000000,
  "usage_type": "...", "buying_timeline": "...", "description": "",
  "property_source": "resale|new_launch",
  "residential_subtype": "apartment", "bhk": "3",                  // residential
  "commercial_subtype": "office", "commercial_status": "pre_leased", // commercial
  "size": 1500, "size_unit": "sqft",
  "condition": "...", "age": "...",            // resale
  "construction_type": "..."                   // new property
}
```

**W10 response**

```json
{ "property_listings": [], "rent_listings": [], "commercial_sale_listings": [], "commercial_rent_listings": [] }
```

---

## 7. Wishlist (Saved) & Interests

File: `services/providers/shortlisted_provider.dart`. Bearer.

| # | Method | Endpoint | Body / Query | Response |
| --- | --- | --- | --- | --- |
| S1 | GET | `/api/wishlist/?user_id={id}` (fallback `/api/wishlist/list/`) | — | `{ wishlist: [{ listing: Project }] }` |
| S2 | POST | `/api/wishlist/toggle/` | `{ listing_id }` or `{ rent_listing_id }` | 200/201 |
| S3 | GET | `/api/interests/?user_id={id}` | — | `{ interests: [{ listing: Project }] }` |
| S4 | POST | `/api/interests/show_interest/` | `{ listing_id \| rent_listing_id, distress_deal: bool }` | 200/201 |

Use `listing_id` when present, otherwise `id`.

---

## 8. PDI (Home Inspection)

Files: `services/pdi_api_service.dart`, `providers/pdi_provider.dart`. Bearer.

| # | Method | Endpoint | Notes |
| --- | --- | --- | --- |
| P1 | GET | `/api/cities/` | step 1, location |
| P2 | GET | `/api/builders/?city=&page=1&page_size=100&search=` | step 2 |
| P3 | GET | `/api/builders/{id}/projects/?project_type=Residential&city=` | step 2 |
| P4 | GET | `/api/pdi/plans/` | `{ plans: [PdiPlan] }` |
| P5 | GET | `/api/pdi/dates/` | `["2026-10-20", ...]` or `{ dates: [...] }` |
| P6 | GET | `/api/pdi/time-slots/?date=yyyy-MM-dd` | `{ success, slots: [{ id, time: "10:00:00", available, is_active }] }`. Show only slots with `available > 0 && is_active` |
| P7 | POST | `/api/pdi/upload-floor-plan/` | multipart field `floor_plan` → `{ file_url }` |
| P8 | POST | `/api/pdi/book/` | see below |
| P9 | GET | `/api/pdi/bookings/` | screen expects `{ success, bookings: [] }`, service expects a plain list. Handle both |
| P10 | GET | `/api/pdi/bookings/{id}/` | booking detail |

**P8 Book payload**

```json
{
  "city": "Gurugram", "plan_type": "basic|pro|advanced",
  "unit_number": "A-1203", "floor_number": "12", "timeslot_id": "<slot id>",
  "price": 4999, "final_price": 5899,          // final = round(price * 1.18), 18% GST
  "builder_id": "1",  // or "builder_other"
  "project_id": "10", // or "project_other"
  "old_price": 6999, "notes": "", "floor_plan_url": "<from P7>"
}
// 400 → { message, errors }
```

**PdiPlan fields:** `id, name, title, plan_type, price, old_price, description, features, feature_points, is_popular, color`
**Booking fields:** `id, booking_id, status, plan, plan_type, price, old_price, final_price, project, project_other, builder, builder_other, city, unit_number, floor_number, appointment_date, appointment_time, date, time, notes, floor_plan_url, has_floor_plan, created_at`

---

## 9. Consultations

Base `https://housypoint.com/api/consultations/`. Bearer (set via `setAuthToken`). File: `services/consultation_api_service.dart`.

| # | Method | Endpoint | Notes |
| --- | --- | --- | --- |
| K1 | GET | `/api/consultations/options/` | `{ success, data: { service_types, consultation_types, time_slots, status_types, services, all_services } }`, each item `{ value, label }`. V1 falls back to hardcoded options on error |
| K2 | POST | `/api/consultations/book/` | see below |
| K3 | GET | `/api/consultations/?page=&limit=&status=&user_only=` | `{ success, data: { consultations: [], pagination } }` |
| K4 | GET | `/api/consultations/{id}/` | detail |
| K5 | POST | `/api/consultations/{id}/cancel/` | cancel |

```json
// K2 request
{
  "full_name": "", "phone_number": "", "email": "",
  "service_type": "", "time_slot": "", "consultation_type": "",
  "other_description": "", "additional_notes": "", "booking_date": "", "added_services": []
}
// pagination
{ "current_page": 1, "total_pages": 1, "total_items": 3, "items_per_page": 10, "has_next": false, "has_previous": false }
```

Consultation fields: `id, booking_id, user_id, full_name, phone_number, email, service_type(_display), consultation_type(_display), time_slot(_display), status(_display), booking_date, consultation_fee, assigned_consultant, admin_notes, additional_notes, other_description, added_services, created_at, updated_at`

---

## 10. Home loan

File: `services/loan_api_service.dart`. No auth.

| # | Method | Endpoint | Response |
| --- | --- | --- | --- |
| H1 | GET | `/api/loan/banks/` | `{ results: [Bank] }` |
| H2 | GET | `/api/loan/banks/{id}/` | `Bank` |
| H3 | GET | `/api/loan/banks/loan-type/{loanType}/` | `[Bank]` |
| H4 | GET | `/api/loan/loan-details/` | `{ results: [LoanDetails] }` |
| H5 | GET | `/api/loan/loan-details/loan-type/{loanType}/` | `LoanDetails` (404 → `{ error }`) |

Bank: `id, bank_name, bank_type, bank_logo, bank_logo_url, interest_rate, emi_per_lakh, loan_type, loan_amount_range, loan_tenure, processing_fee, prepayment_charges, description, eligibility_criteria, required_documents, features_benefits, application_process, schemes, faqs, website_url, is_active`
LoanDetails: `id, loan_type, title, description, home_loan_interest, personal_loan_interest, business_loan_interest, loan_against_property_interest, public_interest_range, private_interest_range, nbfc_interest_range, features, benefits, eligibility_criteria, required_documents, application_process, faqs`

> The home-loan card is commented out on the V1 home screen; the screens still exist.

---

## 11. Referral (Refer & Earn)

Base `https://housypoint.com`, Bearer. Files: `views/screens/referEarn/*`.

| # | Method | Endpoint | Notes |
| --- | --- | --- | --- |
| R1 | GET | `/api/referrals/partners/current` | 200 = partner registered, 404 = not a partner |
| R2 | GET | `/api/referrals/earnings/detailed_stats/` | dashboard stats + referral code + share links |
| R3 | GET | `/api/referrals/pdi-stats` | `{ pdi_bookings_count, pdi_earnings, pdi_pending, recent_bookings }` |
| R4 | GET | `/api/referrals/earnings/earnings_history` | `{ results: { results: [] } }` or `{ results: [] }` |
| R5 | GET | `/api/referrals/withdrawals` | `{ results: [] }` |
| R6 | POST | `/api/referrals/withdrawals/` | `{ amount, account_name, account_number, ifsc_code }` |
| R7 | GET | `/api/referrals/referred-users/detailed` | `{ results: [] }` |

**R2 response (fields used):**

```json
{
  "referral_code": "", "tier": "gold", "tier_display": "", "tier_progress": 0,
  "users": { "total_referred": 0, "active_referred": 0 },
  "earnings": { "total_earned": 0, "available_balance": 0, "pending_earnings": 0, "voucher_earnings": 0 },
  "activities": { "property_listings": 0, "buy_interests": 0 },
  "sharing_link": { "main": "", "add_property": "", "rent_listing": "", "listings": { "resale": "" } }
}
```

Partner (R1) fields: `referral_code, tier, tier_display, tier_progress, total_referrals, successful_listings, successful_sales`

**Referral web links:** `https://housypoint.com/?ref=CODE`, `/add-property/?ref=`, `/add-rent-property/?ref=` (some screens use `/rent-property/?ref=`), `/listings/?ref=`, `/pdi_service_page/?ref=`

---

## 12. Firebase (not REST)

- **FCM**: token is sent with A6. Permission is asked on onboarding.
- **Remote Config**: key `launcher_icon_alias` (default `default`) switches the app icon (`AppConfigProvider`).
- **In-app review**: shown after 3 launches and 2 days (`RatingService`).

---

## 13. Suggested V2 endpoint constants

```dart
class ApiConfig {
  static const host = 'https://housypoint.com';
  static const baseUrl = '$host/api/';
  static const mediaCdn = 'https://housymediabucket.blr1.cdn.digitaloceanspaces.com/media/';
  static const apiKey = String.fromEnvironment('HP_API_KEY');
}

class Endpoints {
  // auth
  static const sendOtp = 'auth/send-otp/';
  static const login = 'auth/login/';
  static const profile = 'auth/profile/';
  static const logout = 'auth/logout/';
  static const fcmToken = 'auth/fcm-token/';
  static const processReferral = 'referrals/process-code';
  static const version = 'version';
  // content
  static const startPosters = 'app/start-posters/';
  static const frontPosters = 'app/front-posters/';
  static const homeLoanPosters = 'app/home-loan-posters/';
  static const allImages = 'images/all/';
  static const newLaunches = 'new-launch/all/';
  // master
  static const cities = 'cities/';
  static const builders = 'builders/';
  static String builder(int id) => 'builders/$id/';
  static String builderProjects(int id) => 'builders/$id/projects/';
  static const projects = 'projects/';
  static String project(int id) => 'projects/$id';
  static const search = 'search';
  // listings
  static const saleListings = 'listings/properties';
  static const rentListings = 'listings/rentals';
  static const listingCounts = 'listings/counts/';
  static const distressDeals = 'distress-deals/';
  static const priceSuggestions = 'price-suggestions/';
  // wizard
  static const wizardOptions = 'wizard/options/';
  static String projectConfigs(int id) => 'wizard/projects/$id/configurations/';
  static String projectImages(int id) => 'wizard/projects/$id/images/';
  static const uploadImages = 'upload-images/';
  static const sellListing = 'wizard/property-listing/';
  static const rentListing = 'wizard/rent-listing/';
  static const buyInterest = 'wizard/buy-interest/';
  static const myListings = 'user/listings/';
  // wishlist / interest
  static const wishlist = 'wishlist/';
  static const wishlistToggle = 'wishlist/toggle/';
  static const interests = 'interests/';
  static const showInterest = 'interests/show_interest/';
  // pdi
  static const pdiPlans = 'pdi/plans/';
  static const pdiDates = 'pdi/dates/';
  static const pdiSlots = 'pdi/time-slots/';
  static const pdiUploadFloorPlan = 'pdi/upload-floor-plan/';
  static const pdiBook = 'pdi/book/';
  static const pdiBookings = 'pdi/bookings/';
  static String pdiBooking(String id) => 'pdi/bookings/$id/';
  // consultation
  static const consultations = 'consultations/';
  static const consultationOptions = 'consultations/options/';
  static const consultationBook = 'consultations/book/';
  static String consultation(int id) => 'consultations/$id/';
  static String consultationCancel(int id) => 'consultations/$id/cancel/';
  // loan
  static const banks = 'loan/banks/';
  static String bank(int id) => 'loan/banks/$id/';
  static String banksByType(String t) => 'loan/banks/loan-type/$t/';
  static const loanDetails = 'loan/loan-details/';
  static String loanDetailsByType(String t) => 'loan/loan-details/loan-type/$t/';
  // referral
  static const partnerCurrent = 'referrals/partners/current';
  static const referralStats = 'referrals/earnings/detailed_stats/';
  static const referralPdiStats = 'referrals/pdi-stats';
  static const earningsHistory = 'referrals/earnings/earnings_history';
  static const withdrawals = 'referrals/withdrawals/';
  static const referredUsers = 'referrals/referred-users/detailed';
}
```
