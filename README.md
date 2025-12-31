# TV Program Scraper

A small, object-oriented Ruby CLI that fetches TV program schedules and normalizes data into `Program` objects. The tool prefers site APIs and falls back to HTML parsing when necessary, and can display or save schedules as JSON.

---

## Features

- Fetch schedules for a selected date
- Prefer API-based data when available; fallback to Nokogiri HTML parsing
- Normalize schedule entries into `Program` objects with validation
- Output to console table or save as JSON (`tv_programs.json`)
- Includes helper scripts for API discovery and payload inspection

---

## Project structure

- `scrape.rb` — interactive CLI
- `lib/tv_guide_scraper.rb` — scraper and parsing logic
- `lib/program.rb` — `Program` model (time parsing, validation)
- `lib/formatters/console_formatter.rb` — console output
- `lib/formatters/json_formatter.rb` — JSON output and save helper
- `scripts/discover_api.rb` — scan site scripts for `/api/` endpoints
- `scripts/inspect_page.rb` — inspect page API payloads
- `spec/` — unit tests (RSpec)

---

## Requirements

- Ruby 2.7+ or 3.x
- Bundler

Dependencies are listed in the `Gemfile` (notable gems: `nokogiri`, `httparty`, `rspec`).

---

## Installation

```bash
git clone <repo-url>
cd tv_program_scraper
bundle install
```

---

## Usage

Start the CLI:

```bash
ruby scrape.rb
```

- Enter a date in `YYYY-MM-DD` format or press Enter to use today's date
- The scraper will attempt API fetching first, then fallback to HTML parsing
- Optionally save the fetched schedule as `tv_programs.json`

Helper scripts:

```bash
ruby scripts/discover_api.rb
ruby scripts/inspect_page.rb
```

---

## Output

Saved output is an array of program objects in `tv_programs.json`, for example:

```json
{
  "channel": "DR1",
  "start_time": "2025-12-31T20:00:00+01:00",
  "title": "Evening News",
  "end_time": "2025-12-31T20:30:00+01:00"
}
```

Console output is a human-readable table showing Channel, Start, End and Title.

---

## Tests

Run unit tests with RSpec:

```bash
bundle exec rspec
```

---

## Development notes

- Consider adding tests that record HTTP responses (VCR/WebMock) to stabilize parsing tests
- Add configurable logging and a `--verbose` flag for troubleshooting
- Respect site terms, rate limits, and robots policies when scraping

---

## License

See the `LICENSE` file if present.

