# Abo Glumbo — System Workflows & Feature Documentation

Reverse-engineered from source on 2026-07-29. Covers:

| Repo | Role |
|---|---|
| `abo_glumbo_bkk` | **Customer app** (Flutter) |
| `abo_glumbo_technician_bbk` | **Technician + Admin panel** (Flutter) — also hosts the **Cloud Functions** backend under `functions/` |

Both apps talk to the same Firebase project (Firestore + RTDB for chat + Storage + FCM). There is no
custom API server; all cross-actor orchestration happens in Cloud Functions triggers.

---

## 1. Data model — Firestore collections

| Collection | Written by | Purpose |
|---|---|---|
| `bookings` | both apps + CF | The single source of truth for a confirmed job. Warranty lives **inside** the booking doc as a `warranty` map — there is no separate warranty collection. |
| `booking_request` | customer app | Short-lived doc for the **manual/broadcast** flow. Deleted or `status: closed` once a technician is picked. |
| `auto-assignment_requests` | customer app + CF | Parallel doc for the **auto-assign** flow. Mirrors booking data; drives the cron. |
| `job_requests` | customer app | Short-lived doc for the **rebook** flow (targeted at one technician). |
| `job_offers` | CF + both apps | One doc per (request × technician). The fan-out unit. |
| `counter_offers` | technician app | Counter-proposed time records (also mirrored onto `booking.activeCounterOffer` and `job_offers.proposedTime`). |
| `users` | technician app | **Technicians and admins.** `role: "technician"`, `isOnline`, `isVerified`, `jobRoles[]`, `liveLocation`, `last_known_location`, `geohash`. |
| `customers` | customer app | Customer profiles + `addresses[]` (each with `lat`/`lon`, `isSelected`). |
| `admins` | admin | `accessLevel` 0/1/2 (2 = customer-service, excluded from some notifications). |
| `categories`, `services`, `locations` | admin | Catalogue. `services.category` is the id matched against technician `jobRoles`. |
| `counters/daily_booking_id` | CF | Transactional counter for human-readable ids `AG-YYMMDD-NNNN`. |
| `transactions`, `unified_payouts`, `tipping` | both | Money. |
| `<collection>/{id}/notifications` | CF + both apps | Per-user in-app notification inbox (parallel to FCM push). |

### 1.1 Booking status codes (`bookingStatusCode`)

| Code | Meaning | Set by |
|---|---|---|
| `P` | Pending — no technician assigned | customer app on auto-assign create ([save_booking.dart:618](../abo_glumbo_bkk/lib/services/booking/save_booking.dart:618)); technician cancel ([app_services.dart:1309](lib/services/app_services.dart:1309)); rebook fallback |
| `A` | Assigned / Accepted | customer selection, admin assign ([admin_bloc.dart:26](lib/pages/home/admin/bloc/admin_bloc.dart:26)), technician accept of auto-assign offer ([app_services.dart:3146](lib/services/app_services.dart:3146)) |
| `CP` | Completion Pending — technician finished work, awaiting customer payment ([app_services.dart:1335](lib/services/app_services.dart:1335)) |
| `VP` | Verification Pending — customer uploaded payment proof, awaiting technician verification ([upload_payment_proof_sheet.dart:192](../abo_glumbo_bkk/lib/sheets/upload_payment_proof_sheet.dart:192)) |
| `C` | Completed — technician verified payment ([verify_payment_sheet.dart:118](lib/pages/bookings/widgets/verify_payment_sheet.dart:118)) |
| `R` | Rejected by admin ([admin_bloc.dart:52](lib/pages/home/admin/bloc/admin_bloc.dart:52)) |
| `X` | Cancelled (admin tab label) |
| `XC` | Cancelled by customer ([app_services.dart:560](../abo_glumbo_bkk/lib/services/app_services.dart:560)) |
| `SR` | "Searching / Re-routing" — **read in 5 places, never written.** See §12.2 |

Admin tabs: `P / A / CP / C / X / R` ([admin_home.dart:30](lib/pages/home/admin/admin_home.dart:30)).

### 1.2 Warranty status codes (`booking.warranty.warrantyStatusCode`)

| Code | Meaning |
|---|---|
| `A` | Active — warranty attached, no claim yet |
| `R` | Requested — customer claimed, or admin (re)assigned a technician, awaiting technician acceptance |
| `S` | Scheduled/Accepted — technician accepted the claim |
| `C` | Completed |
| `X` | Rejected by admin |
| `E` | Expired |

Warranty tabs: `R / S / C / X / E` ([warranty_page.dart:32](lib/pages/bookings/warranty_page.dart:32)).

### 1.3 Job offer statuses (`job_offers.status`)

`pending` → `accepted_by_technician` | `accepted` | `declined` | `counter_offered` | `customer_counter_offered` | `accepted_by_customer` | `closed` | `expired` | `cancelled`

Distinction that matters:
- **`accepted`** — terminal, technician is bound to the booking (auto-assign path only).
- **`accepted_by_technician`** — "I'm interested"; the customer still chooses (broadcast + rebook paths).

---

## 2. Pricing & work hours

`ServiceModel.isOnWorkHour(currentTime)` ([service.dart:448](../abo_glumbo_bkk/lib/models/service.dart:448)):
1. If `workingDays` is set and the weekday isn't in it → **off-hour** (holiday).
2. Compare minutes-of-day against `workStartTime`/`workEndTime`; handles the wrap-around case (start > end).
3. If either bound is null → defaults to **on-hour**.

`getCurrentPrice()` returns `onWorkHourPrice` or `offWorkHourPrice`, and **0 when that band is not
priced**. The resolved price is frozen onto the booking's `service.price` at creation time, and
`booking.isOnHour` records which band applied. `effectiveInspectionFee` re-derives it on read.

> ⚠️ **The general `price` field is not a customer-facing price.** It used to be the fallback whenever
> either band was null or zero, so an unpriced band silently billed the customer the general price.
> It is now read **nowhere in the customer app** — an unpriced band charges 0. Its one remaining job
> is to be the basis for the technician's monthly bonus; see §17.
>
> Note that `booking.service.price` is *not* the general price. All three creation paths overwrite it
> with the resolved band price (`service.copyWith(price: bookingTimePrice)`), so on a booking document
> it is the frozen charged amount. The general price only lives on `services/{id}`, which is why it is
> copied onto `completionData.generalServicePrice` when a technician completes a job.

Note: on-hour is evaluated against **`DateTime.now()` (device local time)** in the UI gate
`_isCurrentTimeOffHour()` ([book_service_page.dart:2537](../abo_glumbo_bkk/lib/pages/bookings/book_service_page.dart:2537)), but
against a Middle-East-normalised clock in `_getSelectedPrice()`. See §12.5.

---

## 3. The three booking creation paths

The customer app's `BookServicePage` is a 4-step wizard (0: when/where → 1: issue notes+media →
2: technician → 3: review) and picks one of three backends at step 2 and again at confirm.

### 3.1 Decision matrix

`_shouldShowTechnicianSelection()` ([book_service_page.dart:2525](../abo_glumbo_bkk/lib/pages/bookings/book_service_page.dart:2525)):

```dart
if (isServiceNow && !_isCurrentTimeOffHour()) return true;   // Now + on-hour  → manual
if (!isServiceNow && selectedDate != null)  return !_isCurrentTimeOffHour();
return false;                                                 // otherwise      → auto-assign
```

| Scenario | Current clock | Result |
|---|---|---|
| Service Now | on-hour | **Manual broadcast** (customer picks) |
| Service Now | off-hour | **Blocked** — button disabled + snackbar ([book_service_page.dart:2621](../abo_glumbo_bkk/lib/pages/bookings/book_service_page.dart:2621)) |
| Service Later | on-hour | **Manual broadcast** |
| Service Later | off-hour | **Auto-assign** |
| Rebook (any) | any | **Targeted rebook**, with fallback |

The final branch at confirm time is `isManual = isServiceNow || _activeRebookTechnician != null || _shouldShowTechnicianSelection()`
([book_service_page.dart:2848](../abo_glumbo_bkk/lib/pages/bookings/book_service_page.dart:2848)).

> ⚠️ The docstring above `_shouldShowTechnicianSelection()` claims "Service Later + On Hour + **Today** →
> technician selection; **Future Date** → auto-assign". The code has no date check — any future date
> during on-hours goes to manual broadcast. See §12.1.

---

### 3.2 Path A — Manual / broadcast ("Service Now", and "Later" during on-hours)

**Step 2 (`_onContinueFromSecondStep`, [book_service_page.dart:2686](../abo_glumbo_bkk/lib/pages/bookings/book_service_page.dart:2686))**

1. Customer app writes a `booking_request` doc via `BookingUtils.saveBookingRequest`
   ([save_booking.dart:429](../abo_glumbo_bkk/lib/services/booking/save_booking.dart:429)) with
   `status: 'searching'`, `acceptedTechnicians: []`, `rejectedTechnicians: [...]`.
   Media goes to `issueMedia/{id}_image_{ts}.jpg`.
2. A **5-minute client timer** starts (`_startExpiryTimer`). On fire it sets `status: 'closed'` and
   bounces the wizard back to step 1.

**Fan-out (CF `onBookingRequestCreated`, [bookingTriggers.js:8](functions/src/triggers/bookingTriggers.js:8))**

Eligibility filter, applied to every doc in `users` where `role == technician && isOnline && isVerified`:

| # | Check | Detail |
|---|---|---|
| 1 | Not in `request.rejectedTechnicians` | |
| 2 | **Job role** | `service.category` must be in `tech.jobRoles[]` |
| 3 | **Has coordinates** | `liveLocation` → `lastKnownLocation` → `last_known_location`, first that parses |
| 4 | **Distance ≤ 20 km** | Haversine from customer's selected address |
| 5 | **No started job** | no `bookings` with `agent.uid == tech && status == 'A' && trackingStartedAt && !completedAt && !cancelledAt` |
| 6 | **No same-instant booking** | no existing `A` booking whose `bookingDateTime` equals this one to the millisecond |

Each survivor gets a `job_offers` doc (`status: pending`, `expiresAt: now + 120s`, `isRebook: false`)
plus a trilingual FCM push. All offers are committed in one batch.

**Technician side**

`getJobOffersStream` ([app_services.dart:2967](lib/services/app_services.dart:2967)) streams offers for the
signed-in technician filtered to `pending | counter_offered | customer_counter_offered |
accepted_by_technician`, combined with a 10 s ticker so `expiresAt` is re-evaluated client-side.
Because the `bookingId` here is the *request* id and no `bookings` doc exists yet, the card renders
straight from `offerData`.

Technician can:
- **Accept** → `acceptJobOffer` with `requestId` set: only flips the offer to `accepted_by_technician`
  ([app_services.dart:3081](lib/services/app_services.dart:3081)). No booking is created.
- **Decline** → `declineJobOffer` → `status: declined`.
- **Counter-offer** a new time → offer `status: counter_offered` + `proposedTime`, a `counter_offers`
  doc, and `booking.activeCounterOffer`.

**Back to the customer (CF `onManualJobOfferUpdated`, [bookingTriggers.js:179](functions/src/triggers/bookingTriggers.js:179))**

On `→ accepted_by_technician`, and only while the request is still `status == 'searching'`, the CF:
- Scans **all** of that technician's bookings to compute `completedJobsCount` (status `C` +
  `paymentCompleted`) and average `review.rating`.
- Computes live distance.
- `arrayUnion`s an `acceptedTechnicians` entry `{uid, name, phone, profileUrl, rating, completedJobs, distance, acceptedAt}`.
- Pushes "Technician Accepted!" to the customer.

On `→ declined` it adds the tech to `booking_request.rejectedTechnicians` **and**
`auto-assignment_requests.cancelledWorkerUids` (best-effort, `Promise.allSettled`).

**Customer selects** (`EmbeddedTechnicianSearch` in-wizard, or the standalone `SearchingTechniciansScreen`):
`_selectTechnician` ([searching_technicians_screen.dart:327](../abo_glumbo_bkk/lib/pages/bookings/searching_technicians_screen.dart:327))
copies the request into `bookings/{sameId}` with `bookingStatusCode: 'A'`, `assignedAt`,
`technicianSelectedAt`, then **deletes** the `booking_request`.
CF `onBookingCreatedCleanupOffers` then deletes the `job_offers` docs for that id that **predate the
booking** — it compares each offer's `createdAt` against the booking's own `createTime`. The
comparison is not cosmetic: the auto-assign path writes `bookings/{id}` and
`auto-assignment_requests/{id}` in one atomic batch, so this trigger and `onAutoAssignmentRequestCreated`
fire concurrently on the same id, and an unconditional delete used to wipe the offers that had just
been created whenever this one happened to run second (a cold start is enough — and off-peak traffic
is exactly when cold starts are normal).

The in-wizard variant ([book_service_page.dart:2854](../abo_glumbo_bkk/lib/pages/bookings/book_service_page.dart:2854)) does the
same but strips `status`/`acceptedTechnicians`/`rejectedTechnicians` and re-uploads media to a
permanent path first.

Customer can also **Search again** ([searching_technicians_screen.dart:174](../abo_glumbo_bkk/lib/pages/bookings/searching_technicians_screen.dart:174)):
deletes the request and recreates it under a fresh id, carrying `rejectedTechnicians` forward.

---

### 3.3 Path B — Auto-assignment ("Later" during off-hours)

`BookingUtils.saveAutoAssignmentRequest` ([save_booking.dart:536](../abo_glumbo_bkk/lib/services/booking/save_booking.dart:536))
writes **two** docs with the same id:
- `bookings/{id}` — `bookingStatusCode: 'P'`, `agent: null`, `autoAssignmentStatus: 'ready_to_assign'`
- `auto-assignment_requests/{id}` — `status: 'P'`, `notificationSent: false`,
  `type: 'instant'` if the booking is **≤ 180 min** away, else `'late'`

**Instant** (CF `onAutoAssignmentRequestCreated`) fires immediately on create.

**Late** — handled by the cron `processAutoAssignments`, **every 4 minutes**:
1. Load all `auto-assignment_requests` with `status == 'P'`.
2. Verify the `bookings` doc still exists and is `P`; otherwise copy its status onto the
   request and skip.
3. If the appointment is more than **1 hour in the past**, retire the request (`status: 'expired'`),
   notify admins ("Auto-Assignment Failed") and stop. The booking stays `P` with no agent so it can
   still be assigned by hand.
4. `instant` requests are re-broadcast every tick (to newly-online techs); `late` requests only start
   once the booking is **within 3 hours**. This is deliberate policy, not a latency bug: a booking
   made at 22:00 for tomorrow 15:00 does nothing at all until 12:00 the next day.
5. First time a `late` request enters the window, push "Searching for Technician" to the customer and
   set `notificationSent: true`.
6. Re-run eligibility, then **create or renew** an offer for everyone still eligible.

Both auto-assign paths share one implementation — `stageAutoAssignOffers` — so they can no longer
drift apart the way they did in §12.4. Eligibility is §3.2's filter plus `cancelledWorkerUids`, minus
anyone who has already *answered* (see below).

**Offer lifetime differs from the broadcast path, and must.** Auto-assign offers use
`AUTO_ASSIGN_OFFER_TTL_SECONDS` (600 s), not the 120 s `OFFER_TTL_SECONDS` the live broadcast uses,
and each wave **renews the existing offer doc in place** rather than writing a new one. One offer doc
and exactly one push per technician per booking, for the whole search.

> ⚠️ **Why a timeout must not count as a refusal.** The technician app auto-declines an offer when its
> countdown hits zero (`declineJobOffer(autoDeclined: true)` → `status: 'declined'`). The auto-assign
> eligibility filter used to exclude *any* technician whose offer was not `pending`, so wave one handed
> every eligible technician a 120-second offer, each auto-declined itself two minutes later, and every
> one of them was then permanently barred from that booking — the pool burnt out within minutes of a
> search meant to run for three hours, and the booking could never be auto-assigned. `isTimedOutOffer`
> now separates a timeout (`autoDeclined: true`, or `declinedAt ≈ expiresAt` for docs written by older
> builds) from a deliberate decline; only the latter is permanent. This mirrors the reading
> `onManualJobOfferUpdated` already applied when deciding what to tell the customer.
>
> The live-broadcast path keeps the old, stricter semantics via `loadTechniciansWithExistingOffers` —
> a 5-minute window with the customer watching is a different problem, and is intentionally untouched.

**Technician accepts** — because `booking.autoAssignmentStatus != null`, `acceptJobOffer` takes the
transactional branch ([app_services.dart:3140](lib/services/app_services.dart:3140)):
- guards `bookingStatusCode == 'P'`, no other agent, offer still `pending`
- sets booking `A` + `agent` + `assignedAt` + `autoAssignmentStatus: 'accepted'`
- sets this offer `accepted`, mirrors onto `auto-assignment_requests` (`status: 'A'`)
- afterwards, deletes all sibling offers for the booking

CF `syncAgentToAutoAssignment` ([bookingTriggers.js:819](functions/src/triggers/bookingTriggers.js:819)) is a
belt-and-braces mirror for the case where the agent is set by some other route (e.g. admin assign).

**First come, first served** — unlike the broadcast path, the customer never chooses here.

---

### 3.4 Path C — Rebook a specific technician

Entry: customer opens a past technician → `RebookServiceSelection`
([rebook_service_selection.dart](../abo_glumbo_bkk/lib/pages/bookings/rebook_service_selection.dart)), which re-fetches the
technician and shows **only services whose category is in that technician's `jobRoles`**. Selecting a
service opens `BookServicePage(rebookTechnician: tech)`.

At step 2 the wizard renders `RebookWaitWidget` instead of the search UI
([rebook_wait_widget.dart](../abo_glumbo_bkk/lib/pages/bookings/widgets/rebook_wait_widget.dart)):

1. If `technician.isOnline != true` → immediate "Technician is currently offline" screen with a
   "Continue with normal search" button. No request is created.
2. Otherwise uploads media, then `AppServices.broadcastJobRequest` writes a `job_requests` doc **and
   one `job_offers` doc** targeted at that single technician, with `isRebook: true` and
   `expiresAt = now + 120 s`. `isOnHour` is hardcoded `true`.
3. A **120-second countdown** runs client-side. On zero → `onFailed`.
4. `dispose()` / app-detach deletes the request + offers if the technician hasn't responded.

CF `onJobOfferCreatedForRebook` ([bookingTriggers.js:1036](functions/src/triggers/bookingTriggers.js:1036)) pushes
"New Booking Assigned: {service}" to the technician and a "New Booking Request" to **all** admins.

**Technician response:** the customer's accept/decline notification is raised server-side by
`onManualJobOfferUpdated` (rebook branch), which stores it *and* pushes it. It used to be written
straight to `customers/{uid}/notifications` by the technician app, which meant no push at all.
- Accept → offer `accepted_by_technician`; customer's listener fires `onAccepted` and the wizard jumps
  to review. Customer notification "Requested technician has accepted your booking request."
- Decline → `declined`; customer sees the failure screen. Customer notification "Requested technician
  has rejected your booking request." Only a `pending` → `declined` transition without
  `autoDeclined` counts, so the two look-alike transitions stay silent: the technician app's countdown
  auto-declining an offer nobody answered (`autoDeclined: true`, or — for builds predating that flag —
  a decline landing at or after `expiresAt`), and the customer rejecting a counter-offer
  (`counter_offered` → `declined`).
- No response → nothing is sent to the customer.
- Counter-offer → the customer sees an accept/reject card with the proposed time; accepting updates
  `job_requests.bookingDateTime` and carries `_counterProposedTime` into the review step.

**Confirm** → `BookingUtils.saveBooking(..., requestId, rebookTechnicianId)`
([save_booking.dart:33](../abo_glumbo_bkk/lib/services/booking/save_booking.dart:33)). This is the only path that uses
`saveBooking`. It:
- sets `bookingStatusCode: 'A'` + `assignedAt` + `acceptedAt` + `technicianSelectedAt`
- reads `createdAt` back from the originating request so the booking keeps the original timestamp
- marks `job_requests/{id}` → `finalized`, all its offers → `closed`
- notifies technician ("Job Confirmed") and customer ("Technician Booked")

**Failure fallback** (`_buildRebookFailedContent`, [book_service_page.dart:2081](../abo_glumbo_bkk/lib/pages/bookings/book_service_page.dart:2081)):
one button whose behaviour depends on the same matrix — either "Search Available Technicians"
(creates a `booking_request` with the rebook tech in `rejectedTechnicianUids`) or "Proceed to
Auto-Assignment" (puts them in `cancelledWorkerUids`).

---

## 4. Consolidated technician-eligibility comparison

| Rule | Manual broadcast | Auto-instant | Auto-cron (late) | Rebook | Admin assign |
|---|:--:|:--:|:--:|:--:|:--:|
| `role == technician` | ✅ | ✅ | ✅ | n/a (targeted) | ⚠️ `isAdmin != true` only |
| `isOnline == true` | ✅ | ✅ | ✅ | ✅ pre-check | ✅ `isOnline != false` |
| `isVerified == true` | ✅ | ✅ | ✅ | ❌ not checked | ✅ |
| Job role matches `service.category` | ✅ | ✅ | ✅ | ✅ (service list is filtered) | ✅ via `jobRoles arrayContains` |
| Has coordinates | ✅ | ✅ | ✅ | ❌ | ✅ if a zone/nearby filter is on |
| Distance ≤ 20 km | ✅ | ✅ | ✅ | ❌ | ⚠️ opt-in "nearby" toggle |
| No job already started | ✅ | ✅ | ✅ | ❌ | ❌ |
| No same-instant booking | ✅ | ✅ | ❌ (computed, unused) | ❌ | ✅ via `ConflictCheckService` |
| Excludes previous decliners | ✅ `rejectedTechnicians` | ✅ `cancelledWorkerUids` | ✅ both | n/a | ⚠️ warn-only dialog |
| Excludes already-offered | ❌ | ✅ | ✅ | n/a | n/a |

Coordinate resolution order — customer: `selectedAddressId` → `isSelected == true` → `addresses[0]`
([bookingUtils.js:4](functions/src/utils/bookingUtils.js:4)); technician: `liveLocation` →
`lastKnownLocation` → `last_known_location` ([bookingUtils.js:46](functions/src/utils/bookingUtils.js:46)). Both
tolerate `lat`/`latitude` and `lon`/`longitude` spellings and string-typed numbers.

**Admin manual assignment** ([assign_worker.dart](lib/sheets/assign_worker.dart)) is deliberately the loosest path
— admins can override an existing assignment ("Change Technician"), and conflicts surface as a
confirmation dialog rather than a hard block. `ConflictCheckService`
([conflict_check_services.dart](lib/services/conflict_check_services.dart)) batches `P`/`A` bookings for the
candidate list (10-uid `whereIn` chunks, 2-minute cache) and flags exact-minute collisions,
previously-cancelled workers, and same-session double-assignments. The write itself is
`AdminBloc._assignAgent` → `agent` + `bookingStatusCode: 'A'` + `acceptedAt`, clearing `cancelledBy`.

---

## 5. Technician location & availability

- `TechnicianLocationUpdateService` writes `liveLocation{latitude,longitude,timestamp,accuracy,altitude,heading,speed}`,
  `last_known_location` (GeoPoint), `geohash`, and reverse-geocoded `location.{city,province,street,fullAddress}`
  ([technician_location_update_service.dart:136](lib/services/technician_location_update_service.dart:136)). It tries
  `getLastKnownPosition()` first for a fast write, then a fresh high-accuracy fix (15 s cap). Admins are skipped.
- `isOnline` is a manual toggle on the technician dashboard ([dashboard.dart:872](lib/pages/home/worker/dashboard.dart:872)).
  **It is the hard gate for every automated assignment path** — an offline technician receives nothing.
- `geohash` is written but never queried; all distance filtering is full-collection scan + Haversine.

---

## 6. Post-assignment job lifecycle

```
A (assigned)
 ├─ technician taps Start   → trackingStartedAt, isStarted=true, live tracking begins
 │                            (BookingBloc.StartWorkingOnBooking + background_fetch)
 ├─ pause / stop tracking   → isTrackingPaused, trackingStoppedAt
 ├─ arrival                 → arrivedAt   (CF notifyCustomerWhenTechnicianIsNearby)
 └─ technician completes    → CP
                              completionData{fileUrls, serviceCost, serviceItems,
                                             totalCost, inspectionFee, mode}
                              mode = 1 if "service completed", 0 if inspection-only
                              paymentRequestedAt set, paymentCompleted=false
CP
 └─ customer uploads proof  → VP  (paymentProof[], paidAmount, transactionId, paidAt)
VP
 └─ technician verifies     → C   (technicianPaymentProof[], paymentCompleted=true,
                                   paymentVerifiedAt) + transactions record + invoice id
                                   `{newBookingId|id}_{customerUid}`
C + paymentCompleted + mode==1
 └─ CF attachWarrantyOnPaymentCompletion → warranty{status 'A', expiredOn = +7 days}
```

`mode` comes from a single toggle in the completion sheet ([complete_work_bottom_sheet.dart:659](lib/pages/bookings/widgets/complete_work_bottom_sheet.dart:659)):
`_serviceCompleted ? 1 : 0`. **Only `mode == 1` earns a warranty** — inspection-only jobs get none.

Card payments go through Telr (`lib/apis/telr_services.dart`, `telr_apple_pay.dart`) and set
`paymentModeCode` `C`/`A`; `O` (outside app / cash) routes to `VP` instead of `C`
([save_booking.dart:330](../abo_glumbo_bkk/lib/services/booking/save_booking.dart:330)).

Invoices are generated client-side as PDFs (`InvoiceService`, `pw.Document`) and cached to
`booking.invoicePdfUrl`.

---

## 7. Cancellation & re-routing

| Who | Effect |
|---|---|
| **Technician** (`AppServices.cancelBooking`, [app_services.dart:1295](lib/services/app_services.dart:1295)) | appends to `cancelledWorkers[]` + `cancelledWorkerUids[]`, deletes `agent` and `acceptedAt`, status → `P`, `cancelledBy: 'worker'` |
| **Customer** (`AppServices.cancelBooking`, [app_services.dart:560](../abo_glumbo_bkk/lib/services/app_services.dart:560)) | status → `XC` + `cancellationReason` |
| **Admin** (`RejectOrderEvent`) | status → `R`, `rejectedBy: 'Admin'` — *unless* a warranty claim is in `R`, in which case it rejects the warranty (`X`) instead |

After a technician cancels, CF `notifyAdminsOnWorkerCancellation` ([index.js:1644](functions/index.js:1644))
**recreates an `auto-assignment_requests` doc** for the booking (carrying `cancelledWorkerUids`
forward) and sets `autoAssignmentStatus: 'ready_to_assign'` — so a cancelled job automatically
re-enters the auto-assign cron regardless of which path originally created it.

`fallbackToGeneralSearch` ([app_services.dart:1848](../abo_glumbo_bkk/lib/services/app_services.dart:1848)) is the rebook
equivalent: nulls `rebookTechnicianId` and `agent`, status → `P`, expires pending offers.

---

## 8. Warranty workflow

Warranty is a sub-document of the booking, never a separate collection.

```
booking reaches C + paymentCompleted + completionData.mode == 1
        ↓  CF attachWarrantyOnPaymentCompletion (index.js:3560)
warranty { status 'A', assignedTechnicianId = original agent, expiredOn = now + 7 days }

customer claims  (AppServices.requestWarrantyRepair, customer app:1371)
        ↓  status 'R', availability=true, assignedTechnicianId/assignedTechnician = original agent,
           requestedOn set
        ↓
   ┌────────────────────────────┬──────────────────────────────┬────────────────────────┐
technician accepts          technician rejects              admin rejects
 status 'S'                  clears assignedTechnician        status 'X', availability=false
 acceptedAt                  (RejectWarranty — status         (AdminRejectWarranty)
                              left unchanged)
                             or CancelWarranty →
                               expired?  'E'  :  back to 'R'
                               + rejectedTechnicians[] entry
        ↓
technician works: StartWorkingOnWarranty → keeps 'S', starts warranty tracking
        ↓
CompleteWarranty → 'C', availability=false, completedAt,
                   totalCost/serviceCost/inspectionFee forced to 0  ← zero-fee enforcement
```

**Reassignment:** admin picks a new technician via `AssignWarrantyTechnician`
([warranty_bloc.dart:236](lib/pages/bookings/bloc/warranty_bloc.dart:236)) — writes the full `UserModel`,
sets status back to `R`, `availability: false`, deletes `rejectedAt`, and **deletes `chatroomId`** so
the new technician gets a fresh chat. Every warranty state change that detaches a technician also
clears `chatroomId`.

**Technician's warranty inbox** ([app_services.dart:2443](lib/services/app_services.dart:2443)) shows warranties
where status is `R` or `S`, the technician is the assignee, and they are **not** in
`rejectedTechnicians[]`.

**Expiry:** `expireWarrantiesDaily` ([index.js:4511](functions/index.js:4511)) and
`expireUnchangedWarranties` ([index.js:2854](functions/index.js:2854)) are scheduled sweeps.

**Escalation:** customers can escalate an unresolved claim (`isEscalated`, `escalatedAt`) →
CF `notifyAdminsOnWarrantyEscalation`; admin resolves with `resolutionText`/`resolvedAt` →
CF `notifyCustomerOnWarrantyResolution`.

---

## 9. Counter-offer (time renegotiation)

Technician proposes a new time (`app_services.dart:2790`):
1. `job_offers/{id}` → `status: 'counter_offered'`, `proposedTime`, `counterOfferedBy`
2. New `counter_offers/{autoId}` doc (this is what CF `notifyOnCounterOfferCreated` watches)
3. `activeCounterOffer` written onto whichever of `bookings` / `job_requests` / `booking_request`
   actually holds the id (tried in that order), plus `counterProposalStartedAt` on first proposal

Customer accepts → offer `accepted_by_customer`, request `bookingDateTime` updated, and the wizard
carries `_counterProposedTime` into the final booking. Customer declines → offer `declined`.

`counterProposalAcceptedAt` / `counterProposalStartedAt` exist on the booking model for SLA tracking.

---

## 10. Human-readable booking ids

CF `assignNewBookingIdHelper` ([bookingTriggers.js:1126](functions/src/triggers/bookingTriggers.js:1126)) runs on create for
`bookings`, `job_requests`, `booking_request`, and `auto-assignment_requests`. It first tries to
**carry over** an existing `newBookingId` from the source doc (so a request → booking transition keeps
one id), otherwise mints `AG-YYMMDD-NNNN` from a Firestore transaction on `counters/daily_booking_id`.
Date is **UTC**.

---

## 11. Notifications

All notifications go through the single `sendAndStoreNotification` in
[bookingUtils.js](functions/src/utils/bookingUtils.js): writes to `<customers|users|admins>/{id}/notifications`
**and** sends FCM. `index.js` imports it; it used to keep a second copy, and the two drifted into
writing different field names (`isRead` vs `read`) and building different FCM payloads.

Role → collection is fixed: `technician` → `users`, `customer` → `customers`, `admin` → `admins`.
Every profile lookup in the trigger layer must follow it; a mismatch fails silently, because a missing
document just reads as "no FCM token".

De-duplication is an **idempotency key**, not a content match: the notification's document id is
derived from the event (`scope__entityId__status__targetRole__hash(titleEn)`) and written with
`create()`. Entity precedence is `messageId → offerId → payoutId → walletId → requestId → bookingId →
chatId`, most specific first — `messageId` before `bookingId` or a whole chat collapses into one
notification; `offerId` before `bookingId` or a re-broadcast of an expired offer reads as a duplicate.
No usable identifier means no dedup, so a real notification is never suppressed by accident.

Payloads are trilingual (`en` / `ar` / `ur`); the FCM title/body is picked by the recipient's `lanCode`
with `ur → ar → en` fallback. All 50 call sites supply all six fields — before, several supplied only
`en`/`ar`, so Urdu users silently received Arabic.

Money in notification bodies goes through `money(amount, lang)`, which renders Saudi riyal as
`SAR` / `ر.س` / `سعودی ریال`. Any other currency marker in a notification body is a bug.

~50 Cloud Functions in `index.js` cover: new-booking alerts to admins, assignment alerts, status
changes, payment completion/verification, cancellation (worker & customer, to both admins and the
other party), warranty request/escalation/resolution/assignment, counter-offers, chat messages (RTDB
`onValueCreated`), payout requests and status changes, tip payouts, technician registration
approval/rejection/resubmission, nearby-arrival alerts, monthly tier resets and bonuses, rating
recalculation, and media/chat cleanup crons.

---

## 12. Findings — discrepancies, dead code, and risks

> **Status:** all of §12 has now been **resolved**; see §14 and §15 for the change logs. The text of
> each finding is kept as the record of what was wrong.

### 12.1 Documented decision matrix ≠ implemented one — ✅ RESOLVED (docs corrected)
The **code was correct**: any "service for later" booking placed during off hours goes to
auto-assignment, and anything placed during working hours goes to live broadcast, regardless of the
requested date. The stale docstring claiming a "Today vs Future Date" split has been rewritten to
describe the actual, intended rule
([book_service_page.dart:2520](../abo_glumbo_bkk/lib/pages/bookings/book_service_page.dart:2520)).

### 12.2 `SR` is a phantom status — ✅ RESOLVED (reads deleted)
Read in 5 places (booking tiles, booking-state grouping, details page, the auto-assign cron guard) but
**written nowhere**. `index.js:1771` even carries the comment "set … status = 'SR' (Searching/Re-Routing)"
directly above a line that writes `"P"`. Either wire it up or delete the reads.

### 12.3 Two Cloud Functions are defined but never exported — ✅ RESOLVED
`onBookingWarrantyUpdated` ([bookingTriggers.js:1201](functions/src/triggers/bookingTriggers.js:1201)) and
`cleanupStaleBookingRequests` ([bookingTriggers.js:1384](functions/src/triggers/bookingTriggers.js:1384)) are not in the
`exports.*` list at [index.js:5386-5394](functions/index.js:5386). Consequences:
- **No warranty accept/reject/reassign notifications are being delivered** from that trigger. (Some
  overlap exists via `notifyOnWarrantyRequestStatusChange` / `notifyTechnicianOnWarrantyAssignment` in
  `index.js`, so verify what's actually covered before adding it.)
- **Stale `booking_request` docs are never closed server-side.** The only cleanup is the customer's
  5-minute client timer, which dies with the app. Abandoned requests accumulate as `searching` forever
  and keep showing on the admin dashboard's pending count.

### 12.4 Time-conflict check silently skipped in the auto-assign cron — ✅ RESOLVED
`processAutoAssignments` declares `hasTimeConflict` and computes `reqBookingTime`, but the loop only
`break`s on `hasStartedJob` and never tests the conflict
([bookingTriggers.js:520-540](functions/src/triggers/bookingTriggers.js:520)). The instant path
([bookingTriggers.js:733](functions/src/triggers/bookingTriggers.js:733)) and the manual path do enforce it. Net effect: a
technician can be offered two `late` auto-assign bookings for the exact same minute.

### 12.5 Timezone inconsistency in the on/off-hour gate — ✅ RESOLVED
`_getMiddleEastNow()` was a no-op returning `DateTime.now()`, so despite the name there was no
timezone normalisation anywhere; some paths called it and others called `DateTime.now()` directly.

A single `KsaTime` helper is now the source of truth in both apps
([time_service.dart](lib/services/time_service.dart)). Saudi Arabia is permanently UTC+3 and has never
observed DST, so a fixed offset is exact — no timezone database needed. It distinguishes the two
kinds of value that flow through the booking code:

- **KSA wall clock** (`KsaTime.now`, `KsaTime.today`) — what the user picks and sees. Returned as a
  local-flagged `DateTime` carrying KSA field values so it composes correctly with
  `DateTime(y, m, d, slot.hour, slot.minute)` built from picker output.
- **Instant** (`KsaTime.toInstant` / `KsaTime.fromInstant`) — the absolute point in time written to
  Firestore.

Wired through `_getMiddleEastNow()`, `_isCurrentTimeOffHour()`, `ServiceModel._getMiddleEastNow()`
(both apps), every `bookingDateTime` write in `save_booking.dart`, the rebook request, and the
`assignmentScheduledTime` / `isInstant` comparisons. On a device already set to Riyadh time every
helper is a no-op, so nothing changes for the overwhelming majority of users; it only bites on a
device set to another zone, which is exactly the case that used to silently shift bookings and
pricing bands.

> Remaining nuance: **display** formatting still renders `Timestamp.toDate()` in device-local time.
> That is correct on a KSA device. If out-of-country display accuracy is ever needed, route those
> `DateFormat` calls through `KsaTime.fromInstant` — the helper is already there.

### 12.6 Notification de-duplication is unbounded — ✅ RESOLVED
The dedup query in `sendAndStoreNotification` had no time bound. Two legitimately separate events that
produce identical `titleEn`/`bodyEn` for the same recipient (e.g. "You have been assigned to a booking."
with no `requestId` in `data`) silently dropped the second one permanently.

**Resolution:** content-matching was replaced with an idempotency key (`buildDedupeKey`). The
notification's Firestore document id is derived from the *event* — scope, entity id, status, recipient
role, plus a hash of `titleEn` as a tie-breaker — and written with `create()`, which is a
compare-and-set. This is race-proof (the old read-then-write let two concurrent invocations both pass),
needs no composite index, and cannot suppress a genuinely different event. When the payload carries no
identifier to key on, the notification is stored without dedup rather than risking a false suppression.

The underlying cause was never the text: two triggers on the same document reacting to one write. See
§12.12.

### 12.7 Rebook path skips most eligibility checks — ✅ RESOLVED
`RebookWaitWidget` now re-reads the technician from Firestore before broadcasting, because the
`UserModel` it receives was loaded on an earlier screen and can be minutes stale
([rebook_wait_widget.dart](../abo_glumbo_bkk/lib/pages/bookings/widgets/rebook_wait_widget.dart)). It applies the
same gate the Cloud Functions apply to every automated path — `isVerified` **and** `isOnline` — and
short-circuits to an explanatory screen instead of creating a request nobody can answer:

| Situation | Screen |
|---|---|
| Not verified / account gone | "This technician is not available for booking right now" |
| Verified but offline | "Technician is currently offline" |
| Verified + online | normal 120 s wait, with accept / decline / counter-offer |

All four outcomes end on the same **"Continue with normal search"** action, which hands back to
`_buildRebookFailedContent` and re-enters the standard assignment-type decision (§3.1) — broadcast
during working hours, auto-assign during off hours — with the rebook technician excluded. Distance and
started-job checks are deliberately *not* applied: a rebook is a direct request to a specific person,
and the technician answers for themselves via decline or counter-offer.

### 12.8 O(n) fan-out queries — ✅ RESOLVED
Two shared helpers were added to
[bookingTriggers.js](functions/src/triggers/bookingTriggers.js): `loadActiveAgentSchedules()` reads every
`bookingStatusCode == 'A'` booking **once** and indexes started jobs and taken booking instants by
agent uid; `loadTechniciansWithExistingOffers()` centralises the duplicate-offer lookup. All three
assignment paths now consult those in-memory indexes instead of issuing one `bookings` query per
candidate technician. In the cron the schedule index is loaded **once per run** rather than once per
request — offers do not themselves assign anyone, so a per-run snapshot yields identical eligibility
answers. Reads per pass drop from `O(requests × technicians)` to `O(requests)`.

`onManualJobOfferUpdated` was the worst offender: it fetched **every booking a technician had ever
had** on each acceptance. Rating now comes from the stored aggregates (see 12.9) and completed jobs
from a server-side `count()` aggregation, with a fallback to the original scan if the composite index
on `(agent.uid, bookingStatusCode, paymentCompleted)` is not present yet — so it is fast once the
index exists and correct either way.

On the customer side `getWorkerRating` no longer opens a live query over the whole `bookings`
collection per worker; it reads the worker's `users` document instead.

> Not changed: `getCompletedJobsByWorkerId` still opens one live query per worker. Fixing it properly
> needs a lifetime completed-jobs counter on the user doc (`currentMonthJobs` resets monthly), which is
> a data-model change rather than a refactor.

### 12.9 Rating arithmetic is inconsistent — ✅ RESOLVED
The canonical model is now stated once and used everywhere: **`users.rating` is the running SUM of
review scores and `users.reviewCount` is the number of rated jobs**; the displayable value is
`rating / reviewCount`. `updateTechnicianRatingOnReview` ([index.js:5026](functions/index.js:5026)) is the
sole writer — it is transactional and already handles new, edited and deleted reviews.

Fixed:
- **Customer `saveReview` no longer touches `users.rating`.** It was adding to the sum without
  incrementing `reviewCount`, double-counting against the Cloud Function and making every derived
  average drift upward.
- **`onManualJobOfferUpdated`** derives the average from the stored aggregates instead of being a
  third, independent implementation.
- **`getWorkerRating`** returned the **average** under the `'rating'` key while `WorkerCard` divided it
  by the review count a *second* time — a technician averaging 5.0 across 4 reviews displayed as 1.25
  stars. It now returns the sum, matching the field semantics, so the call site is correct.
- **`worker_list` sorting** switched to `WorkerWithStats.averageRating`; sorting by the raw sum would
  have ranked high-volume technicians above high-rated ones.
- `UserModel.averageRating` added in both apps (plus the missing `reviewCount` field on the customer
  side) as the single accessor for display.

> ⚠️ **Data note:** technicians who accumulated reviews while the double-counting bug was live have an
> inflated `rating` sum. New reviews are now correct, but a one-time backfill recomputing
> `rating`/`reviewCount` from `bookings.review` would be needed to clean up historical values.

### 12.10 Broadcast offers don't exclude already-offered technicians — ✅ RESOLVED
`onBookingRequestCreated` now calls the same `loadTechniciansWithExistingOffers()` guard the
auto-assign paths use, and skips anyone holding a live pending offer or who has already responded.
This closes the "Search again" gap, where a new request id previously let a technician who had just
declined be re-notified whenever the client-side `rejectedTechnicians` carry-forward didn't happen.
It is a pure filter addition — no eligible technician who would have been offered before is excluded now.

### 12.11 Non-atomic request→booking conversion — ✅ RESOLVED
Both conversion sites — `_selectTechnician`
([searching_technicians_screen.dart](../abo_glumbo_bkk/lib/pages/bookings/searching_technicians_screen.dart)) and the
in-wizard variant ([book_service_page.dart](../abo_glumbo_bkk/lib/pages/bookings/book_service_page.dart)) — now
commit the `bookings.set()` and the `booking_request.delete()` in a single `WriteBatch`, so a crash or
network drop can no longer leave a live request sitting next to a confirmed booking.

The concurrent-selection half of the finding is **not** guarded, by design: the product assumes one
account is used from one device at a time, so two devices racing to select different technicians for
the same request is out of scope. The batch makes each individual conversion all-or-nothing, which is
the part that could bite a single user.

### 12.12 Overlapping notification triggers — ✅ RESOLVED
A full audit of all 39 notifying triggers (50 emission sites) found **three** cases where two triggers
watching the same document both reacted to a single write. Because the two messages differ in wording
and payload, no content-based dedup could ever have caught them — this was the real source of the
"two notifications for one action" reports.

| Event | Triggers | Resolution |
|---|---|---|
| Warranty technician cancels | `notifyOnWarrantyStatusChange` (S→R) + `onBookingWarrantyUpdated` (`assignedTechnicianId` cleared) — a cancel does both in one write | `onBookingWarrantyUpdated` defers when the status also moved S→R; its branch still covers an assignment cleared *without* that transition |
| Card tip payout processed | `notifyWorkerOnTipPayoutProcessed` + `notifyTechnicianOnTipPayoutCompletion` on the same `tipping` doc; the second's condition is a strict subset of the first's | the broader one defers when `cardtip` was cleared |
| Technician accepts a job offer | `notifyCustomerOnBroadcastAccepted` + `onManualJobOfferUpdated`, same `status → accepted_by_technician` transition | `notifyCustomerOnBroadcastAccepted` **removed** — it looked the customer up in `users` instead of `customers`, so it had never delivered anything; repairing it would only have produced the duplicate |

Five further suspects were checked and cleared: new-booking vs assignment (mutually exclusive `P`/`A`),
the auto-assign cron vs `onAutoAssignmentRequestCreated` (the cron skips `techsWithOffers`), warranty
accept → technician (`warranty_accepted` has no `technician` entry in `statusMessages`), warranty
resolution (keys on `isEscalated`, not `warrantyStatusCode`), and the two registration triggers.

**Still open:** `payouts` and `unified_payout_requests` are parallel systems, each with its own
admin-notify and technician-notify trigger, and both are still written from the app
([app_services.dart:1860](lib/services/app_services.dart:1860) and
[unified_payout_services.dart:241](lib/services/unified_payout_services.dart:241)). They are disjoint at
the trigger level today — unified approve touches `unified_wallets`, the legacy path touches `tipping` —
so there is no duplicate, but the legacy triggers are notifications for a superseded flow.

---

## 13. Quick file map

**Customer app (`abo_glumbo_bkk`)**
| Concern | File |
|---|---|
| Booking wizard + decision matrix | `lib/pages/bookings/book_service_page.dart` |
| Request/booking writers | `lib/services/booking/save_booking.dart` |
| Broadcast/rebook/offer services | `lib/services/app_services.dart` (≈1500-1880) |
| Technician selection UI | `searching_technicians_screen.dart`, `widgets/embedded_technician_search.dart` |
| Rebook wait + counter-offer UI | `widgets/rebook_wait_widget.dart` |
| Rebook service picker | `rebook_service_selection.dart` |
| Zone validation | `lib/services/location_matcher_service.dart` |
| Payment | `lib/apis/telr_*.dart`, `lib/sheets/upload_payment_proof_sheet.dart` |

**Technician/Admin app (`abo_glumbo_technician_bbk`)**
| Concern | File |
|---|---|
| Cloud Functions — assignment engine | `functions/src/triggers/bookingTriggers.js` |
| Cloud Functions — notifications etc. | `functions/index.js` |
| Shared CF helpers | `functions/src/utils/bookingUtils.js` |
| Offer stream / accept / decline / counter | `lib/services/app_services.dart` (2790-3290) |
| Offer card UI | `lib/pages/bookings/broadcast_offer_info.dart` |
| Job lifecycle | `lib/pages/bookings/bloc/booking_bloc.dart`, `booking_info.dart` |
| Warranty lifecycle | `lib/pages/bookings/bloc/warranty_bloc.dart`, `warranty_page.dart` |
| Admin assign + conflicts | `lib/sheets/assign_worker.dart`, `lib/services/conflict_check_services.dart` |
| Admin assign write | `lib/pages/home/admin/bloc/admin_bloc.dart` |
| Location/availability | `lib/services/technician_location_update_service.dart`, `lib/pages/home/worker/dashboard.dart` |
| KSA clock helper | `lib/services/time_service.dart` (mirrored in both apps) |

---

## 14. Change log

Applied 2026-07-29 in response to review of §12. Both apps pass `flutter analyze` with no new issues;
`functions/` passes `node --check`.

| Finding | Change | Files |
|---|---|---|
| 12.1 | Docstring rewritten to match the intended rule (off-hours "later" → auto-assign) | `book_service_page.dart` |
| 12.5 | New `KsaTime` helper (UTC+3, no DST); wired into all booking decision + creation paths in both apps | `time_service.dart` ×2, `service.dart` ×2, `book_service_page.dart`, `save_booking.dart`, `rebook_wait_widget.dart` |
| 12.7 | Rebook re-reads the technician live and gates on `isVerified` + `isOnline`, with distinct outcome screens; all failures fall back to the standard assignment-type logic | `rebook_wait_widget.dart` |
| 12.8 | `loadActiveAgentSchedules()` + `loadTechniciansWithExistingOffers()` replace per-technician queries; cron loads the index once per run; `count()` aggregation (with scan fallback) for completed jobs; `getWorkerRating` reads the user doc | `bookingTriggers.js`, `app_services.dart` (customer) |
| 12.9 | Cloud Function is the sole writer of rating aggregates; client mutation removed; sum-vs-average confusion fixed at every call site; `averageRating` getters added | `save_booking.dart`, `bookingTriggers.js`, `app_services.dart`, `user.dart` ×2, `worker_card.dart`, `worker_list.dart`, `agent_info.dart` |
| 12.10 | Duplicate-offer guard added to the manual broadcast path | `bookingTriggers.js` |
| 12.11 | Both request→booking conversions moved into a single `WriteBatch` | `searching_technicians_screen.dart`, `book_service_page.dart` |

---

## 15. Change log — second pass

Applied 2026-07-29. Both apps pass `flutter analyze` with no new issues; `functions/` passes
`node --check`.

### 15.1 Remaining §12 findings

| Finding | Change | Files |
|---|---|---|
| 12.2 | `SR` deleted rather than wired up. Every read was provably a no-op (it is written nowhere), and enabling it would have broken auto-assign acceptance — `acceptJobOffer`'s transactional guard requires exactly `'P'`, so a booking parked in `SR` could never be accepted. The comment at `index.js` that claimed to write `SR` now describes what the line actually does. | `booking_cards.dart`, `booking_info.dart`, `admin_home.dart`, `app_services.dart`, `service_booking_tile.dart`, `booking_state.dart`, `booking_details_page.dart`, `index.js`, `bookingTriggers.js` |
| 12.3 | Both triggers exported. `onBookingWarrantyUpdated` was first reduced to the one case index.js does **not** cover — a technician leaving a claim (`S → R`, which matches none of `notifyOnWarrantyRequestStatusChange`'s branches). Its acceptance, admin-rejection and assignment branches duplicated existing functions and would have sent every one of those twice. | `index.js`, `bookingTriggers.js` |
| 12.4 | The cron now applies the same-instant conflict rule. It already loaded the schedule index and computed nothing from the booked-instants half; that half is now destructured and tested, matching the instant and manual paths. | `bookingTriggers.js` |
| 12.6 | Dedup is bounded to a 15-minute window. Long enough to absorb retries and double-firing triggers — its actual purpose — short enough that two genuinely separate events producing identical text (e.g. "You have been assigned to a booking.", which carries no `requestId`) both reach the recipient. Filtered in memory over the same query, so no new composite index is needed. | `bookingUtils.js` |

### 15.2 KSA time as the display standard

§12.5 made *writes* KSA-correct but left display rendering `Timestamp.toDate()` in device-local time.
Saudi time is now the standard end to end:

- **Formatting is converted at the helper, not the call site.** `formatBookingDateTime`,
  `formatDateTimeDay`, `formatDateTime` ([date_formatter.dart](lib/helpers/date_formatter.dart), both
  apps), `formatDateLocalized` and `formatDateTimeCompact`
  ([localization_helper.dart](lib/helpers/localization_helper.dart), and `timeline.dart` on the
  customer side) take an absolute instant and render the KSA wall clock. Every existing call site
  already passed `Timestamp.toDate()`, so no caller had to change.
- **Direct `DateFormat` sites** routed through `KsaTime.fromInstant`: booking cards, broadcast offer
  details, payout lists, transaction tiles, the unified wallet, notification lists, invoices, and both
  chat screens.
- **Elapsed-time text is untouched.** "3 days ago" compares two instants and is zone-independent by
  construction; only the absolute fallback each of those functions falls through to is converted.
- **Chat day boundaries** follow the Saudi calendar, so "Today"/"Yesterday" separators agree with the
  timestamps under them.
- **"Service Now" no longer reads the device clock.** The slot was built as
  `{"label": "Now", "time": TimeOfDay.now()}` and then combined with a KSA-derived date, so a booking
  placed from India was stamped with a KSA date and an Indian time. It now uses
  `TimeOfDay.fromDateTime(KsaTime.now)`.
- **The date picker** is bounded by `KsaTime.today` rather than `DateTime.now()`; on a device behind
  KSA the local date can still be "yesterday" there, which offered an already-past day.
- **Invoice issue date** uses `KsaTime.now`.

### 15.2b The rule, and the audit against it

**A KSA device behaves exactly as it always did; every other device converts.**
`KsaTime.fromInstant` and `toInstant` are identity operations at UTC+3, so on a phone set to Riyadh
nothing changes at all — the time slots, the picker and the on/off-hour band are the device clock,
because the device clock *is* the Saudi clock. Off KSA, the same code paths convert. Verified
numerically on a UTC+5:30 machine: a 10:00 KSA pick stores as 07:00Z and reads back as 10:00 for every
reader, in January and July alike (KSA has no DST, so the fixed offset is exact).

Two kinds of value flow through the code and they must never be compared with each other:

| | Produced by | Compare against | Convert with |
|---|---|---|---|
| **KSA wall clock** | `KsaTime.now`, `KsaTime.today`, date/time pickers, the slot grid | other wall-clock values | `toInstant` on the way to Firestore |
| **Instant** | `Timestamp.toDate()`, `TimeService.now`, `DateTime.now()` | other instants (durations are zone-independent) | `fromInstant` on the way to the screen |

The whole codebase was swept against that rule. What it turned up:

| Site | Problem | Fix |
|---|---|---|
| `worker_list.dart` ×2 | The "busy at this time" query built a wall clock from the slot picker and matched it against `bookings.bookingDateTime`, which stores instants. Off KSA the equality matched nothing, so the busy indicator silently showed everyone as free. | Query converted with `toInstant` |
| `worker_list.dart` | The broadcast request wrote `bookingDateTime` raw. Every other writer converts, and the Cloud Functions compare it against instants from `bookings`, so the same-instant conflict rule compared two different clocks. | Converted |
| `counter_propose_sheet.dart` | A technician's counter-proposed time was stored straight from the picker, and the sheet was seeded, bounded and validated against `DateTime.now()`. | Whole sheet on the KSA clock; submitted value converted |
| `period_selector.dart` | The admin's calendar decided "today" and which days are future from the device, so an admin outside KSA saw the wrong day greyed out. | `KsaTime.now` / `KsaTime.today` |
| `admin_dashboard.dart` | Custom revenue range `lastDate` was the device's today. | `KsaTime.today` |
| `assignNewBookingIdHelper` | `AG-YYMMDD-NNNN` derived the date in **UTC**, three hours behind Riyadh, so every booking placed between midnight and 03:00 KSA was stamped with the previous day *and* counted against the previous day's sequence — against the stated rule that the first booking of 22 June is `AG-260622-0001`. | Date derived at UTC+3 |
| `cleanupIssueMedia`, `scheduledChatCleanup` | The only two crons without a timezone; the other four already pinned `Asia/Riyadh`. | Pinned |
| `chat_screen.dart` | **Introduced during 15.2**: the date separator converted `date` and then converted it again when formatting. | Converted once |
| `chat/chat.dart` (customer) | The separator compared device-local days but formatted the KSA date, so a "Today" label could disagree with the dates around it. | Both on the KSA calendar |

A second sweep, driven by "validate everything", found more:

| Site | Problem | Fix |
|---|---|---|
| `book_service_page.dart` | **Double conversion.** A technician's counter-proposed time arrives as an instant (`Timestamp.toDate()`) and was stored in `_counterProposedTime`, which the wizard treats as a wall clock and hands to `saveBooking` — which converts it *again*. A counter-offer accepted outside KSA was saved at the wrong time. | Converted once, at the point it enters the wizard |
| `searching_technicians_screen.dart` | The counter-offer card rendered the proposed time device-local, and the booking-completed page was handed a raw instant where every other caller passes a wall clock. | Both converted |
| `payment_success.dart` | The confirmed booking time rendered device-local. | Converted |
| `booking_success.dart` | "Booked on" date and time came from `DateTime.now()`. | `KsaTime.now` |
| `getAdminDashboardStream` | The revenue chart built its day/month bucket **keys** from the device clock and labelled each booking's payment date with the device clock too. Internally consistent, but an admin abroad saw revenue attributed to the wrong Saudi day. | Keys and labels both on the KSA calendar |
| `stat_services.dart` | The monthly jobs/rating window used device-local month boundaries against stored instants. | Saudi month |
| `manage_agents.dart`, `manage_transactions.dart` | "This month" and the date-range bounds came from the device. | `KsaTime.now` |
| `dashboard.dart`, `unified_wallet_page.dart` | The "today" header dates were device-local. | `KsaTime.now` |

Deliberately left alone: elapsed-time text ("3 days ago", offer countdowns, the broadcast timer) compares
two instants and is correct in any zone; upload filenames built from `DateTime.now().millisecondsSinceEpoch`
are identifiers, not times; `ConflictCheckService`'s cache TTL is a local duration; and
`book_service_page`'s own date chip formats `selectedDate`, which is already a wall clock.

### 15.3 Bug fixes

| Area | Change | Files |
|---|---|---|
| Admin dashboard | `Total Revenue` was a hardcoded English string and the amount had no currency. Now localised (en/ar/ur) with the amount through `sarAmount`. | `admin_dashboard.dart`, `app_*.arb` |
| Warranty timeline | Added **Complaint Submitted** (`escalatedAt`) and **Complaint Resolved by Admin** (`resolvedAt`, described with the admin's own `resolutionText`), plus a **Technician Assigned / New Technician Assigned** entry so the timeline continues through to completion after a reassignment. `escalatedAt`, `resolutionText` and `resolvedAt` were missing from the technician-app `BookingModel` entirely; `warranty.assignedAt` is new. | `booking_info.dart`, `booking.dart`, `warranty.dart`, `warranty_bloc.dart`, `app_*.arb` |
| Warranty assignment | `AssignWarrantyTechnician` stamped `warranty.acceptedAt` at assignment time, fabricating an acceptance that had not happened and showing "Warranty Repair Accepted" the moment an admin assigned. It now writes `assignedAt` and clears any inherited `acceptedAt`; the pending state reads "waiting for acceptance" instead of "waiting for admin to reassign". | `warranty_bloc.dart`, `booking_info.dart` |
| Admin warranty reject | The assign sheet dispatched `RejectWarranty` — the *technician's* "not me" action, which only detaches the assignee and deliberately leaves the status alone. The claim stayed in the Requested tab and admins could press Reject indefinitely with no effect. Now dispatches `AdminRejectWarranty`. The details-page reject was also aligned with it (availability, assignee and chatroom cleared). | `warranty_page.dart`, `booking_info.dart` |
| Technician dashboard | The pending-payment counter queried `C` + `paymentCompleted == false` — a combination that essentially never exists. It now mirrors the "Payment Pending" tab exactly: `CP` **and** `VP`. | `app_services.dart` |
| Unified wallet | Booking earnings are now credited by a single Cloud Function, `creditTechnicianWalletOnPaymentCompletion`, keyed on booking *state* and made exactly-once by a `walletCreditedAt` marker written in the same transaction. It replaces three partial client credits: the customer app credited in-app earnings (double-counting against the Cloud Function that already did, and on a different basis — `serviceCost + inspectionFee` vs `totalCost` everywhere else), and the technician app credited outside-app earnings from the possibly-stale `BookingModel` the verify-payment sheet had loaded, skipping silently whenever `completionData` was absent from that copy. Being server-side and state-keyed, it is independent of which of the three creation paths produced the booking. | `index.js`, `verify_payment_sheet.dart`, `processing_payment_page.dart` |
| Cancelled searches | `AppServices.cancelTechnicianSearch` deletes the offers **and** the request document from whichever collection holds it. A rebook request lives in `job_requests`, but every cancel path deleted only `booking_request`, so a search the customer had already cancelled stayed live on the admin dashboard as a view-only pending item. | `app_services.dart`, `searching_technicians_screen.dart`, `book_service_page.dart`, `rebook_wait_widget.dart` |
| Cancelled screen | Cancellation attribution generalised from three rebook-specific booleans to one `_SearchCancelledBy` enum shared by the rebook wait and the broadcast search, so both flows show "Customer Cancelled" / "Technician Cancelled" with matching body copy. The copy no longer says "rebooking request". | `book_service_page.dart`, `embedded_technician_search.dart`, `app_*.arb` |
| Continue button | Hidden whenever a search ended cancelled, and the stale `selectedWorker` is cleared. Previously the rebook technician stayed in `selectedWorker` after a failure, so Continue remained live and a technician-less booking could be walked into review and confirmed. The cancelled state is a single nullable field reset at every point a new search starts — the expiry path closes the request (which the search widget reports as an ending) *and* shows its own timeout dialog, so without the reset a stale flag would have hidden Continue on the next search. | `book_service_page.dart` |
| Warranty reject (technician) | Added a confirmation dialog before the reject fires. | `warranty_controllers.dart`, `app_*.arb` |

### 15.4 Validation performed

| Check | Result |
|---|---|
| `flutter analyze lib/` — technician app | 10 issues, all pre-existing style/dead-code, no errors |
| `flutter analyze lib/` — customer app | 10 issues, all pre-existing style/dead-code, no errors |
| `flutter build apk --debug` — both apps | **Both succeed** |
| `node --check` on all three Cloud Functions files | Passes |
| `require('./index.js')` with a stub Firebase config | Loads; **59 exports**, none undefined — catches export typos and the `onSchedule({schedule, timeZone}, …)` signature change |
| `KsaTime` arithmetic | Verified on a UTC+5:30 machine: round trip exact, 10:00 KSA → 07:00Z, identical in January and July |

Not covered, and worth saying plainly: there are no automated tests in either repo, so nothing here
exercises the apps at runtime against live Firestore. Payment (Telr), location tracking, chat delivery
and push notifications were reviewed only where they touch the changes above.

### 15.5 Runtime failure modes closed during validation

- **Wallet double-credit on historical data.** The crediting Cloud Function was originally keyed on the
  booking *state*. Bookings settled before it existed carry no `walletCreditedAt` marker, so the next
  write of any kind to one of them — a warranty claim, a review, an invoice url — would have credited
  the technician a second time. It now fires on the booking **entering** the payable state
  (`paymentCompleted && status == 'C'` false → true), which is also inherently safe against the marker
  write re-triggering it. The marker remains for retry/race idempotency.
- **Re-entrancy of the marker write.** Every other `bookings` onWrite trigger was checked against it:
  all are transition-guarded on fields the marker write does not touch (`attachWarrantyOnPaymentCompletion`
  additionally requires `!afterData.warranty`), so none double-fire.
- **Silent zero on the pending-payment counter.** The stream ends in `.onErrorReturn(0)`, which would
  render a failed query as "nothing pending" — indistinguishable from the bug it was fixing. The failure
  is now logged.
- **Stale-request cancellation UX collision.** Exporting `cleanupStaleBookingRequests` means the server
  now closes abandoned requests, which the in-wizard search would have reported as a technician
  cancellation *on top of* the wizard's own timeout dialog. Only an actually-deleted request is treated
  as a cancellation.
- **`deleteJobRequest` removed.** It deleted only `job_requests`, and every caller now uses
  `cancelTechnicianSearch`, so there is one teardown path rather than two that differ.

### Follow-ups worth scheduling
1. **Composite index** on `bookings(agent.uid, bookingStatusCode, paymentCompleted)` — until it exists
   the completed-jobs count silently falls back to the old full scan.
2. **Rating backfill** — recompute `users.rating` / `users.reviewCount` from `bookings.review` to clear
   the inflation left by the old double-counting client write.
3. **Wallet backfill** — historical bookings have no `walletCreditedAt`, so the new Cloud Function will
   not re-credit them (correct — they were credited by the old client paths), but any that the old
   paths *missed* stay missing until someone runs the wallet re-sync. `syncExistingDataToUnifiedWallet`
   already recomputes from `bookings` and is reachable from the wallet screen's sync action.
4. **`_showResolveDialog`** in `booking_info.dart` is declared but never referenced — the admin can only
   resolve a complaint from the booking card, not the details page. Wire it up or delete it.

---

## 16. Change log — auto-assignment repair (2026-08-28)

Tester report: *"service for later bookings done during off hours are not being auto-assigned."*
The 3-hour policy itself was confirmed correct and is unchanged — a booking scheduled within 3 hours
searches immediately, one scheduled further out starts searching 3 hours before its slot. Four
defects underneath that policy were making the search fail once it did start.

`functions/` passes `node --check` and `eslint --rule no-undef`. A stubbed-Firestore harness exercises
both auto-assign paths, the cleanup trigger and the untouched broadcast path: 44 assertions, all green.

| # | Defect | Fix |
|---|---|---|
| 16.1 | **A timed-out offer permanently burnt the technician.** The technician app auto-declines an unanswered offer when its 120 s countdown ends (`declineJobOffer(autoDeclined: true)` → `status: 'declined'`), and the auto-assign eligibility filter excluded *any* technician whose offer was not `pending`. Wave one offered every eligible technician, each offer auto-declined itself two minutes later, and the whole pool was permanently barred within minutes of a three-hour search. This is the defect that made auto-assignment look completely dead. | New `isTimedOutOffer` / `loadAutoAssignOfferState` read the `autoDeclined` flag (falling back to `declinedAt ≈ expiresAt` for older docs) and treat a timeout as "not yet answered". Only a deliberate decline is permanent. |
| 16.2 | **Offers were dead for half of every cycle.** The wave interval moved from 1 min to 4 min in `4c025dd` but `OFFER_TTL_SECONDS` stayed at 120 s, so every offer lapsed ~2 minutes before the next wave could replace it. A technician opening the app had a better-than-even chance of an empty Pending tab mid-search. | `AUTO_ASSIGN_OFFER_TTL_SECONDS` (600 s) for auto-assign offers only, and each wave **renews the existing offer in place** instead of writing a new doc. Continuous coverage, one offer doc and one push per technician per booking instead of ~45 of each over a three-hour search. |
| 16.3 | **`onBookingCreatedCleanupOffers` raced the instant broadcast.** `bookings/{id}` and `auto-assignment_requests/{id}` are written in one atomic batch, so the cleanup trigger and `onAutoAssignmentRequestCreated` fire together on the same id with no ordering guarantee. An unconditional delete wiped the freshly created offers whenever cleanup ran second — likeliest on a cold start, i.e. off-peak, i.e. exactly when off-hours bookings are made. | The sweep is anchored to the booking's own `createTime`: offers created *before* the booking are leftovers and are deleted, offers created *after* it belong to the live broadcast and are kept. Correct in either execution order. |
| 16.4 | **A missed request broadcast for ever.** Once an appointment time passed, "within 3 hours of the appointment" stayed true permanently, so the request kept re-broadcasting with nobody watching and no escalation. | One hour past the appointment the request is retired (`status: 'expired'`) and admins get an "Auto-Assignment Failed" notification. The booking is deliberately left at `P` with no agent so it can still be assigned by hand. |

Two structural changes came with the above:

- Both auto-assign paths now share one `stageAutoAssignOffers` implementation. They previously carried
  near-identical copies of the eligibility and offer-writing logic and had already drifted once (§12.4).
- Technician pushes are sent **after** the batch commits, so a failed commit can no longer leave
  technicians holding notifications for offers that do not exist.

**Deliberately not changed:**

- The 3-hour policy, per product decision.
- The live-broadcast path (`broadcastEligibleOffersForRequest` / `loadTechniciansWithExistingOffers` /
  the 120 s `OFFER_TTL_SECONDS` / the 1-minute rebroadcast cron). A 5-minute window with the customer
  watching is a genuinely different problem, and there a lapsed offer really is a dead end.
- Both client apps. Every fix is server-side, so it takes effect for technicians and customers already
  on the current builds without a release.

---

## 17. Pricing change — the general price is bonus-only (2026-08-28)

**Rule:** the customer is never charged, shown, or filtered by the service's general `price`. An
on-hour/off-hour band that carries no price is worth **0**. The general price becomes the basis for the
technician's monthly bonus when the band price is 0.

Both apps pass `flutter analyze` with no new issues (10 and 12 pre-existing, unchanged); `functions/`
passes `node --check`. A stubbed-Firestore harness runs the real `applyMonthlyBonus` handler over the
fee-selection cases: 7 assertions, all green.

### 17.1 Customer app — every general-price read removed

| Where | Was | Now |
|---|---|---|
| `ServiceModel.getCurrentPrice()` | fell back to `price` when either band was null **or zero** | returns the band price, `0` if unset |
| `BookingModel.effectiveInspectionFee` | `onWorkHourPrice ?? price ?? 0` | `onWorkHourPrice ?? 0` (same for off-hour) |
| `sheets/payment.dart` | `completionData.inspectionFee ?? service.price ?? 0` | `completionData.inspectionFee ?? effectiveInspectionFee` |
| `sheets/payment.dart` (Apple Pay ×2) | charged `service.price` | charge the new `_payableAmount` getter |
| `service_tile.dart` | listed `service.price` | `service.getCurrentPrice()` |
| `filter_criteria.dart` | filtered on `service.price` | `service.getCurrentPrice()` |
| `booking_details_page.dart` | showed `service.price` as "Inspection Fee" | `booking.effectiveInspectionFee` |
| `processing_payment_page.dart` (×2) | `getDiscountedPrice(service.price)` | `getDiscountedPrice(service.getCurrentPrice())` |

The Apple Pay change also fixes a real inconsistency it exposed: within the same `processPayment()`,
the card route already charged the computed total while the Apple Pay route sent `service.price`. Both
now read one `_payableAmount` getter.

### 17.2 Technician app — kept in step, and captures the bonus basis

- `BookingModel.effectiveInspectionFee` drops the `service.price` fallback too. This one is not
  cosmetic: it is what `completionData.inspectionFee` is written from, which is what the wallet credit
  and the technician's payment notification read. Left as it was, the technician would have been
  credited an amount the customer is no longer billed.
- `ServiceModel.getCurrentPrice()` matches the customer app's copy (it has no call sites here, but the
  two model copies are maintained in parallel and divergence between them is how bugs start).
- `verify_payment_sheet.dart`'s no-completion-data fallback moves from `service.price` to
  `effectiveInspectionFee`.
- `AppServices.completeBooking` now writes **`completionData.generalServicePrice`**, read from
  `services/{serviceId}` at completion. It is plumbed through `CompleteBooking` → `BookingBloc`, and
  round-trips through the technician's `CompletionDataModel` so re-serialising a completed booking
  cannot drop it.
- `booking_info.dart` still displays `booking.service.price` — that is the frozen *charged* price on an
  internal technician/admin screen, not the general price, so it is correct as-is.

The customer app's `CompletionDataModel` deliberately does **not** parse `generalServicePrice`, so the
figure cannot reach a customer-facing widget at all.

### 17.3 Bonus calculation

`applyMonthlyBonus` picks its base per booking:

```js
const chargedInspectionFee = Number(booking.completionData?.inspectionFee) || 0;
const baseInspectionFee = chargedInspectionFee > 0
  ? chargedInspectionFee
  : Number(booking.completionData?.generalServicePrice) || 0;
```

The existing discount treatment then applies to whichever base was chosen, so the rule stays "the bonus
is earned on the discounted inspection fee, with the general price standing in when that fee is zero".

**Backfill note:** bookings completed before this change carry no `generalServicePrice`. Ones with a
non-zero `inspectionFee` are unaffected. Ones whose fee was 0 score nothing — the same as before the
field existed — so no historical bonus changes value.

---

## 18. Rewards — daily bonus, new tier thresholds (2026-08-28)

The bonus moved from one monthly payout to a **nightly** one, and the Silver/Gold job requirements
dropped. `functions/` passes `node --check`; the technician app passes `flutter analyze` with no new
issues and `untranslated.json` empty. A stubbed-Firestore harness runs the real handler: 32 assertions,
all green.

### 18.1 What changed

| | Before | After |
|---|---|---|
| Export | `applyMonthlyBonus` | **`applyDailyBonus`** |
| Schedule | 1st of month, 01:00 Riyadh | **every day, 00:00 Riyadh** |
| Period paid | the whole previous calendar month | the **KSA day that just ended** |
| Tier input | `previousMonthJobs` (a once-a-month snapshot) | `currentMonthJobs` — month-to-date |
| Idempotency | `lastBonusMonth === currentMonthKey` | `lastBonusDay === dayKey` |
| Silver | 20 jobs, 4.0 rating | **10 jobs**, 4.0 |
| Gold | 40 jobs, 4.5 rating | **12 jobs**, 4.5 |
| Platinum | 60 jobs, 4.8 rating | unchanged |

A worker now earns every night on the inspection fees they settled that day, at whatever tier their
month-to-date record qualifies for, instead of waiting up to 31 days.

### 18.2 Two ordering/consistency traps this had to fix

**`resetMonthlyTiers` moved to 00:30 on the 1st** (was 00:00). It zeroes `currentMonthJobs`, which is
now the bonus's tier input. Left at 00:00 it would race the 00:00 payout and, whenever it won, pay the
last day of every month at Bronze — i.e. nothing — for everybody. The old monthly bonus wanted the
opposite order (it read the `previousMonth*` snapshot the reset writes), so the two schedules had to
move together.

**The tier ladder existed in three places** — the bonus calculation, `updateWorkerTierOnJobCompletion`
(the live badge, recomputed on every completed job), and the technician app's rewards screen. Editing
one moved the badge a worker sees without moving the tier they are actually paid for. The two
server-side copies now share one `resolveTier()`; the app keeps its own constants
(`_silverJobs`/`_goldJobs`/`_platinumJobs` in `rewards_page.dart`) with a comment tying them to
`TIER_*_JOBS`, since it cannot read the function's source.

### 18.3 KSA day boundaries

The day being paid for is a **Riyadh** calendar day, not a UTC one — Cloud Functions run in UTC, so
`new Date()` would have straddled two KSA days. `ksaDayKey` / `ksaDayBounds` / `previousKsaDayKey`
derive it from the fixed UTC+3 offset, the same technique `assignNewBookingIdHelper` already uses for
booking numbers. `previousKsaDayKey` steps back from the start of the current KSA day rather than
subtracting 24h from "now", so a schedule that fires a few minutes late still names the right day.

### 18.4 Query cost

The monthly job ran one `bookings` query **per user** over their entire history and filtered in memory.
At 30x the frequency that was not affordable, so the daily run does a single range query
(`bookingStatusCode == 'C'` + `walletCreditedAt` within the day) and buckets by agent, then reads only
the user documents that actually earned.

That range query needs a composite index on **(`bookingStatusCode`, `walletCreditedAt`)**. If it is not
present the query fails with `FAILED_PRECONDITION`, and the function falls back to the old
scan-and-filter rather than paying nobody — same pattern as the completed-jobs aggregation. **Create
the index** to get the cost benefit; the fallback is a safety net, not the intended path.

### 18.5 Copy

`bonusCalculationNote` said "your monthly bonus … from the previous month" — now describes the nightly
payment, in all three languages. `monthlyBonusEarned` → `bonusEarned` (it is a running total, not a
monthly one). The rewards stat tile showing the most recent payout was labelled just "Bonus", which
next to a month-to-date job count read as a monthly figure; it is now `lastBonus` / "Last Bonus".
`twentyPlusJobs`/`fortyPlusJobs`/`sixtyPlusJobs` were replaced by one parameterised
`tierJobsRequirement(count)`, so the strings cannot state a number the ladder no longer uses.

### 18.6 Note on the ladder shape

Silver at 10 jobs and Gold at 12 are two apart, while Platinum stays at 60. That is what was asked for
and it works, but the middle of the ladder is now very compressed relative to the top — worth a second
look if Platinum was meant to come down too.

### 18.7 BONUS_MODE — both schemes deployed, one live

`applyMonthlyBonus` was **not** deleted. Both functions are deployed and a single constant at the top
of the rewards section decides which one pays:

```js
const BONUS_MODE = "daily"; // "daily" | "monthly"
```

The inactive function returns immediately on every invocation. This is not tidiness — it is the only
thing standing between the two schemes and a double payout. The monthly job sums a whole month of
inspection fees that the daily job has already paid out night by night, and the two guards
(`lastBonusMonth` vs `lastBonusDay`) know nothing about each other, so if both schedules were armed
every technician would be paid twice for the same work.

`BONUS_MODE` also selects the job ladder, so reverting the schedule reverts the thresholds with it:

| Mode | Silver | Gold | Platinum |
|---|---|---|---|
| `daily` | 10 | 12 | 60 |
| `monthly` | 20 | 40 | 60 |

**To revert to the previous scheme:**
1. Set `BONUS_MODE = "monthly"` in `functions/index.js`.
2. Set `_silverJobs = 20` and `_goldJobs = 40` in the technician app's `rewards_page.dart` — the app
   cannot read the function's constants, so this does not follow automatically.
3. Restore the monthly wording of `bonusCalculationNote` (and `bonusEarned`/`lastBonus` if the
   "Monthly Bonus Earned" phrasing is wanted back) in the three `.arb` files, then `flutter gen-l10n`.
4. `firebase deploy --only functions`.

No function has to be recreated and no Cloud Scheduler job has to be rebuilt.

Two deliberate differences between the restored monthly function and the version it was copied from:
it takes its ladder from the shared `resolveTier()`, and it keeps the
`completionData.generalServicePrice` fallback from the pricing change — that was a separate decision
and is not part of what reverting the schedule is meant to undo.

### 18.8 Required Firestore index

The daily run's range query needs a composite index that **Firestore does not create on its own**:

| Collection | Fields | Scope |
|---|---|---|
| `bookings` | `bookingStatusCode` ASC, then `walletCreditedAt` ASC | Collection |

Firestore auto-creates single-field indexes only; anything combining an equality filter with a range
filter on a different field needs an explicit composite index. Without it the query throws
`FAILED_PRECONDITION` and the function falls back to scanning every completed booking and filtering in
memory — correct, but it gives up the whole cost saving.

`firestore.indexes.json` at the repo root holds the project's full index set (41 pre-existing, exported
with `firebase firestore:indexes`, plus this one), so it can be deployed without proposing to delete
anything. It is **not** wired into `firebase.json`; add a `"firestore": { "indexes": "firestore.indexes.json" }`
entry before running `firebase deploy --only firestore:indexes`.
