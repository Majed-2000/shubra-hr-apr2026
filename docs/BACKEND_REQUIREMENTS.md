# Backend Requirements — Shubra HR Mobile Sprint

Mobile is **shipped and waiting on backend**. All UI is built, committed, and behind feature flags. As each backend track below comes online, we flip its flag and the feature lights up for users — no mobile redeploy needed for the simple `/myinfoview` extension, just a flag flip + TestFlight/Play push for the new endpoints.

**Tracked features:**
- #8 EOS calculator — needs hire date in profile
- #9 Document vault — new endpoint stack
- #10 HR ticketing — new endpoint stack + admin UI
- #16 Iqama expiry alert — needs profile fields + daily cron + FCM

**Mobile baseline:** Flutter app commit `21a5dcc` on `master`. All endpoints below are consumed via the existing `DioClient` (Bearer token + auto-refresh on 401).

---

## Priority order

| # | Track | Effort | Unblocks |
|---|---|---|---|
| 1 | `/myinfoview` field additions | half day | feature 16 iqama banner + feature 8 EOS auto-hire-date + digital card polish |
| 2 | FCM payload contracts | 1 day (wired into existing push sends) | features 10 + 16 push notifications |
| 3 | Iqama daily cron | 1 day after #1 | feature 16 push reminders |
| 4 | Document vault endpoints | 3–5 days + HR admin upload UI | feature 9 |
| 5 | HR ticketing API + admin UI | 1–2 weeks | feature 10 |

---

## 1. Extend `GET /myinfoview` response

**Why first:** smallest change, single endpoint, unblocks 2 features.

Add these fields inside the existing `info` map. All are nullable so the current mobile builds don't break.

```jsonc
{
  "info": {
    // ── existing fields preserved ──
    "emcd": "10021",
    "emnma1": "...", "emnma2": "...", "emnma3": "...",
    "empmob": "...", "email": "...",
    "slbse": 8000, "sladd": ..., "trns": 500, "monhvl": 2000, "insr": ...,
    "bkaccno": "...", "iban": "...",

    // ── NEW fields ──
    "iqama_expiry":          "2026-08-15",        // ISO date | null  — feature 16
    "nationality":           "IN",                 // ISO 3166 alpha-2 | null — feature 16 (skip if "SA")
    "hire_date":             "2020-03-15",         // ISO date | null  — feature 8
    "service_years_decimal": 5.42,                 // float    | null  — feature 8 (optional; client can derive)
    "contract_type":         "unlimited",          // "fixed"|"unlimited"|null — feature 8 (future)
    "dept_name":             "IT",                 // string   | null  — digital card polish
    "job_title":             "Senior Developer",   // string   | null  — digital card polish
    "photo_url":             "https://...",        // string   | null  — optional override
    "dob":                   "1990-05-10"          // ISO date | null  — optional
  }
}
```

**Skip rules the mobile app applies:**
- If `nationality == "SA"` → iqama banner never shown
- If `iqama_expiry == null` → iqama banner never shown
- If `hire_date == null` → EOS calculator asks user to input manually

**Acceptance:** logged-in employee hits `GET /myinfoview` and the response includes these 9 fields (some may be null), and existing fields are unchanged.

---

## 2. FCM data-payload contracts

Mobile app's FCM handlers (`lib/main.dart` + `lib/shared/services/deep_link_router.dart`) already route on `message.data["type"]`. Backend just needs to send pushes in the right shape.

### 2a. Ticket reply push

When HR replies to a ticket, send to the employee's FCM token:

```json
{
  "to": "<employee_fcm_token>",
  "data": {
    "type": "ticket_reply",
    "ticket_id": "101"
  },
  "notification": {
    "title": "HR replied to your ticket",
    "body": "<first 80 chars of HR's reply, optional>"
  }
}
```

Mobile tap → opens `/ticketDetail` with `arguments: 101`.

### 2b. Iqama alert push (sent by cron — see §3)

```json
{
  "to": "<employee_fcm_token>",
  "data": {
    "type": "iqama_alert",
    "days_remaining": "14"
  },
  "notification": {
    "title": "تنتهي إقامتك خلال 14 يوم",
    "body": "جدّد إقامتك في أقرب وقت"
  }
}
```

Mobile tap → opens `/profile`.

**Notes:**
- Use `data` keys exactly as shown (lowercase, snake_case). `ticket_id` must be string-encoded (FCM data values must be strings).
- The `notification` block is optional but recommended — it's what the OS shows in the tray when the app is killed.
- If you need to add other deep-link types later, follow the same pattern. Update `DeepLinkRouter.fromMessage()` in mobile to route them.

---

## 3. Iqama expiry daily cron

Once §1 ships, add a scheduled job at **09:00 Riyadh time** every day.

```sql
-- Pseudocode
SELECT e.empcode, e.iqama_expiry, e.fcm_token, DATEDIFF(e.iqama_expiry, CURDATE()) AS days
FROM employees e
WHERE e.iqama_expiry IS NOT NULL
  AND e.nationality != 'SA'
  AND e.fcm_token IS NOT NULL
  AND DATEDIFF(e.iqama_expiry, CURDATE()) IN (60, 30, 14, 7, 1, 0, -1)
  AND NOT EXISTS (
    SELECT 1 FROM iqama_notif_log l
    WHERE l.empcode = e.empcode
      AND l.threshold_days = DATEDIFF(e.iqama_expiry, CURDATE())
      AND l.iqama_expiry = e.iqama_expiry
  );
```

For each row: send the FCM push (§2b), then insert into `iqama_notif_log` to prevent re-sending.

**Table:**
```sql
CREATE TABLE iqama_notif_log (
  id            BIGINT PRIMARY KEY AUTO_INCREMENT,
  empcode       VARCHAR(10) NOT NULL,
  iqama_expiry  DATE        NOT NULL,
  threshold_days INT        NOT NULL,
  sent_at       TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq (empcode, iqama_expiry, threshold_days)
);
```

Pinning the log on `iqama_expiry` itself (not just empcode) means a renewal automatically resets the notification cycle.

---

## 4. Document vault endpoints

### 4a. `GET /documents`

```jsonc
// Request: GET /documents  (Bearer user token)
// Response: 200 OK
{
  "documents": [
    {
      "id":          1,
      "title":       "عقد العمل",
      "category":    "contract",         // contract | identity | certificate | other
      "uploaded_at": "2024-01-15T09:00:00Z",
      "mime_type":   "application/pdf",  // or image/jpeg, image/png
      "size_bytes":  245000
    },
    ...
  ]
}
```

Returns only documents owned by the authenticated user.

### 4b. `GET /documents/{id}/download`

```
Request:  GET /documents/{id}/download  (Bearer user token; verify ownership)
Response: Two options — pick one:

  Option A (simple): stream the file bytes inline
    Status:          200
    Content-Type:    application/pdf | image/jpeg | ...
    Content-Length:  <bytes>
    Body:            <raw file bytes>

  Option B (recommended): 302 redirect to a short-lived signed URL
    Status:   302
    Location: https://cdn.shubra.net/docs/sig=...&expires=...
    (mobile follows the redirect with no Bearer header)
```

The mobile app uses `path_provider` to stream the response to a temp file before opening it in `syncfusion_flutter_pdfviewer`. Either approach works.

### 4c. HR admin upload UI (out of mobile scope)

Backend team needs a way for HR to upload documents per employee. Doesn't have to be in the mobile app — could be a separate web admin tool. Required fields per document: `title`, `category`, the file itself.

---

## 5. HR ticketing API

The biggest piece. Replaces the existing fire-and-forget `POST /submitComplaint` with a real ticket system that tracks state and supports two-way messages.

### 5a. Endpoints

```jsonc
// ──────────────────────────────────────────────────────────────────
GET /tickets
// ──────────────────────────────────────────────────────────────────
// Lists current user's tickets, newest activity first.
// Response: 200
{
  "tickets": [
    {
      "id":                   101,
      "subject":              "استفسار عن البدلات",
      "category":             "salary_query",       // see §5b
      "status":               "awaiting_user",      // see §5c
      "last_message_preview": "يرجى مراجعة قسيمة الراتب...",  // first ~80 chars
      "last_activity_at":     "2026-05-19T14:30:00Z",
      "unread_count":         1                     // for the badge dot
    },
    ...
  ]
}

// ──────────────────────────────────────────────────────────────────
POST /tickets
// ──────────────────────────────────────────────────────────────────
// User creates a new ticket.
// Request:
{
  "subject":  "...",
  "category": "complaint" | "salary_query" | "leave_query"
            | "document_request" | "technical_issue" | "other",
  "body":     "..."         // initial message body
}
// Response: 201
{ "ticket_id": 102, "status": "open" }

// ──────────────────────────────────────────────────────────────────
GET /tickets/{id}
// ──────────────────────────────────────────────────────────────────
// Full thread for a single ticket.
// Response: 200
{
  "id":         101,
  "subject":    "استفسار عن البدلات",
  "category":   "salary_query",
  "status":     "awaiting_user",
  "created_at": "2026-05-17T09:00:00Z",
  "messages": [
    {
      "id":          1,
      "author_type": "user",          // "user" | "hr" | "system"
      "author_name": "أنت",            // display name
      "body":        "...",
      "created_at": "2026-05-17T09:00:00Z"
    },
    {
      "id":          2,
      "author_type": "hr",
      "author_name": "الموارد البشرية",
      "body":        "...",
      "created_at": "2026-05-18T11:30:00Z"
    }
  ]
}

// ──────────────────────────────────────────────────────────────────
POST /tickets/{id}/messages
// ──────────────────────────────────────────────────────────────────
// User replies. Status auto-transitions awaiting_user → open.
// Request:  { "body": "..." }
// Response: 201
{ "message_id": 5, "created_at": "..." }

// ──────────────────────────────────────────────────────────────────
POST /tickets/{id}/close   — user closes own ticket; → status "closed"
POST /tickets/{id}/reopen  — only if status=="closed" AND closed <7 days ago
POST /tickets/{id}/read    — server zeros unread_count for this user
```

### 5b. Categories

Hard-coded list for v1 (mobile already has identical fixture):

| key | name_ar | name_en | icon hint |
|---|---|---|---|
| `complaint` | شكوى | Complaint | report_problem |
| `salary_query` | استفسار راتب | Salary Query | payments |
| `leave_query` | استفسار إجازة | Leave Query | event_note |
| `document_request` | طلب مستند | Document Request | description |
| `technical_issue` | مشكلة تقنية | Technical Issue | bug_report |
| `other` | أخرى | Other | help_outline |

If you want this dynamic later, expose `GET /tickets/categories` returning the list. Mobile already has a stub that can switch from local → remote.

### 5c. Status state machine

```
open ──(HR opens it)──> in_progress ──(HR sends reply)──> awaiting_user
  └──(HR closes)──> closed                                      │
                                                                ▼
                                                  (user replies → back to open)

closed ──(user reopens within 7 days)──> open
```

### 5d. HR admin UI (out of mobile scope)

Backend needs a way for HR to view ticket queues, reply to messages, change status, and close tickets. Out of the mobile app's scope but required for the system to be useful.

### 5e. Migration from complaints

The existing `POST /submitComplaint` endpoint stays alive for one release cycle so older mobile builds keep working. New mobile builds (with `FF_TICKETS=true`) call `POST /tickets` with `category: "complaint"` instead. Eventually you can deprecate `/submitComplaint` once `/tickets` is universal.

---

## Verification per track

For each track, the mobile team will flip the matching feature flag in a TestFlight / Play Internal build and run smoke tests:

```powershell
flutter build appbundle --release `
  --dart-define=FF_IQAMA_ALERT=true `
  --dart-define=FF_DOCUMENT_VAULT=true `
  --dart-define=FF_TICKETS=true
```

**Smoke test checklist:**

| Track | What to verify |
|---|---|
| `/myinfoview` extension | Open Profile → see no errors. Open EOS calculator → hire date pre-filled (not empty). Open Home → iqama banner shows expected days remaining for a non-Saudi test user. |
| FCM payloads | Send a mock push with `data:{type:"ticket_reply", ticket_id:"101"}` — mobile shows snack and opens thread on tap. Same for `iqama_alert`. |
| Iqama cron | Set a test employee's `iqama_expiry` to today+14, run cron — push arrives within 1 minute. Re-run cron — no duplicate push (log dedup works). |
| Documents | Open `/documents` in the app → list renders with backend data instead of mocks. Tap a PDF → opens in viewer. |
| Tickets | Open `/tickets` → list. Create new → see in list. Reply → message appears. HR replies on web → mobile gets push, tap → opens thread with new HR message. |

---

## Contact

- Mobile lead (Shubra): Mahmood Ahmad-Himayatullah
- Mobile repo: `Majed-2000/shubra-hr-apr2026` on GitHub
- Latest mobile commit at time of writing: `21a5dcc`
- Plan reference: `~/.claude/plans/do-1-2-5-8-9-10-12-13-14-15-16-17-18-sea-wobbly-pine.md` (local; tied to the sprint planning session)

When a track is ready, ping mobile so we can flip the flag, run smoke tests, and ship the next TestFlight / Play build.
