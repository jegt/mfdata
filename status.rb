require 'hirb'
require_relative 'data'


class Status

  def self.get(characters)

    puts ""
    puts "ESTATES:"

    estates = []
    characters.each do |c|
      c[:estates].each do |e|
        estates << {
                     character: c[:character][:name],
                     name: e[:name],
                     size: e[:population],
                     militia: e[:militia],
                     recruits: e[:recruits],
                     development: e[:development],
                     constructing: e[:constructing].join(', ')
                   }
      end
#      c[:estates].each do |e|
#        puts "#{c[:character][:name]}\t#{e[:name]}\t#{e[:population]}\t#{e[:militia]} (#{e[:recruits]})\t#{e[:development]}\t#{e[:constructing].join(', ')}"
#      end
    end
    puts Hirb::Helpers::AutoTable.render(estates, fields: [:character, :name, :size, :development, :militia, :recruits, :constructing])


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
