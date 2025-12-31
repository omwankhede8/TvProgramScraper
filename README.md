# TV Program Scraper

A small Ruby CLI that fetches TV schedules and normalizes them into `Program` objects.
It prefers site APIs and falls back to HTML when needed.

## Quick start

Requirements: Ruby 2.7+ and Bundler.

Install:

```bash
git clone <repo-url>
cd tv_program_scraper
bundle install
```

Run:

```bash
ruby scrape.rb
```

Enter a date in `YYYY-MM-DD` or press Enter for today. When prompted you can save results to `tv_programs.json`.

