require 'rubygems'
require 'mechanize'
require 'json'

class MfData



   def get(username, password)
     login(username, password) do

       each_character do

         {
           character: character_info,
           buildings: buildings,
           troops: troops
         }

       end

     end
   end

   def login(username, password)
     @agent = Mechanize.new
     @page = @agent.get('http://mightandfealty.com/en/login')

     login = @page.forms.first

     login._username = username
     login._password = password

     @page = @agent.submit(login)

     yield

   end

   def each_character

     @page = @agent.get('http://mightandfealty.com/en/account/characters')

     return @page.links.select{|l| l.to_s == "Play" }.map  do |l|

       url = "http://mightandfealty.com#{l.uri}"
       @page = @agent.get(url)

       yield

     end

  end

  def character_info

    character = @page.search(".//div[@id='identity']//a[@class='link_character']").first.children.first.to_s
    settlement = @page.search(".//div[@id='identity']//a").last.children.first.to_s

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

        data[:ready] << {name: name, equipment: equipment}
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


end

if(ARGV.size > 0)
  characters = MfData.new.get(ARGV[0], ARGV[1])
  pp characters
  #JSON.pretty_print(characters)
end
