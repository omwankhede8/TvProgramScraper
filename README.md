# TV Program Scraper 🎬

A small, object-oriented Ruby CLI that scrapes TV program normalizes the data into `Program` objects, and displays or saves the schedule as JSON.

---

## Features ✅

- Fetches TV guide data for a chosen date
- Prefers official page APIs when available, falls back to HTML parsing with Nokogiri
- Normalizes data into immutable `Program` objects (channel, start_time, end_time, title)
- Outputs nicely formatted console table or pretty JSON file (`tv_programs.json`)
- Includes helpful scripts for API discovery and page inspection

---

## Project Structure 🔧

- `scrape.rb` — interactive CLI entry point
- `lib/tv_guide_scraper.rb` — main scraper class and parsing logic
- `lib/program.rb` — `Program` model (time parsing, validation, serialization)
- `lib/formatters/console_formatter.rb` — console output
- `lib/formatters/json_formatter.rb` — JSON output + save helper
- `scripts/discover_api.rb` — helper script to find API endpoints
- `scripts/inspect_page.rb` — helper script to inspect page JSON
- `spec/` — unit tests for core model behavior (RSpec)

---

## Requirements & Dependencies 🧩

- Ruby (tested on Ruby 2.7+ or 3.x)
- Bundler

Gems used (listed in `Gemfile`):
- `nokogiri` — HTML/XML parsing
- `httparty` — HTTP requests
- `colorize` — colored console output
- `rspec` — tests

---

## Installation & Setup ⚙️

1. Clone the repository

```bash
git clone <repo-url>
cd tv_program_scraper
```

2. Install dependencies

```bash
bundle install
```

---

## Usage — Run the scraper ▶️

Start the interactive CLI:

```bash
ruby scrape.rb
```

- Enter a date in `YYYY-MM-DD` format, or press Enter to use today's date
- The script will attempt API-based fetching first, then fall back to HTML parsing
- Choose whether to save results as JSON at the end

Helper scripts:

```bash
ruby scripts/discover_api.rb   # scan site scripts for /api/ endpoints
ruby scripts/inspect_page.rb   # inspect the page API payloads
```

---

## Output format 📄

When saved, programs are written as an array of objects in `tv_programs.json`. Each object has:

```json
{
  "channel": "DR1",
  "start_time": "2025-12-31T20:00:00+01:00",
  "title": "Evening News",
  "end_time": "2025-12-31T20:30:00+01:00"
}
```

Console display is a simple table showing Channel, Start, End and Program Title.

---

## Tests ✅

Run unit tests with RSpec:

```bash
bundle exec rspec
```

(Existing tests validate the `Program` model: time parsing, duration, comparability, and equality.)

---

## Deliverables (for submission) 📝

- Ruby source files (already in this repo)
- `README.md` (this file) — includes dependencies, installation, instructions, output format
- Sample output: after running `ruby scrape.rb` and choosing to save, check `tv_programs.json` for a sample run

---

## Notes & Next steps 💡

- The scraper is resilient but scraping may be brittle; consider adding VCR/WebMock integration for stable tests, rate limiting, better logging, and CI.
- Be mindful of legal/ethical scraping rules (robots.txt, rate limits, and terms of service).

---

If you want, I can also:
- Add a sample `tv_programs.json` file with recorded output
- Create a short `INTERVIEW_NOTES.md` summarizing how to present this project in an interview

---

Good luck with the submission — let me know if you'd like me to add the sample output or interview notes! 
