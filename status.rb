require_relative 'data'

class Status

  def self.get(characters)

    puts ""
    puts "STATUS:"
    
    characters.each do |c|

      messages = []

      if(c[:buildings][:finished])

        c[:buildings][:under_construction].delete_if {|b| b[:workers] < 5 }

        if(c[:buildings][:under_construction].nil? || c[:buildings][:under_construction].size == 0)
          messages << "NO BUILDINGS UNDER CONSTRUCTION!"
        end

        if(c[:troops][:in_training].nil? && c[:buildings][:finished].include?('Garrison'))
          messages << "NO TROOPS IN TRAINING!"
        end

      end

      if(messages.size > 0)
        puts ""
        puts "#{c[:character][:name]} in #{c[:character][:settlement]}:"
        messages.each {|m| puts m }
      end

    end
    return nil
  end
end

if(ARGV.size > 0)
  characters = MfData.new.get(ARGV[0], ARGV[1])
  Status.get(characters)
end
