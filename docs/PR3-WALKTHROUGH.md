# PR3 Manual Browser Walkthrough — S1 Scheduling Foundation

**Status:** Deferred to user — manual walkthrough required.

This document captures the 10-step end-to-end QA walkthrough for the PR3 work
(WBS templates admin UI, holiday calendar, project schedule config). The
implementation has shipped on `feat/s1-pr3-flutter-admin-ui` with all
`flutter test` and `flutter analyze` checks green. This walkthrough exercises
the UI live against running PR1 + PR2 backends.

## Pre-flight

Branch state:

- `wd_portal_api`: `feat/s1-pr2-templates-cloner-roles` (V117 + permission seed)
- `wd_portal_app_flutter`: `feat/s1-pr3-flutter-admin-ui` (this PR)

Start services from each repo root:

```bash
# Portal API (Spring Boot — terminal 1)
cd "N:/Projects/wd projects git/wd_portal_api"
./mvnw spring-boot:run

# Portal Flutter (terminal 2)
cd "N:/Projects/wd projects git/wd_portal_app_flutter"
flutter run -d chrome --web-port 3000
```

Login: any user with role `ADMIN`.

## Steps

### 1. Drawer entries appear for ADMIN

- Sign in.
- Open the side drawer, expand the **Admin** group.
- **Pass:** "WBS Templates" and "Holidays" entries are visible (with
  `account_tree` and `event` icons respectively).

### 2. Drawer entries for SITE_ENGINEER — view-only access

- Sign out, sign in as a `SITE_ENGINEER`.
- The role matrix in V117 grants SITE_ENGINEER both `WBS_TEMPLATE_VIEW` and
  `HOLIDAY_VIEW` (but not the corresponding `_MANAGE` permissions).
- **Pass:** Both "WBS Templates" and "Holidays" entries appear in the drawer.
- Open Admin → WBS Templates: list renders as read-only.
  - Edit pencil icons on cards are absent.
  - "New version" floating action button is absent.
- Open a template card → the editor renders.
  - "Save as new version" button in the AppBar is absent.
  - "Add task" / "Add phase" buttons are absent.
  - Edit pencils on phases/tasks are absent.
  - Drag handles for re-ordering are disabled.
- Open Admin → Holidays: list renders as read-only.
  - "+" FAB to create a holiday is absent.
  - Per-row edit / delete icons are absent.

### 3. Holiday Calendar — list

- Re-sign as `ADMIN`. Navigate to Admin → Holidays.
- **Pass:** Page renders with title "Holiday Calendar". Year filter defaults
  to the current year. Scope filter defaults to `NATIONAL` (the backend
  requires a scope on every list call — there is no "All scopes" option).
- Switch year to 2026, scope to `STATE`. The list refreshes for STATE
  holidays for 2026.
- **Pass:** State-scope holidays seeded by V117 (e.g. Onam Day 1 / Onam Day 2)
  appear with the correct dates.

### 4. Holiday Calendar — Create

- Click the "+" FAB.
- Fill: name "Test Day", date pick today + 30 days, scope `NATIONAL`,
  recurrence `ONE_OFF`.
- Save.
- **Pass:** A "Holiday added." snackbar appears, the dialog closes, the new
  row is visible in the list (after the provider's auto-reload).

### 5. WBS Template list

- Navigate Admin → WBS Templates.
- **Pass:** Filter chips visible (All, Residential, Commercial, Interior
  Fit-out, Renovation). Click "Residential". Cards render for each template
  version with name, version chip, active flag, last-edited date.
  - The provider fetches the unfiltered set from the backend (the real
    contract accepts only `includeInactive`); the project-type filter is
    applied client-side.

### 6. WBS Template editor

- Click a template card.
- **Pass:** Two-pane editor loads — phase list on left (drag-handle visible),
  task table on right showing the first phase's tasks with columns: Seq, Name,
  Duration, Weight, Floor, Monsoon, Pmt, Preds.

### 7. WBS Template — Save as new version

- Edit the template name (use the AppBar action, or change a phase via the
  edit icon).
- Click "Save as new version".
- **Pass:** Snackbar reports "Saved as v{N+1}". Navigate back to the list:
  the new version card is visible.

### 8. Project schedule config — read

- Navigate to a project detail page (`/projects/{id}` of any active project).
- Scroll to the bottom — find the "Schedule configuration" card.
- **Pass:** Renders with sundayWorking toggle (default OFF), monsoon dates
  (default 06-01 / 09-30 from V116 seed), district code (defaults to the
  project's district or "(none)"), holiday-overrides section.
- **Permission gate (I1):** Sign in as a user without `HOLIDAY_VIEW` and
  without `PROJECT_SCHEDULE_CONFIG_EDIT`. Re-open the project detail page:
  the Schedule configuration card is absent entirely.

### 9. Project schedule config — write

- As `ADMIN`, toggle "Sunday is a working day" ON.
- **Pass:** Snackbar "Saved." The toggle remains ON after refresh.
- Click the edit icon next to "Monsoon start" → pick June 15 → save.
- **Pass:** Snackbar "Saved." Value updates to 06-15.

### 10. Project schedule config — add holiday override

- Click "Add" next to "Project holiday overrides".
- Pick action `EXCLUDE`, pick a date (the backend now requires `overrideDate`
  on every override request), enter the holiday ID from step 4 (optional —
  leave blank for project-only ADD overrides), save.
- **Pass:** Override row appears with the date and a `cancel` icon. The POST
  returns only the new id; the screen re-fetches the override list to render
  the row with full details.
- Repeat with action `ADD`, no holiday ID, an "overrideName" like
  "Site closure".
- **Pass:** Project-only ADD row appears with the override name and date.

## Expected pass criteria

All 10 steps complete with green checkmarks. Network tab shows requests to:

- `GET /api/admin/holidays?scope=…&year=…`
- `POST /api/admin/holidays`
- `GET /api/wbs/templates?includeInactive=…`
- `GET /api/wbs/templates/{id}`
- `POST /api/wbs/templates`
- `PUT /api/wbs/templates/{id}` (when toggling active or saving an edit)
- `GET /api/projects/{id}/schedule-config`
- `PUT /api/projects/{id}/schedule-config`
- `GET /api/projects/{id}/holiday-overrides`
- `POST /api/projects/{id}/holiday-overrides`

All return `200`/`201`/`204` with raw JSON bodies (no `{success, data}`
envelope). 4xx responses are surfaced via the screen's snackbar.

### 11. B9 — WBS template picker on project creation

- As `ADMIN` (or any user with `PROJECT_WBS_CLONE`), open Leads, pick a lead
  whose project type is residential / commercial / interior / renovation,
  click **Convert** and fill the convert dialog. After the
  "Lead converted successfully!" snackbar a second modal —
  **"Materialize WBS from template"** — appears.
- **Pass:** Templates filtered to the chosen project type are listed as
  radio rows. Floors input defaults to the lead's floor count (clamped to
  1–20). Clicking **Materialize** calls
  `POST /api/projects/{id}/wbs/clone-from-template`; on success a green
  snackbar reports `"WBS materialized: X phases, Y tasks created."`.
- **Skip path:** Click **Skip** → no clone fires; the project is left
  WBS-less and the user can run the flow later from the project's WBS tab.
- **Duplicate-clone:** Re-running the picker against a project that already
  has a WBS surfaces a red snackbar `"Project already has a WBS — nothing
  was changed."` (backend returns 409).
- **Permission gate:** Sign in as a user without `PROJECT_WBS_CLONE` and
  convert a lead. The picker dialog is skipped silently — only the
  conversion success snackbar is shown.

## Notes

- **B9 wired** — the WBS clone is invoked after lead-conversion via
  `WbsTemplatePickerDialog` + `runWbsTemplatePickerFlow`. The picker is
  permission-gated on `PROJECT_WBS_CLONE` and is a silent no-op when the
  project's type doesn't map to any WBS template (e.g. Vastu / Smart Home).
