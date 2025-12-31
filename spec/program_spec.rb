require_relative 'spec_helper'
require 'set'

RSpec.describe Program do
  let(:start) { '2025-12-31 20:00' }
  let(:finish) { '2025-12-31 21:00' }

  it 'parses string times and computes duration' do
    p = Program.new(channel: 'BBC', start_time: start, title: 'Show', end_time: finish)

    expect(p.start_time).to be_a(Time)
    expect(p.end_time).to be_a(Time)
    expect(p.duration).to eq(3600)
  end

  it 'raises if end_time is before start_time' do
    expect {
      Program.new(channel: 'BBC', start_time: '2025-12-31 20:00', title: 'Backwards', end_time: '2025-12-31 19:00')
    }.to raise_error(ArgumentError, /end_time must be >= start_time/)
  end

  it 'to_h returns ISO 8601 time strings' do
    p = Program.new(channel: 'BBC', start_time: start, title: 'Show', end_time: finish)
    h = p.to_h

    expect(h[:start_time]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:/)
    expect(h[:end_time]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:/)
  end

  it 'is comparable and sortable by start_time' do
    p1 = Program.new(channel: 'A', start_time: '2025-12-31 08:00', title: 'a', end_time: '2025-12-31 09:00')
    p2 = Program.new(channel: 'B', start_time: '2025-12-31 07:00', title: 'b', end_time: '2025-12-31 08:00')
    expect([p1, p2].sort).to eq([p2, p1])
  end

  it 'supports equality and can be used in a Set' do
    p1 = Program.new(channel: 'X', start_time: '2025-12-31 10:00', title: 'X', end_time: '2025-12-31 11:00')
    p2 = Program.new(channel: 'X', start_time: '2025-12-31 10:00', title: 'X', end_time: '2025-12-31 11:00')

    expect(p1).to eq(p2)
    expect(Set.new([p1, p2]).size).to eq(1)
  end

  it 'builds from a hash with string keys' do
    h = { 'channel' => 'BBC', 'start_time' => start, 'title' => 'Show', 'end_time' => finish }
    p = Program.from_h(h)

    expect(p).to be_a(Program)
    expect(p.channel).to eq('BBC')
  end
end
