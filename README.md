# RICH

Personal discipline, finance, trading, reading, work, and mentor app built with
Flutter.

## Linux Desktop

The project includes a Linux Flutter runner. Build a debug desktop version with:

```sh
flutter build linux --debug
```

On Debian/Ubuntu systems, secure desktop storage requires libsecret headers:

```sh
sudo apt update
sudo apt install -y libsecret-1-dev
```

The focus timer uses Flutter's built-in system click on desktop, so the Linux
build does not need GStreamer audio development packages.

## Supabase Sync

Create a Supabase project, run `supabase/schema.sql` in the SQL editor, then
create one Auth user for yourself. Start both Android and Linux with the same
project values and the same sync account:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SUPABASE_SYNC_EMAIL=you@example.com \
  --dart-define=SUPABASE_SYNC_PASSWORD=your-password
```

Finance data syncs local-first through the `rich_sync_records` table. The app
only syncs between devices that are signed into the same Supabase user.

If sync does not upload anything, check the debug console. The app prints one
of these messages:

- `Supabase is not configured`: the app was launched without
  `SUPABASE_URL` and/or `SUPABASE_ANON_KEY`.
- `Supabase session is not available`: the URL/key are present, but there is no
  signed-in user. Pass `SUPABASE_SYNC_EMAIL` and `SUPABASE_SYNC_PASSWORD`, or
  enable anonymous sign-ins in Supabase Auth and launch with
  `--dart-define=SUPABASE_AUTO_ANON_AUTH=true`.
- `Finance sync completed`: upload/download reached Supabase.

## Reports And Mentor Reviews

The Reports screen keeps recent history in two layers:

- Daily records stay available for the last 25 days.
- Records older than 25 days are folded into monthly summaries in the
  `monthly_reports` Hive box.

Monthly reports preserve feature totals and item lists, including work tasks,
meetings, finance totals, reading pages, writing words, and focus time. The
Monthly tab shows a quick mentor read immediately, then the `AI MENTOR REVIEW`
button sends a compact monthly brief plus the current mentor context to the
existing text AI service. That response is meant to read like a practical mentor
review: what worked, what leaked, one rule for next month, and one move for
today.

The AI route uses `AiLessonService`, which can call Pollinations with an
optional `POLLINATIONS_API_KEY` dart define:

```sh
flutter run --dart-define=POLLINATIONS_API_KEY=YOUR_KEY
```

Without that key, the app falls back to the configured no-key text route when
available. If the service is unreachable, the monthly report still shows the
local summary and raw recorded data.
