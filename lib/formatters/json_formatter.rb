require 'json'

class JSONFormatter
  # Convert programs to JSON format
  def self.format(programs)
    data = programs.map(&:to_h)
    JSON.pretty_generate(data)
  end
  
  # Save JSON to a file"
  def self.save(programs, filename = "tv_programs.json")
    File.write(filename, format(programs))
    puts "💾 Saved to #{filename}"
  end
end