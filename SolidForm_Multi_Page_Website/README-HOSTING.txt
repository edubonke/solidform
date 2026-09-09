SOLIDFORM CONSTRUCTION WEBSITE
Portable multi-page website package

CONTENTS
--------
- index.html       Home page
- services.html    Detailed services
- projects.html    Project case studies
- about.html       Company profile and credibility
- quote.html       Interactive quote builder
- contact.html     WhatsApp enquiry page
- assets/          Styles, scripts and website images

HOW TO HOST IT
--------------
This is a static website and does not require a database or server-side code.

1. Extract the ZIP file.
2. Upload all extracted files and the assets folder to your hosting provider's
   public website directory. This folder is often named public_html, www or htdocs.
3. Keep index.html in the top-level public directory.
4. Keep the existing folder structure unchanged.
5. Visit your domain and test every navigation item and the WhatsApp forms.

The same files can also be deployed through Netlify, Cloudflare Pages, GitHub
Pages, cPanel hosting or another static website host.

IMPORTANT CHANGES BEFORE CLIENT LAUNCH
--------------------------------------
The current website is a presentation draft. Update the following placeholders:

1. Company name and branding
   Search the HTML files and assets/app.js for "SolidForm".

2. WhatsApp number
   Open assets/app.js and replace:
   const COMPANY_WHATSAPP = "27601234567";
   Use the full international number without +, spaces or brackets.
   Example for a South African number: 27821234567

3. Phone and email address
   Replace 060 123 4567, +27601234567 and hello@solidform.co.za in the HTML files.

4. Service area
   Replace Johannesburg and greater Gauteng if the company serves other areas.

5. Prices
   The quote rates are inside the services list near the top of assets/app.js.
   Confirm all rates and minimum charges with the company before public launch.

6. Claims and portfolio content
   Replace draft experience figures, project counts, warranties, testimonials,
   project descriptions and duplicated demonstration images with verified company
   information and genuine project photographs.

7. Company details
   Add verified registration, insurance, professional membership and trade
   information only when supporting evidence is available.

QUOTE BUILDER
-------------
The quote builder works inside the browser. It calculates an indicative range
from the selected services, project size, finish level and urgency. When the
visitor agrees to continue, the site opens WhatsApp with the complete quote and
client brief already written.

No client information is stored by this website.

TECHNICAL NOTES
---------------
- Entry page: index.html
- Required JavaScript: assets/app.js
- Required stylesheet: assets/styles.css
- No build step is required.
- No external database is required.
- Google Fonts are loaded from the internet; the website still falls back to
  common system fonts if they are unavailable.

Draft package prepared in September 2026.
