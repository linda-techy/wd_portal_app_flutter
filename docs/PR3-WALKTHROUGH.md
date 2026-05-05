# PR3 Manual Browser Walkthrough — S1 Scheduling Foundation

**Status:** Deferred to user — manual walkthrough required.

This document captures the 10-step end-to-end QA walkthrough for the PR3 work
(WBS templates admin UI, holiday calendar, project schedule config). The
implementation tasks 1–22 have shipped on `feat/s1-pr3-flutter-admin-ui` with
all `flutter test` and `flutter analyze` checks green. This walkthrough
exercises the UI live against running PR1 + PR2 backends and was deferred from
the agentic execution because it requires:

- Five concurrent dev services (portal API on 8080, customer API on 8081,
  portal Flutter on 3000, customer Flutter on 3001, web on 3002).
- An ADMIN-role login on the portal API to exercise the manage flows.
- A test district code (`KL-EKM`) seeded via PR1's V116 migration.

## Pre-flight

Branch state:

- `wd_portal_api`: `feat/s1-pr2-templates-cloner-roles` (V117 + permission seed)
- `wd_portal_app_flutter`: `feat/s1-pr3-flutter-admin-ui` (this PR)

Start services (from each repo root):

```bash
# Portal API (Spring Boot — terminal 1)
cd "N:/Projects/wd projects git/wd_portal_api" && \
  ./mvnw spring-boot:run

# Portal Flutter (terminal 2)
cd "N:/Projects/wd projects git/wd_portal_app_flutter" && \
  flutter run -d chrome --web-port 3000
```

Login: any user with role `ADMIN`.

## Steps

### 1. Drawer entries appear for ADMIN

- Sign in.
- Open the side drawer, expand the **Admin** group.
- **Pass:** "WBS Templates" and "Holidays" entries are visible (with
  `account_tree` and `event` icons respectively).

### 2. Drawer entries hidden for SITE_ENGINEER

- Sign out, sign in as a SITE_ENGINEER.
- **Pass:** Neither "WBS Templates" nor "Holidays" appears in the drawer.
  ("WBS Templates" should still be visible because SITE_ENGINEER has
  `WBS_TEMPLATE_VIEW`. Verify per role matrix.)

### 3. Holiday Calendar — list

- Re-sign as ADMIN. Navigate to Admin → Holidays.
- **Pass:** Page renders with title "Holiday Calendar", year filter
  defaulting to current year, scope filter "All".
- Switch year to 2026 and scope to STATE → KL.
- **Pass:** Onam Day 1 / Onam Day 2 (lunar) are listed with date 2026-08-26 / 27
  (assuming PR2's lunar resolver populated 2026 in V117 — otherwise empty).

### 4. Holiday Calendar — Import YAML

- Click the "Import YAML" button.
- **Pass:** A toast says "Imported N holidays" where N >= 1.

### 5. Holiday Calendar — Create

- Click the "+" FAB.
- Fill: name "Test Day", date pick today + 30 days, scope NATIONAL,
  recurrence ONE_OFF.
- Save.
- **Pass:** Row appears in list. Snackbar "Holiday added."

### 6. WBS Template list

- Navigate Admin → WBS Templates.
- **Pass:** 4 chips visible (All, Residential, Commercial, Interior Fit-out,
  Renovation). Click "Residential". Cards render for each template version
  with name, version chip, active flag, last-edited date.

### 7. WBS Template editor

- Click a template card.
- **Pass:** Two-pane editor loads: phase list on left (drag-handle visible),
  task table on right showing the first phase's tasks with columns: Seq, Name,
  Duration, Weight, Floor, Monsoon, Pmt, Preds.

### 8. WBS Template — Save as new version

- Edit the template name (use the AppBar action, or change a phase via the
  edit icon).
- Click "Save as new version".
- **Pass:** Snackbar "Saved as v{N+1}". Going back to the list shows the new
  version card.

### 9. Project schedule config — read

- Navigate to a project detail page (`/projects/{id}` of any active project).
- Scroll to the bottom — find the "Schedule configuration" card.
- **Pass:** Renders with sundayWorking toggle (default OFF), monsoon dates
  (default 06-01 / 09-30), district code (defaults to project's district or
  "(none)"), holiday-overrides section.

### 10. Project schedule config — write

- Toggle "Sunday is a working day" ON.
- **Pass:** Snackbar "Saved." Toggle remains ON after refresh.
- Click the edit icon next to "Monsoon start" → pick June 15 → save.
- **Pass:** Snackbar "Saved." Value updates to 06-15.
- Click "Add" next to "Project holiday overrides" → enter the holiday ID from
  step 5, action "Work this day (exclude holiday)" → save.
- **Pass:** Override row appears with `cancel` icon.

## Expected pass criteria

All 10 steps complete with green checkmarks. Network tab shows requests to:

- GET /api/admin/holidays
- POST /api/admin/holidays
- POST /api/admin/holidays/import-yaml
- GET /api/admin/wbs-templates
- GET /api/admin/wbs-templates/{id}
- POST /api/admin/wbs-templates
- GET /api/projects/{id}/schedule-config
- PUT /api/projects/{id}/schedule-config
- GET /api/projects/{id}/holiday-overrides
- POST /api/projects/{id}/holiday-overrides

All return `200`/`201` JSON envelopes (`{success: true, data: ...}`).

## Permission-gate spot check

Sign in as a SITE_ENGINEER and re-do step 7 if the WBS templates link is
visible (they have VIEW only). Verify:

- "Save as new version" button is hidden.
- "Add task" / "Add phase" buttons are hidden.
- Edit pencils on phases/tasks are hidden.
- Drag handles for re-ordering are disabled.
