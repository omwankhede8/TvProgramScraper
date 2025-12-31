require 'date'
require_relative 'lib/tv_guide_scraper'
require_relative 'lib/formatters/console_formatter'
require_relative 'lib/formatters/json_formatter'

puts "TV Program Scraper"

print "Enter date (YYYY-MM-DD) or press Enter for today: "
date_input = gets.chomp

date = if date_input.strip.empty?
  Date.today
else
  begin
    Date.parse(date_input)
  rescue ArgumentError
    Date.today
  end
end

scraper = TVGuideScraper.new(date)
programs = scraper.scrape

ConsoleFormatter.display(programs)

print "Save to tv_programs.json? (y/n): "
answer = gets.chomp.downcase
JSONFormatter.save(programs) if answer == 'y'