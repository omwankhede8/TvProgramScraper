require 'time'
require 'json'

class Program
  include Comparable

  attr_reader :channel, :start_time, :title, :end_time

  # Initialize a new TV program with these details.
  # start_time and end_time may be Time objects or parseable Strings.
  def initialize(channel:, start_time:, title:, end_time:)
    @channel = channel.to_s.freeze
    @start_time = parse_time(start_time)
    @title = title.to_s.freeze
    @end_time = parse_time(end_time)

    validate_times!

    freeze
  end

  # Build from a hash with string or symbol keys, parsing times if needed.
  def self.from_h(hash)
    new(
      channel: hash[:channel] || hash['channel'],
      start_time: hash[:start_time] || hash['start_time'],
      title: hash[:title] || hash['title'],
      end_time: hash[:end_time] || hash['end_time']
    )
  end

  # Convert to a standard hash with ISO 8601 time strings.
  def to_h
    {
      channel: channel,
      start_time: start_time.iso8601,
      title: title,
      end_time: end_time.iso8601
    }
  end

  # JSON representation (uses `to_h`).
  def to_json(*args)
    JSON.generate(to_h, *args)
  end

  # Duration in seconds as an Integer.
  def duration
    (end_time - start_time).to_i
  end

  # Comparable by start_time, then channel.
  def <=>(other)
    return nil unless other.is_a?(Program)
    cmp = start_time <=> other.start_time
    return cmp unless cmp == 0
    channel <=> other.channel
  end

  # Equality and hashing suitable for use in Sets.
  def ==(other)
    other.is_a?(Program) &&
      channel == other.channel &&
      start_time == other.start_time &&
      title == other.title &&
      end_time == other.end_time
  end
  alias eql? ==

  def hash
    [channel, start_time, title, end_time].hash
  end

  def to_s
    "#{channel} | #{start_time.iso8601} - #{end_time.iso8601} | #{title}"
  end

  private

  def parse_time(value)
    return value if value.is_a?(Time)
    Time.parse(value.to_s)
  rescue ArgumentError
    raise ArgumentError, "invalid time: #{value.inspect}"
  end

  def validate_times!
    raise ArgumentError, 'start_time must be a Time' unless start_time.is_a?(Time)
    raise ArgumentError, 'end_time must be a Time' unless end_time.is_a?(Time)
    raise ArgumentError, 'end_time must be >= start_time' if end_time < start_time
  end
end