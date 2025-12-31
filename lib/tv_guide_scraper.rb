# This is our main scraping robot!
require 'nokogiri'
require 'httparty'
require 'date'
require 'json'
require 'uri'
require 'time'
require 'cgi'
require_relative 'program' 

class TVGuideScraper
  BASE_URL = "https://www.dr.dk/drtv/tv-guide"
  
  def initialize(date = nil)
    @date = date || Date.today  # Use today if no date given
    @programs = []  # Empty basket for programs we find
  end
  
  def scrape
    html = fetch_page
    parse_programs(html)
  end
  
  private  # These are helper methods (robot's internal tools)
  
  def fetch_page
    resp = HTTParty.get(BASE_URL)
    resp.success? ? resp.body : nil
  rescue StandardError
    nil
  end
  
  def parse_programs(html)
    return [] unless html

    doc = Nokogiri::HTML(html)
    nodes = doc.css('.schedule-event, .program, .program-item, .schedule-item, .event, li.program')

    nodes.map do |n|
      channel = n.at_css('.channel')&.text&.strip || n['data-channel'] || 'Unknown'
      title   = n.at_css('.title, .program-title, .event-title')&.text&.strip || n['title'] || 'No title'
      time_text = n.at_css('.time, .time-range, .event-time')&.text&.strip || (n['data-start'] && n['data-end'] && "#{n['data-start']} - #{n['data-end']}")

      start_time, end_time = parse_time_range(time_text)

      begin
        Program.from_h(channel: channel, start_time: start_time, title: title, end_time: end_time)
      rescue ArgumentError
        nil
      end
    end.compact
  end



  # Find potential API endpoints by scanning script bundles and page HTML
  

    # Script srcs
    doc.css('script[src]').each do |s|
      src = s['src']
      src = src.start_with?('http') ? src : URI.join(BASE_URL, src).to_s rescue nil
      next unless src

      begin
        js = HTTParty.get(src).body[0, 200_000] # limit size
        urls += js.scan(/https?:\/\/[^"']+\/api[^"' \s]*/i)
        js.scan(/\/api\/[a-z0-9_\-\/.=?&%+]*/i).each do |path|
          begin
            urls << URI.join('https://www.dr.dk', path).to_s
          rescue
            urls << path
          end
        end
      rescue StandardError
        next
      end
    end

    # Also scan the HTML itself
    urls += html.scan(/https?:\/\/[^"']+\/api[^"' \s]*/i)
    urls.uniq
  end

  # Try to fetch schedules by calling the site's page API and then /api/schedules
  

  # Add or replace a date query parameter on candidate API URLs
  

  # Convert site JSON to Program objects, trying a few common shapes
  def parse_programs_from_json(json)
    arr = nil

    # Handle dr-massive "schedules" shape
    if json.is_a?(Array) && json.any? { |e| e.is_a?(Hash) && e.key?('schedules') }
      schedules = json.flat_map { |ch| ch['schedules'] || [] }
      arr = schedules.map do |s|
        {
          'channel' => s['broadcastChannel'] || s['channelId'],
          'title' => s.dig('item', 'title') || s['title'] || 'No title',
          'start_time' => s['startDate'] || s['startTimeInDefaultTimeZone'],
          'end_time' => s['endDate'] || s['endTimeInDefaultTimeZone']
        }
      end
    elsif json.is_a?(Hash)
      arr = json['programs'] || json['items'] || json['results'] || json['data'] || json.values.find { |v| v.is_a?(Array) && v.any? { |i| i.is_a?(Hash) && (i['title'] || i['name']) } }
    elsif json.is_a?(Array)
      arr = json
    end

    return nil unless arr && arr.is_a?(Array)

    arr.each_with_object([]) do |item, results|
      channel = item['channel'] || item['channelName'] || item['station'] || item['stationName'] || item['service']
      title = item['title'] || item['name'] || item['programTitle'] || item['title'] || 'No title'
      start_time = item['start_time'] || item['startTime'] || item['start'] || item['startTimeLocal'] || item['broadcastStart']
      end_time = item['end_time'] || item['endTime'] || item['end'] || item['endTimeInDefaultTimeZone'] || item['broadcastEnd']

      # Preserve ISO datetime strings (contain 'T'), otherwise normalize to HH:MM where possible
      start_time = (start_time.is_a?(String) && start_time.include?('T')) ? start_time : normalize_time(start_time)
      end_time   = (end_time.is_a?(String) && end_time.include?('T')) ? end_time : normalize_time(end_time)

      # Skip items without both start and end times
      if start_time.nil? || end_time.nil?
        puts "⚠️ Skipping JSON item without start or end time: #{title.inspect}"
        next
      end

      begin
        results << Program.from_h(channel: channel || 'Unknown', start_time: start_time, title: title, end_time: end_time)
      rescue ArgumentError => e
        puts "⚠️ Skipping program from JSON due to invalid times: #{e.message} (#{title.inspect})"
        next
      end
    end
  rescue StandardError => e
    puts "⚠️ Error parsing JSON programs: #{e.message}"
    nil
  end

  # Try to convert various time formats to HH:MM
  def normalize_time(value)
    return nil if value.nil?

    if value.is_a?(Numeric)
      # ms or s
      if value > 1_000_000_000_000
        Time.at(value / 1000).strftime('%H:%M') rescue value.to_s
      else
        Time.at(value).strftime('%H:%M') rescue value.to_s
      end
    elsif value.is_a?(String)
      begin
        Time.parse(value).strftime('%H:%M')
      rescue
        value
      end
    else
      value.to_s
    end
  end

  # Parse a "HH:MM - HH:MM" style time range into [start, end]
  def parse_time_range(text)
    return [nil, nil] if text.nil? || text.to_s.strip.empty?
    parts = text.to_s.split(/[-–—]/).map(&:strip)
    [parts[0], parts[1]]
  end
  
end