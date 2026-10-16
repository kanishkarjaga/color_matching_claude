# Embroidery Thread Color Recommender

## Structure
```
backend/            FastAPI (heavy tasks); app/color.py = core matcher
app/lib/core        color_math.dart (Lab + CIEDE2000)
app/lib/data        db.dart (SQLite, daily backup/restore), thread.dart (model + snap)
app/lib/features    threads/ (Phase 1 UI); later: job/, preview/, catalog/, rules/, reports/
docs/schema.sql     full DB schema (all phases)
```

## Setup
Backend: `cd backend && pip install -r requirements.txt && PYTHONPATH=. pytest && uvicorn app.main:app --reload`
App: `cd app && flutter create . --project-name thread_recommender && flutter pub get && flutter run`
(`flutter create .` generates android/ios folders; it keeps the provided lib/ and pubspec.yaml.)

## Phase 1 test checklist
1. Add 3 threads (one zari) -> list shows sample-color swatch.
2. Toggle one out of stock -> Match never returns it.
3. Enter `#800020` -> nearest thread + deltaE.
4. Relaunch next day -> new file in backups; Restore icon reverts DB.

## API
Live (P1): GET/POST /threads, PUT /threads/{id}, POST /threads/{id}/stock, GET /threads/low-stock, POST /match, POST /backup, GET /backups, POST /restore/{name}
Planned: /fabric/colors, /schemes (P2); /preview (P3); /jobs, /jobs/{id}/sheet, /jobs/{id}/qr (P4); /designs, /designs/{id}/layers, /jobs/duplicates (P5); /share/{token}, /feedback, /reports/* (P6); /segment, /learn (P7)

## Next: Phase 2
Fabric K-means (LAB) endpoint, scheme generators, JSON rules engine, fabric-type adjustments, scoring.

## Get the APK (no local setup)
1. Create a GitHub repo, upload the contents of this folder (including `.github/`).
2. Actions tab -> "Build APK" -> Run workflow (also runs on every push to main).
3. When green (~5 min), open the run -> Artifacts -> `thread-recommender-apk` -> download, unzip, copy `app-release.apk` to your phone.
4. On phone: allow "Install unknown apps" for your file manager/browser, tap the APK.
