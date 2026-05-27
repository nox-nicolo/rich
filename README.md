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
