require 'colorize'

class ConsoleFormatter
  # Display Program in nice table"
  def self.display(programs)
    puts "\n" + "=" * 80
    puts "📺 TV PROGRAM SCHEDULE".center(80).green.bold
    puts "=" * 80
    
    puts "\nChannel".ljust(15) + "Start".ljust(10) + "End".ljust(10) + "Program Title"
    puts "-" * 80
    
    programs.each_with_index do |program, index|
      start_str = program.start_time.is_a?(Time) ? program.start_time.strftime('%H:%M') : program.start_time.to_s
      end_str = program.end_time.is_a?(Time) ? program.end_time.strftime('%H:%M') : program.end_time.to_s

      puts "#{program.channel.to_s.ljust(15)}" +
           "#{start_str.ljust(10)}" +
           "#{end_str.ljust(10)}" +
           "#{program.title}"
    end
    
    puts "-" * 80
    puts "Total: #{programs.length} programs".blue
  end
end