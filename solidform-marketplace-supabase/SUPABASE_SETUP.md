# SolidForm Supabase setup

1. Create a Supabase project and open the SQL Editor.
2. Run `supabase/schema.sql`. This creates authentication-linked profiles, contractor onboarding, projects, quotations, private compliance documents, reviews, moderation records, row-level security policies and the private Storage bucket.
3. In Authentication, configure the Site URL and allowed redirect URLs for your deployed domain. Keep email confirmation enabled for production.
4. Copy the project URL and **publishable** key into `dist/supabase-config.js`. Never place a secret or `service_role` key in browser files.
5. Create the first administrator by registering normally and then changing their row in `public.profiles` to role `admin` from the Supabase dashboard.
6. Serve the `dist` directory over HTTPS. The site remains in interactive demo mode until both public config values are present.

## Verification operations

- Keep the `contractor-documents` bucket private. Review files through time-limited signed URLs generated for authenticated administrators.
- Record each source check in `document_verifications`; do not rely on upload alone.
- Recheck time-sensitive evidence when it expires and before a high-risk appointment.
- Publish only a contractor's verification status, relevant scope credentials and expiry warning. Do not expose identity, tax, address or banking evidence to customers.
- Add a documented retention/deletion schedule and incident response process before production launch.

## Production work still required

- Add server-side/Edge Functions for signed document previews, notification emails and privileged workflow transitions.
- Add CAPTCHA/rate limits, audit-event writes, malware scanning and consent/privacy documents.
- Replace the demonstration WhatsApp number in `dist/assets/app.js`.
- Have South African legal/compliance counsel review the final onboarding, POPIA notices and marketplace terms.
