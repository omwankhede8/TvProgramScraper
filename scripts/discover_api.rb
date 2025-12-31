require 'httparty'
require 'nokogiri'

url = 'https://www.dr.dk/drtv/tv-guide'
puts "Fetching #{url}..."
html = HTTParty.get(url).body

doc = Nokogiri::HTML(html)
script_srcs = doc.css('script[src]').map { |s| s['src'] }.compact.uniq
puts "Found #{script_srcs.length} script srcs"

script_srcs.each do |src|
  full = src.start_with?('http') ? src : URI.join('https://www.dr.dk', src).to_s
  puts "--- #{full} ---"
  begin
    js = HTTParty.get(full, timeout: 10).body[0, 200_000]
    api_matches = js.scan(/https?:\/\/[^"]+\/api[^"'\s]*/i).uniq
    api_matches += js.scan(/\/api\/[a-z0-9_\-\/\.=?&%+]*/i).uniq
    puts "API matches (#{api_matches.length}):"
    puts api_matches.uniq.join("\n")

    interesting = js.scan(/.{0,80}(program|tv|guide|schedule|startTime|broadcast|episode).{0,80}/i).uniq
    puts "Interesting matches (#{interesting.length}):"
    puts interesting.join("\n\n")
  rescue => e
    puts "(failed to fetch: #{e.message})"
  end
end
