# Portal Flutter App — Codebase Cleanup

Branch: `chore/codebase-cleanup`
Date: 2026-04-22
Status: **Phase 1 (Discovery) complete. No deletions yet.**

## Core principles (from user's cleanup prompt)
- Analyze first, delete last
- When in doubt, keep it
- Document every decision
- Preserve git history (use `git rm`)

## Baseline

Run `flutter analyze --no-fatal-infos --no-fatal-warnings` on a clean tree:
- **0 errors**
- **1 warning** — unused import `package:pdf/pdf.dart` in `lib/services/reports/quality_report.dart:1`
- **11 infos** — mostly `prefer_const_constructors` hints

Build and tests pass on `main` today. Any cleanup must not regress this.

## Phase 1 — Discovery

### Folder structure
```
wd_portal_app_flutter/
├── lib/                        401 dart files total
│   ├── config/                 2  (app_config, router — GoRouter, 32 GoRoute declarations)
│   ├── constants/              6
│   ├── controllers/            1
│   ├── exceptions/             1
│   ├── features/               97  (feature-sliced organisation)
│   ├── models/                 46
│   ├── providers/              28
│   ├── screens/                98  (older organisation — parallel tree to features/)
│   ├── services/               55
│   ├── shared/                 3
│   ├── theme/                  4
│   ├── utils/                  24
│   └── widgets/                32
├── test/                       1  file
├── integration_test/           14 files (login/navigation helpers + module tests)
├── android/ ios/ web/ windows/ macos/ linux/    platform code
├── assets/                     declared in pubspec: images/, icons/
├── pubspec.yaml
├── analysis_options.yaml       (uses flutter_lints/flutter.yaml, no excludes)
├── firebase.json
└── .github/workflows/ci.yml    (flutter analyze + flutter test on push/PR)
```

### Entry points
- `lib/main.dart` — `runApp(...)`, wires providers
- `lib/config/router.dart` — **32 `GoRoute` declarations**, all static `builder: (_, __) => const FooScreen()`. No string-based name lookup, no `onGenerateRoute` dynamic dispatch.

### Dynamic imports / string-based references
- **No `deferred as` imports** in `lib/`
- **No string-based route name lookup** outside GoRouter's own tables
- **No Dart file names referenced** in `web/`, `android/app/src/main/`, HTML, JSON, or markdown (spot-checked)
- **3 generated files**: `*.g.dart` / `*.freezed.dart` — these are code-gen outputs, not hand-written, will regenerate from their source models

### Test setup
- `test/widget_test.dart` — single smoke test
- `integration_test/` — helpers + module tests
- **CI runs `flutter analyze --no-fatal-infos` + `flutter test`** on push/PR to main. Production build is NOT run in CI.

### Side-effect imports
Scan for imports that might run for side effects alone — none found. All imports are standard.

### Observation: parallel `screens/` + `features/` trees
- `lib/screens/` — 98 files, older organisation (by UI type: dashboard, tasks, auth, etc.)
- `lib/features/` — 97 files, feature-sliced (`features/<name>/{data,domain,presentation}/`)
- Both trees are live — neither is flagged as deprecated in code comments
- Some feature names appear in both trees (e.g. `boq`, `customers`, `delays`, `labour`, `leads`, `procurement`, `quality`). Previous session produced false "duplicate" readings based on folder overlap alone. In reality, each file's status must be checked individually — a shared folder name does **not** imply redundancy.

## Phase 1 outcome: safe-to-act inventory

What this phase is **allowed** to have touched:
- Created branch `chore/codebase-cleanup`
- Created this report file

What this phase has **not** touched:
- Any source file
- Any config file
- Git history beyond the branch creation

## What goes into Phase 2

Before the next phase runs a single delete or edit, the plan is:

1. Install/run at least **two** analyses:
   - `flutter pub run dependency_validator` (via pub global — for unused/undeclared pub deps)
   - Custom Dart script that walks `lib/` and for each `.dart` file builds a symbol/file-use map from AST imports (not substring grep). This is what actual tools like `dart_code_metrics` or a hand-rolled AST walker do — avoids the false-positive "0 imports" readings that caused the earlier session's mistakes (relative-path vs package-path, import-without-usage, etc.).
2. Produce a candidate list per category (A. unused, B. duplicate, C. dead code, D. obsolete deps), with per-file evidence.
3. Present candidates to user for review. **No deletion until approved.**

## Phase 2 — Candidate identification

Two analyses were run, both path-aware (not substring grep). Tools committed at `tool/find_unused.py` and `tool/verify_unused_v2.py`.

### Method 1 — AST-style reachability walker
Parses every `import`, `export`, `part`, and conditional-import alternate in every `.dart` file under `lib/`, `test/`, `integration_test/`. Resolves targets (handles `package:admin/…`, relative, and external). BFS from roots = `lib/main.dart` + all `_test.dart` files + anything in `test/` or `integration_test/`.

Result: **86 files in `lib/` unreachable from roots** (out of 401).

### Method 2 — Filename presence check
For each candidate, grep the entire repo (`.dart`, `.yaml`, `.json`, `.md`, `.html`) for its filename. Split hits by whether the referring file is itself an orphan candidate.

Result buckets:
- **60 candidates** with **zero external references** anywhere in the repo (strongest delete-candidates)
- **23 candidates** referenced only by *other* orphan candidates (dead clusters — unused feature subgraphs)
- **3 candidates** that showed up in Method 1 but are **actually live** — keep

### The 3 live-keeper corrections
Method 1 initially flagged these because they chain-load through `screens/customer_projects/project_details_screen.dart` (the old tile-rich detail screen), which *is* live via `main_screen.dart:88` → `CustomerProjectsScreen` → `ProjectDetailsScreen`:

- `lib/screens/customers/customers_screen.dart` — referenced by router + main_screen
- `lib/screens/delays/delay_logs_screen.dart` — referenced by old project_details_screen
- `lib/screens/reports/site_reports_screen.dart` — referenced by old project_details_screen

**This is the exact set of files I mis-deleted in the previous session.** The second-method cross-check correctly catches them now.

### Bucket A — 60 files with zero repo-wide references

These are the strongest delete candidates but still need Phase-3 per-file review. See `tool/_verify_out.txt` for the full machine-checked list. Notable clusters visible:
- Orphaned dashboard pieces: `dashboard/components/{header, lead_dashboard, my_fields}`
- Old procurement flows never wired in: `procurement/{grn_list, material_indents, purchase_orders, record_grn, vendor_quotations}` (screens side — distinct from `features/procurement`)
- Old document/finance/inventory/invoice screens: `documents/*`, `finance/{accounts_payable, vendor_payment_form}`, `inventory/*`, `invoices/*`, `payments/payments_screen`
- Legacy `screens/projects/` pieces: `cctv_management`, `subcontract_measurement_form`, `subcontracts_screen`, `subcontract_work_order_detail`
- PDF report generators: `services/reports/{financial, labour, procurement, site_report_pdf}`
- Unused widgets: `accessibility/*`, `animations/{page_transition, staggered_list}`, `charts/progress_ring`, `components/{data_card, empty_state, enhanced_data_table, premium_card, premium_modal, status_indicator}`, `financial/financial_widgets`, etc.
- Two parallel auth scaffolds: `shared/auth/{base_auth_provider, base_auth_service}`, `widgets/portal_auth_wrapper`, `widgets/portal_role_based_navigation`

### Bucket B — 23 dead-cluster files (unused feature subgraphs)

Candidates only reach each other, not the live graph. Likely whole feature prototypes that never shipped:

- `features/change_orders/` — 3 files (screen + service + model). Appears superseded by `features/boq/.../co_management_screen`.
- `features/procurement/` — 6 files (`indent_list`, `indent_creation`, `quotation_management` screens + their services + models). Appears distinct from `screens/procurement/` which is also dead.
- `features/leads/presentation/screens/lead_form.dart` — only referenced by another orphan (`lead_crm_page`).
- `features/warranties/presentation/screens/project_warranties_screen.dart` — only referenced by `providers/project_warranty_provider.dart`, also orphan.
- `providers/{delay_log, inventory_stock, material_indent, vendor_quotation}_provider.dart` — each only reaches a matching orphan screen.
- `models/my_files.dart` + `screens/dashboard/components/{file_info_card, my_fields}.dart` — old dashboard scaffolding.
- `screens/projects/cctv_camera_form_screen.dart` — only referenced by `cctv_management_screen.dart` (also orphan).

### Bucket C — 3 live keepers (exclude from any deletion)

Already listed above. These must NOT be touched.

### Duplicates (separate scan — not yet done)

Phase 2 still needs a duplicate scan (content-hash based). Will be run before Phase 3 proceeds.

## Pause point — user review needed

Before any Phase-3 per-candidate deep analysis or Phase-5 deletion, please review:

1. Is the **60-file Bucket A** list (at `tool/_verify_out.txt`, "ZERO REFERENCES" section) what you expect?
2. Can I proceed to **Phase 3** (per-file verification — checking dependency_validator for unused pub deps, git blame for recent additions, docs references) on Bucket A + Bucket B together?
3. Should the **3 live keepers** (Bucket C) get a follow-up question about whether to *redirect* their callers away from the old tree (i.e., finish the features/ migration), or leave them wired as today?

Nothing has been deleted. Only additions so far: `tool/find_unused.py`, `tool/verify_unused_v2.py`, `tool/_candidates.txt`, `tool/_verify_out.txt`, and this report.

