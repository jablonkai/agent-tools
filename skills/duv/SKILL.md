---
name: duv
description: "Search and retrieve data from the DUV Ultramarathon Statistics website (statistik.d-u-v.org). Use when the user asks about ultramarathon results, runner profiles, race events, rankings, records, or finishing times — e.g. 'find runner X on DUV', 'what was the Spartathlon 2024 result', 'best 100km times in Hungary', 'lookup ultra runner'. The DUV database covers 10M+ performances, 2.4M+ runners, and 115k+ ultra events worldwide."
---

# DUV Ultramarathon Statistics

The DUV (Deutsche Ultramarathon-Vereinigung) statistics site at `https://statistik.d-u-v.org/` is the canonical database for ultramarathon results worldwide.

**There is no official API.** All data is served as HTML. Use `curl` / `WebFetch` and parse the returned pages.

Parameter names and values were verified against the live HTML forms — neither is always what the on-screen label suggests (e.g. the "country" dropdown on rankings posts as `nat`, not `country`; the "F" option posts as `W`). When in doubt, fetch the page and grep for `name='...'` inside `<select>`/`<input>` elements, and pull `<option value='...'>` to see the exact tokens.

**Silent-filter failure warning.** For most of these endpoints, passing a value the backend doesn't recognise does not raise an error — it just drops the filter and returns the unfiltered page (typically 1000 rows, the page cap). That's why the exact tokens below matter: a wrong-looking result is usually a dropped filter, not a shortage of data.

## Core URL patterns

All endpoints are under `https://statistik.d-u-v.org/`. Every endpoint accepts `language=EN|DE|FR|ES|IT|RU|ZH|JA` — always pass `language=EN` for consistent parsing.

| Endpoint | Purpose | Primary params |
|---|---|---|
| `searchrunner.php` | Search runners by name | `sname` |
| `getresultperson.php` | Runner profile + all results | `runner` |
| `searchevent.php` | Search events by name or town | `sname` |
| `getresultevent.php` | Event details + finisher list | `event` |
| `geteventlist.php` | Browse/filter past events | `year`, `country`, `dist`, `surface`, `label`, `from`, `to`, `sort` |
| `getresultclub.php` | Club results | `club`, `year`, `racetype`, `aktype`, `sort` |
| `getintbestlist.php` | International rankings | `year`, `dist`, `nat`, `gender`, `cat`, `label`, `hili`, `tt` |
| `calendar.php` | Race calendar (upcoming/future events) | `year`, `country`, `dist`, `cups`, `rproof`, `mode`, `radius` |
| `bulk_search.php` | Bulk runner search (POST, textarea of names) | form-encoded |
| `overview_intbestlist.php` | International rankings overview | — |
| `overview_dtbestlist.php` | German rankings overview | — |
| `overview_records.php` | Records overview | — |
| `overview_champions.php` | Championships overview | — |
| `overview_cups.php` | Cups overview | — |
| `latestresults_rss.php` | Recent results RSS feed | — |
| `xml/nextraces_rss.php` | Upcoming races RSS feed | — |

## Shared parameter vocabulary

Different endpoints use different names and different value vocabularies for conceptually similar fields. Pick the right one for the endpoint you're calling.

### Country / nation

- `geteventlist.php`, `calendar.php`, `getresultclub.php` → `country=<IOC-3>` (e.g. `HUN`, `GER`, `USA`).
- `getintbestlist.php` → `nat=<IOC-3>` (same codes, different param name).
- `calendar.php` also accepts numeric continent codes on `country`: `1`=Europe, `2`=Asia, `3`=Africa, `4`=North America, `5`=South America, `6`=Oceania.
- Use `all` (or omit) for world-wide.

### Distance (`dist`)

One shared vocabulary across `geteventlist.php`, `getintbestlist.php`, and `calendar.php`. Values are **compact, no spaces, no `+`** — e.g. `100km`, not `100+km`. Passing `100+km` silently returns unfiltered results.

- Fixed distances: `50km`, `50mi`, `100km`, `100mi`
- Time-limited: `6h`, `12h`, `24h`, `48h`, `72h`, `6d`, `10d`
- Multi-day / long: `1000km`, `1000mi` (only `getintbestlist.php`)
- Distance-range codes (geteventlist + calendar only): `1` = 45–79 km, `2` = 80–119 km, `4` = 120–179 km, `8` = 180 km+
- `calendar.php` additionally accepts surface tokens in the `dist` slot (same values as `surface`, see next section): `Road`, `Trail`, `Stage`, `Track`, `Indoo`, `Elim`, `Backy`, `Walk`

### Race surface (`surface` on geteventlist, `racetype` on club)

Case-sensitive, truncated tokens exactly as they appear in the form dropdown. Common full-word variants (`road`, `trail`, `indoor`, `elimination`, `backyard`, `walking`) are NOT recognised and silently return unfiltered results:

- `Road` — road race
- `Trail`
- `Stage` — stage race
- `Track`
- `Indoo` — indoor (yes, truncated at 5 chars)
- `Elim` — elimination race
- `Backy` — Backyard Ultra
- `Walk` — ultra-walking

Omit the param or pass `all` for no surface filter.

### Year

- Most endpoints: a 4-digit year (e.g. `2024`) or `all`. `geteventlist.php` years go back to 1798.
- `calendar.php` additionally: `futur` = all upcoming from today, `past1` = 1 year back from today. (Plain `past` is *not* recognised — use `past1`.)

### Gender (`getintbestlist.php` only)

`gender=M|W`. The form *label* for the female list renders as "F", but the posted *value* is `W` — `gender=F` silently returns zero rows.

### Age category (`cat` on `getintbestlist.php`)

Gender-prefixed tokens, paired with the `gender` value:

- Male list (`gender=M`): `all`, `MU23`, `M23`, `M35`, `M40`, `M45`, `M50`, `M55`, `M60`, `M65`, `M70`, `M75`, `M80`, `M85`, `M90`
- Female list (`gender=W`): `all`, `WU23`, `W23`, `W35`, … `W90`

### IAU label (`label`)

On both `geteventlist.php` and `getintbestlist.php`: empty string (omit the param) = all events, `label=Y` = IAU-labelled events only. The dropdown label reads "IAU-Label" but that string is *not* the value — passing `label=IAU-Label` silently drops the filter.

## Endpoint reference

### `searchrunner.php` — runner search

```
curl -sL "https://statistik.d-u-v.org/searchrunner.php?sname=Jablonkai&language=EN"
```

- `sname` — full-text, ≥2 characters. Can be surname, firstname, or substring.
- **One match** → 302 redirect to `getresultperson.php?runner=<id>`. Use `curl -L` and `-w "%{url_effective}"` to see the resolved id.
- **Many matches** → HTML list of `getresultperson.php?runner=<id>` links. Parse with `getresultperson\.php\?runner=[0-9]+`.
- Accent-insensitive on most characters; try both accented and non-accented forms if nothing comes back.

### `getresultperson.php` — runner profile

```
curl -s "https://statistik.d-u-v.org/getresultperson.php?runner=401716&language=EN"
```

- `runner=<id>` is the only meaningful param (besides `language`). The page itself has no filter controls — just a chronological list of every performance, grouped by year, plus DOB, nationality, club, and age-group categories (German + international) computed from DOB.
- To compare one runner to another, the page embeds a `PersonalBest` / `comparison` form — usually easier to just fetch both runners and diff client-side.

### `searchevent.php` — event search

```
curl -sL "https://statistik.d-u-v.org/searchevent.php?sname=Spartathlon&language=EN"
```

- `sname` — ≥3 characters. Matches **event name OR start town/location**.
- Same one-match-302 / many-match-list behavior as `searchrunner.php`.
- Result links: `getresultevent.php?event=<id>`.

### `getresultevent.php` — event results

```
curl -s "https://statistik.d-u-v.org/getresultevent.php?event=100580&language=EN"
```

- `event=<id>` is the main param.
- Each finisher row links to `getresultperson.php?runner=<id>`.
- The page also surfaces view toggles (avg-speed unit km/h vs min/km, category scheme: German / international / event-specific, nation highlight). In practice, scrape the default view and compute derivations locally — the page URL params for these toggles are unstable.
- Some events bundle several races (e.g. 50k + 100k on the same day) under separate event IDs — resolve each via `searchevent.php` or `geteventlist.php` rather than guessing.

### `geteventlist.php` — past-event browse/filter

```
curl -s "https://statistik.d-u-v.org/geteventlist.php?year=2024&country=HUN&dist=100km&language=EN"
```

Confirmed form field names (authoritative):

- `year` — 4-digit year, or `all`. Default = current year.
- `country` — IOC-3, or `all`.
- `dist` — shared `dist` vocabulary above (`100km`, `24h`, `6d`, range codes `1`/`2`/`4`/`8`, …). No `+` or spaces.
- `surface` — **NOT `racetype`**. Values: see the race-surface vocabulary above (`Road`, `Trail`, `Stage`, `Track`, `Indoo`, `Elim`, `Backy`, `Walk`, case-sensitive). Lowercase full words silently return unfiltered results.
- `label` — **NOT `iau`**. Values: omit (= all) or `Y` (= IAU-labelled).
- `from`, `to` — **NOT `dist_from` / `dist_to`**. Distance-range **codes** from the `dist` dropdown (`1`=45–79 km, `2`=80–119 km, `4`=120–179 km, `8`=180 km+), **not** raw km numbers. `from=80&to=120` is not a valid range and silently returns unfiltered results.
- `sort` — `Date` (default) or `Finishers`.
- `club` — optional filter by club (string, partial match).

Response: HTML table, one row per event, with `getresultevent.php?event=<id>` links. The default page size is up to 1000; results beyond that require narrower filters.

### `calendar.php` — upcoming / future-race calendar

```
curl -s "https://statistik.d-u-v.org/calendar.php?year=futur&dist=6d&country=4&cups=0&rproof=0&mode=list&language=EN"
```

Use `calendar.php` — **not** `geteventlist.php` — whenever the user asks about upcoming, future, or scheduled races. `geteventlist.php` is tuned for completed events with results; `calendar.php` is the forward-looking view and exposes extra filters.

- `year` — `futur` (from today on), `past1` (1 year back), a specific year, or `all`. Plain `past` is *not* a valid token.
- `country` — IOC-3 for a country, or numeric `1`–`6` for a continent (`1`=Europe, `2`=Asia, `3`=Africa, `4`=North America, `5`=South America, `6`=Oceania).
- `dist` — shared `dist` vocabulary above; also accepts surface tokens (`Road`, `Trail`, …) in this slot.
- `cups` — numeric token: `0`=all, `1`=DUV-Cup, `2`=DUV-50km-Cup, `3`=DUV-6h-Cup, `4`=IAU-50k-Trophy, `5`=Championships, `6`=ECU, `7`=Anglo Celtic Plate. (The form shows names; the posted value is the numeric id.)
- `rproof` (ranking-eligible) — `0`=all, `1`=yes, `2`=no.
- `mode` — `list` (tabular) or `map`.
- `radius` — kilometers around a location; only meaningful together with the site's lat/lon context. Leave blank unless reproducing a user-supplied URL.
- `norslt=1` — "without result list": hide events that already have posted results (useful when combined with past years to find events that haven't published results yet). Omit for normal behaviour.

Each row links to `getresultevent.php?event=<id>` (or a pre-race info page for events that haven't happened yet).

### `getintbestlist.php` — international rankings

```
curl -s "https://statistik.d-u-v.org/getintbestlist.php?year=2024&dist=100km&gender=M&nat=HUN&language=EN"
```

Confirmed form field names:

- `year` — 4-digit (back to ~2005).
- `dist` — shared `dist` vocabulary (`100km`, `24h`, `6d`, …) **plus** `1000km`, `1000mi` which only appear here. No `+` or spaces.
- `nat` — **NOT `country`**. IOC-3 or `all`. Continental groupings also accepted: `World`, `Europe`, `Asia`, `Africa`, `North America`, `South America`, `Oceania`.
- `gender` — `M` or `W`. (The form label reads "F" for the female list, but the posted value is `W`; `gender=F` silently returns zero rows.)
- `cat` — **NOT `AgeGrp`**. Age-group code, gender-prefixed: `all`, `MU23`/`WU23`, `M23`/`W23`, `M35`/`W35`, … up to `M90`/`W90`. Must match the `gender` value.
- `label` — omit for all events, or `Y` for IAU-labelled only. (`IAU-Label` is the dropdown *text*, not the value — passing it drops the filter.)
- `hili` (highlight) — overlay highlight for a country (IOC-3) or `none`/`GER`.
- `tt` (time type) — `netto` or `brutto`.
- `club` — optional club filter.

### `getresultclub.php` — club view

```
curl -s "https://statistik.d-u-v.org/getresultclub.php?club=<name-or-id>&year=2024&language=EN"
```

Confirmed form field names:

- `club` — partial match on club name (3–25 chars), or a club id if you already have one.
- `sname` — optional runner-name filter within the club.
- `year` — 2001–current, or `all`.
- `racetype` — surface filter, same case-sensitive tokens as `surface` on `geteventlist` (`Road`, `Trail`, `Stage`, `Track`, `Indoo`, `Elim`, `Backy`, `Walk`).
- `aktype` — ranking-eligibility (`all` or `Y` for "Yes only" — the form label is "Ranking proof").
- `sort` — `Runner/Start date`, `Distance`, `Performance`.

### `bulk_search.php` — POST-only bulk lookup

Paste a list of names (tab/semicolon/comma/space-separated) into the textarea and configure column mappings (surname, first name, gender, nationality, birth, age group, bib, DUVID). Supports a reference discipline (50km, 50mi, 100km, 100mi, 6h, 12h, 24h, 48h, 6 days, Backyard) and age-category scheme (international, German, French, Italian). Output is HTML; no documented CSV export.

For scripted use, `getresultperson.php` + `searchrunner.php` per name is usually simpler than automating the bulk form.

### Overview pages

`overview_intbestlist.php`, `overview_dtbestlist.php`, `overview_records.php`, `overview_champions.php`, `overview_cups.php` are navigation hubs — static landing pages that link into the filterable endpoints above. Follow the links rather than trying to parameterize them.

### RSS feeds

`latestresults_rss.php` and `xml/nextraces_rss.php` are the only structured-data endpoints on the whole site. Useful for "what's new" checks.

## Scraping tips

- Always append `&language=EN` so labels are predictable.
- Use `curl -sL` to follow the single-match redirects from search endpoints.
- Parse IDs with regex — the HTML is stable but not semantic.
- HTML entities: links contain `&amp;` — decode before following.
- Be polite: sequential requests with small delays. The site is community-run.
- If a param you expect isn't filtering, fetch the page and check both the `name='...'` attribute *and* the `<option value='...'>` text in the form HTML — param names *and* value tokens both diverge from user-facing labels (e.g. `nat` vs "Country", `gender=W` vs "F", `surface=Indoo` vs "indoor", `from`/`to` taking range codes `1`/`2`/`4`/`8` vs km numbers, `label=Y` vs "IAU-Label"). A wrong-looking value usually parses as "no filter" and returns the full page cap (1000 rows), not an error.

## When unsure of an ID

Never guess runner, event, or club IDs — always resolve them via `searchrunner.php` / `searchevent.php` / `getresultclub.php` first, or via `geteventlist.php` filters. IDs are opaque and not derivable from names.
