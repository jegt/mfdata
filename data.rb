require 'rubygems'
require 'mechanize'
require 'json'

class MfData

  attr_accessor :agent,:page

   def get(username, password)
     login(username, password) do

       each_character do

         {
           character: character_info,
           buildings: buildings,
           troops: troops,
           estates: estates
         }

       end

     end
   end

   def login(username, password)
     @agent = Mechanize.new
     @agent.ignore_bad_chunking = true
     @agent.keep_alive = false
     
     puts "Loggin in..."
     @page = @agent.get('http://mightandfealty.com/en/login')

     login = @page.forms.first

     login._username = username
     login._password = password

     @page = @agent.submit(login)

     yield(self)

   end

   def character(name)
     puts "Listing characters..."
     @page = @agent.get('http://mightandfealty.com/en/account/characters')

     play = nil
     table = @page.search(".//div[@class='maincontent']//table").first
     table.search(".//tr").each do |tr|
       tds = tr.search(".//td")
       if(tds.size == 8 && tds[1].text.strip == name.strip)
         play = tds.last.search(".//a").first.attributes['href'].value
         break
       end
     end

     if(play)
       url = "http://mightandfealty.com#{play}"
       @page = @agent.get(url)
       yield(self)
     else
       raise "No character found with name #{name}"
     end

   end

   def each_character

     puts "Listing characters..."
     @page = @agent.get('http://mightandfealty.com/en/account/characters')

     return @page.links.select{|l| l.to_s == "Play" }.map  do |l|

       url = "http://mightandfealty.com#{l.uri}"
       @page = @agent.get(url)

       yield(self)

     end

  end

  def character_info

    character = @page.search(".//div[@id='identity']//a[@class='link_character']").first.children.first.to_s
    settlement = @page.search(".//div[@id='identity']//a").last.children.first.to_s

    puts "#{character} in #{settlement}..."

    {name: character, settlement: settlement}

  end


  def buildings

    buildings = @agent.page.link_with(:text => 'Buildings')
    building = nil
    building_progress = nil
    data = {}

    if(buildings)

      @page = buildings.click

      tr = @page.search(".//table[@id='buildingslist']//tbody//tr")

      data[:finished] = []

      tr.each do |b|
        building = b.search(".//a[@class='link_building']").children.first.to_s
        data[:finished] << building
      end

      tr = @page.search(".//table[@id='buildingslist2']//tbody//tr")

      data[:under_construction] = []

      tr.each do |b|

        building = b.search(".//a[@class='link_building']").children.first.to_s
        p = b.search(".//div[@class='progressbar']").first
        building_progress = p.attributes['value'].value.to_i if p

        workers = b.search(".//input").first.attributes['value'].value.to_f

        data[:under_construction] << {name: building, progress: building_progress, workers: workers}
      end
    end

    return data
  end



  def troops
    troops = @agent.page.link_with(:text => 'manage militia')
    count = 0
    data = {}

    if(troops)
      @page = troops.click

      troop_segments = @page.search("//tbody")

      list = troop_segments.first
      data[:ready] = []
      list.search(".//tr").each do |tr|
        equipment = tr.search(".//a[@class='link_equipment']").map{|l| l.text}
        name = tr.search(".//td").first.text
        troop_id = tr.search(".//td/a").last.attributes['href'].value.split('/').last.to_i

        data[:ready] << {id: troop_id, name: name, equipment: equipment}
      end


      if(troop_segments.size > 1)
        list = troop_segments.last

        data[:in_training] = []

        list.search(".//tr").each do |tr|
          equipment = tr.search(".//a[@class='link_equipment']").map{|l| l.text}
          p = tr.search(".//div[@class='progressbar']").first
          troop_progress = p.attributes['value'].value.to_i if p

          data[:in_training] << {equipment: equipment, progress: troop_progress}
        end

      end

    end

    return data
  end


  def soldiers
    count = 0
    @page = @agent.get("http://mightandfealty.com/en/character/soldiers")

    troop_segments = @page.search("//tbody")

    list = troop_segments.first
    data = []
    list.search(".//tr").each do |tr|
      equipment = tr.search(".//a[@class='link_equipment']").map{|l| l.text}
      name = tr.search(".//td").first.text
      troop_id = tr.search(".//td/a").last.attributes['href'].value.split('/').last.to_i

      data << {id: troop_id, name: name, equipment: equipment}
    end

    return data
  end


  def estates
    estates = @agent.page.link_with(:text => /estate/)
    data = []

    if(estates)
      @page = estates.click

      data = @page.search(".//table[@id='estates']//tbody//tr").map do |tr|
        name = tr.search(".//a").first.text
        tds = tr.search(".//td")
        size = tds[3].text
        population = tds[4].text.to_i
        development = tds[5].text.strip
        militia = tds[6].text.to_i
        recruits = tds[7].text.to_i
        constructing = tds[8].text.lines.map {|b| b.strip}.select{|b| b.size > 0}
        {
          name: name,
          size: size,
          population: population,
          development: development,
          militia: militia,
          recruits: recruits,
          constructing: constructing
        }
      end

    end

    return data
  end

end

if(__FILE__ == 'data.rb' && ARGV.size > 0)
  puts "Downloading data..."
  characters = MfData.new.get(ARGV[0], ARGV[1])
  pp characters
end
