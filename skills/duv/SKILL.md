---
name: duv
description: "Search and retrieve data from the DUV Ultramarathon Statistics website (statistik.d-u-v.org). Use when the user asks about ultramarathon results, runner profiles, race events, rankings, records, or finishing times — e.g. 'find runner X on DUV', 'what was the Spartathlon 2024 result', 'best 100km times in Hungary', 'lookup ultra runner'. The DUV database covers 10M+ performances, 2.4M+ runners, and 115k+ ultra events worldwide."
---

# DUV Ultramarathon Statistics

The DUV (Deutsche Ultramarathon-Vereinigung) statistics site at `https://statistik.d-u-v.org/` is the canonical database for ultramarathon results worldwide.

**There is no official API.** All data is served as HTML. Use `curl` / `WebFetch` and parse the returned pages.

## Core URL patterns

All endpoints are under `https://statistik.d-u-v.org/`.

| Endpoint | Purpose | Key params |
|---|---|---|
| `searchrunner.php` | Search runners by name | `sname=<name>` |
| `getresultperson.php` | Runner profile + all results | `runner=<id>` |
| `searchevent.php` | Search events by name | `sname=<name>` |
| `getresultevent.php` | Event details + finisher list | `event=<id>` |
| `geteventlist.php` | Browse/filter events | `year`, `country`, `dist`, `racetype`, `dist_from`, `dist_to`, `iau`, `sort` |
| `getresultclub.php` | Club lookup | `club=<name>` |
| `getintbestlist.php` | International rankings | `year`, `dist`, `country`, `gender`, `AgeGrp` |
| `overview_intbestlist.php` | International rankings overview | — |
| `overview_dtbestlist.php` | German rankings overview | — |
| `overview_records.php` | Records overview | — |
| `overview_champions.php` | Championships overview | — |
| `overview_cups.php` | Cups overview | — |
| `calendar.php` | Race calendar | `year`, `country` |
| `bulk_search.php` | Bulk runner search | form POST |

All endpoints additionally accept `language=EN|DE|FR|ES|IT|RU|ZH|JA` — always pass `language=EN` for consistent scraping.

## Common parameter values

- `country`: 3-letter IOC codes — `HUN`, `GER`, `USA`, `GBR`, `JPN`, etc.
- `dist`: `50+km`, `50+mi`, `100+km`, `100+mi`, `6+h`, `12+h`, `24+h`, `48+h`, `72h`, `6+days`, `10d` (URL-encode the space as `+`)
- `racetype`: `road`, `trail`, `track`, `indoor`, `stage`, `elimination`, `backyard`, `walking`
- `gender`: `M` or `W`
- `year`: 4-digit year or `all`

## Recipes

### Find a runner by name

```
curl -sL "https://statistik.d-u-v.org/searchrunner.php?sname=Jablonkai&language=EN"
```

- If **one match**, the server 302-redirects to `getresultperson.php?runner=<id>` (use `curl -L` or check `Location` header; `-w "%{url_effective}"` reveals the resolved id).
- If **multiple matches**, the page lists them as `getresultperson.php?runner=<id>` links — parse with a regex like `getresultperson\.php\?runner=[0-9]+`.

### Get a runner's full result history

```
curl -s "https://statistik.d-u-v.org/getresultperson.php?runner=401716&language=EN"
```

Returns name, DOB, nationality, club, and a table of every ultramarathon performance (date, event, distance/time, rank).

### Find an event

```
curl -sL "https://statistik.d-u-v.org/searchevent.php?sname=Spartathlon&language=EN"
```

Same redirect-vs-list behavior as runner search. Event detail URL: `getresultevent.php?event=<id>`.

### List events by year / country / distance

```
curl -s "https://statistik.d-u-v.org/geteventlist.php?year=2024&country=HUN&dist=100+km&language=EN"
```

Response contains `getresultevent.php?event=<id>` links for each matching event.

### Get full finisher list of an event

```
curl -s "https://statistik.d-u-v.org/getresultevent.php?event=100580&language=EN"
```

Each finisher row links to `getresultperson.php?runner=<id>`.

### International best list for a year/distance

```
curl -s "https://statistik.d-u-v.org/getintbestlist.php?year=2024&dist=100+km&gender=M&country=HUN&language=EN"
```

## Scraping tips

- Always append `&language=EN` so labels are predictable.
- Use `curl -sL` to follow the single-match redirects from search endpoints.
- Parse IDs with regex — the HTML is stable but not semantic.
- Be polite: sequential requests with small delays. The site is community-run and has no rate-limit API.
- HTML entities: links contain `&amp;` — decode before following.
- The site has **no JSON/XML API**. Only RSS feeds exist for `latestresults_rss.php` and `xml/nextraces_rss.php`.

## When unsure of an ID

Never guess runner or event IDs — always resolve them via `searchrunner.php` / `searchevent.php` first, or via `geteventlist.php` filters. IDs are opaque and not derivable from names.
