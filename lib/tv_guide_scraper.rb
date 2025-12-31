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
    programs = parse_programs(html)
    return programs if programs && programs.any?

    # If HTML parsing didn't find anything, try discovering API endpoints and fetching JSON schedules
    puts "⚡ No programs found in page HTML — trying site APIs..."
    api_candidates = find_api_urls(html)

    # Keep date handy for later queries
    iso_date = @date.respond_to?(:iso8601) ? @date.iso8601 : @date.to_s

    # Known page API used by the site (inspect_page.rb uses a full variant below)
    api_candidates << "https://prod95-cdn.dr-massive.com/api/page?device=web_browser&ff=idp%2Cldp%2Crpt&include=sitemap%2Cnavigation%2Cgeneral%2Ci18n%2Cplayback%2Clinear%2CfeatureFlags&lang=da&segments=drtv%2Coptedin&sub=Anonymous2&path=%2Ftv-guide&text_entry_format=html"
    api_candidates.uniq!
    # Filter obvious non-API/noise endpoints (images/analytics etc.)
    api_candidates.reject! { |u| u =~ /ResizeImage|dataservice|shain|massiveanalytics|static\.dr-massive|&#x27;/i }
    puts "🔍 API candidates found: #{api_candidates.size}"

    api_candidates.each do |url|
      # puts "→ trying: #{url}"
      body = fetch_json(url) rescue nil
      next unless body

      # Minimal inspection of JSON responses
      begin
        if body.is_a?(Hash) && body['entries'].is_a?(Array)
          puts "  → page API entries: #{body['entries'].length}"

          # collect channel tiles
          channels = body['entries'].flat_map { |e| (e.dig('list','items') || []) }

          # Try schedules by channel ids (batch GET)
          channel_ids = channels.map { |c| c['id'] }.compact.map(&:to_s).uniq
          if channel_ids.any?
            channels_url = "https://prod95-cdn.dr-massive.com/api/schedules?channels=#{CGI.escape(channel_ids.join(','))}&date=#{CGI.escape(iso_date)}&device=web_browser&duration=24&hour=0&ff=idp%2Cldp%2Crpt&segments=drtv%2Coptedin&sub=Anonymous2&lang=da"
            puts "  → trying schedules for #{channel_ids.size} channel ids"
            sbody = fetch_json(channels_url) rescue nil
            if sbody
              programs = parse_programs_from_json(sbody)
              if programs && programs.any?
                puts "✅ Found #{programs.size} programs from channel schedules GET"
                return programs
              end
            end
          end

          # Try candidate per-service URLs
          schedule_candidates = build_schedule_candidates(channels, iso_date)
          schedule_candidates.each do |surl|
            sbody = fetch_json(surl) rescue nil
            next unless sbody
            programs = parse_programs_from_json(sbody)
            if programs && programs.any?
              puts "✅ Found #{programs.size} programs from schedule API"
              return programs
            end
          end

          # Fallback: POST batch query
          services = channels.map { |c| c['customId'] || c['channelShortCode'] || c['channel'] }.compact.uniq
          if services.any?
            post_url = 'https://prod95-cdn.dr-massive.com/api/schedules'
            payload = { 'channels' => services, 'hour' => 0, 'duration' => 24, 'date' => iso_date }
            begin
              resp = HTTParty.post(post_url, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json', 'User-Agent' => 'Mozilla/5.0 (compatible; TVGuideScraper/1.0)' }, body: payload.to_json, timeout: 15)
              if resp && resp.success?
                sbody = JSON.parse(resp.body) rescue nil
                programs = parse_programs_from_json(sbody)
                if programs && programs.any?
                  puts "✅ Found #{programs.size} programs from POST schedule query"
                  return programs
                end
              else
                puts "  → POST schedule non-success: HTTP #{resp&.code}"
              end
            rescue StandardError => e
              puts "  → POST schedule error: #{e.message}"
            end
          end
        end
      rescue StandardError => e
        puts "  → inspect error: #{e.message}"
      end

      programs_from_json = parse_programs_from_json(body)
      if programs_from_json && programs_from_json.any?
        puts "✅ Found #{programs_from_json.size} programs from API: #{url}"
        return programs_from_json
      end
    end

    programs || []
  end
  
  private  # These are helper methods (robot's internal tools)
  
  def fetch_page
    resp = HTTParty.get(BASE_URL, headers: { 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36' }, timeout: 10)
    resp.success? ? resp.body : nil
  rescue StandardError => e
    puts "  → fetch_page error: #{e.message}"
    nil
  end

  def fetch_json(url)
    return nil unless url
    resp = HTTParty.get(url, headers: { 'Accept' => 'application/json', 'User-Agent' => 'Mozilla/5.0 (compatible; TVGuideScraper/1.0)' }, timeout: 10)
    unless resp && resp.success?
      puts "  → fetch_json non-success for #{url}: HTTP #{resp&.code}"
      return nil
    end

    JSON.parse(resp.body)
  rescue StandardError => e
    puts "  → fetch_json error for #{url}: #{e.message}"
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
  def find_api_urls(html)
    return [] unless html
    urls = []
    doc = Nokogiri::HTML(html)

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
    items = case
    when json.is_a?(Hash) && json['entries'].is_a?(Array)
      json['entries'].flat_map { |e| e.dig('list','items') || [] }.map do |it|
        {
          'channel' => it['channelShortCode'] || it['channel'] || it['channelName'] || it['service'],
          'title' => it['title'] || it['name'] || it['programTitle'] || 'No title',
          'start_time' => it['startTime'] || it['broadcastStart'] || it['broadcastStartDate'],
          'end_time' => it['endTime'] || it['broadcastEnd'] || it['broadcastEndDate']
        }
      end

    when json.is_a?(Array) && json.any? { |e| e.is_a?(Hash) && e.key?('schedules') }
      json.flat_map { |ch| ch['schedules'] || [] }.map do |s|
        {
          'channel' => s['broadcastChannel'] || s['channelId'],
          'title' => s.dig('item','title') || s['title'] || 'No title',
          'start_time' => s['startDate'] || s['startTimeInDefaultTimeZone'],
          'end_time' => s['endDate'] || s['endTimeInDefaultTimeZone']
        }
      end

    when json.is_a?(Hash)
      json['programs'] || json['items'] || json['results'] || json['data'] || json.values.find { |v| v.is_a?(Array) && v.any? { |i| i.is_a?(Hash) && (i['title'] || i['name']) } } || []
    when json.is_a?(Array)
      json
    else
      []
    end

    return nil if items.nil? || !items.is_a?(Array) || items.empty?

    items.each_with_object([]) do |item, results|
      channel = item['channel'] || item['channelName'] || item['station'] || item['stationName'] || item['service']
      title = item['title'] || item['name'] || item['programTitle'] || 'No title'
      start_time = item['start_time'] || item['startTime'] || item['start'] || item['startTimeLocal'] || item['broadcastStart']
      end_time = item['end_time'] || item['endTime'] || item['end'] || item['endTimeInDefaultTimeZone'] || item['broadcastEnd']

      start_time = (start_time.is_a?(String) && start_time.include?('T')) ? start_time : normalize_time(start_time)
      end_time = (end_time.is_a?(String) && end_time.include?('T')) ? end_time : normalize_time(end_time)

      next unless start_time && end_time

      begin
        results << Program.from_h(channel: channel || 'Unknown', start_time: start_time, title: title, end_time: end_time)
      rescue ArgumentError
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
      t = value > 1_000_000_000_000 ? value / 1000 : value
      Time.at(t).strftime('%H:%M') rescue value.to_s
    elsif value.is_a?(String)
      Time.parse(value).strftime('%H:%M') rescue value
    else
      value.to_s
    end
  end

  # Parse a "HH:MM - HH:MM" style time range into [start, end]
  def parse_time_range(text)
    return [nil, nil] if text.to_s.strip.empty?
    parts = text.to_s.split(/[-–—]/, 2).map(&:strip)
    [parts[0], parts[1]]
  end
end