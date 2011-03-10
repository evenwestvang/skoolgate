class Massage < Thor

  # Don't read this code.

  desc "geolocate_admin_units", "Geolocate administrative units"
  def geolocate_admin_units
    require 'geokit'
    require './environment'
    Geokit::Geocoders::google = ENV['GOOGLE_GEOCODING_KEY']
    munis = Municipality.find(:all, :conditions => {:location => nil}).asc(:name)
    munis.each do |muni|
      search_string = "#{muni.name}, #{muni.in_county}"
      puts "** looking for muni #{search_string}"
      res = Geokit::Geocoders::GoogleGeocoder.geocode(search_string, :bias => 'no')
      if res.success?
        puts res
        muni.location = [res.lat, res.lng]
        muni.save!
        success = true
      else
        puts "Meh – failed for #{search_string}."
      end
    end
    munis = County.find(:all, :conditions => {:location => nil}).asc(:name)
    munis.each do |muni|
      search_string = "#{muni.name}"
      puts "** looking for county #{search_string}"
      res = Geokit::Geocoders::GoogleGeocoder.geocode(search_string, :bias => 'no')
      if res.success?
        puts res
        muni.location = [res.lat, res.lng]
        muni.save!
        success = true
      else
        puts "Meh – failed for #{search_string}."
      end
    end
  end

  desc "calculate_averages", "Run the stats for schools, munis and counties"
  def calculate_averages
    require './environment'
    puts "Calculating school avgs"
    School.all.each do |s|
     normalized = s.test_results.map { |result| result.normalized_result }.compact
     s.result_average = (normalized.inject { |a, b| a + b }) / normalized.length unless normalized.empty?
     puts s.result_average
     s.save!
    end
    puts "Muni school avgs"
    Municipality.all.each do |muni|
      avgs = School.find(:all, :conditions => {:municipality => muni.name}).map(&:result_average).compact
      muni.result_average = (avgs.inject { |a, b| a + b }) / avgs.length unless avgs.empty?
      body_count = School.find(:all, :conditions => {:municipality => muni.name}).map(&:student_body_count).compact
      muni.student_body_count = (body_count.inject { |a, b| a + b }) unless body_count.empty?
      muni.save!
    end
    puts "Calculating county avgs"
    County.all.each do |county|
      avgs = School.find(:all, :conditions => {:county => county.name}).map(&:result_average).compact
      county.result_average = (avgs.inject { |a, b| a + b }) / avgs.length unless avgs.empty?
      county.save!
    end
  end

  desc "get_student_body_count", "How many students abound? ** Warning ≈10% error rate"
  def get_student_body_count
    require './environment'
    require 'nokogiri'
    require 'CGI'
    require 'open-uri'
    require 'json/pure'

    schools_to_scrape = School.find(:all, :conditions => {:student_body_count => nil}).asc(:name)
    puts "We have #{schools_to_scrape.count} schools left to count"
    schools_to_scrape.each_with_index do |s, i|
      puts "Looking for body count at school #{s.name}"
      name = s.name.gsub('Grunnskole', '') # term seems to be deprecated
      #http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=Paris%20Hilton&key=INSERT-YOUR-KEY
      url = "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=" + CGI.escape("site:skoleporten.utdanningsdirektoratet.no skolefakta -\"Alle skoler med adresse\" \"#{s.municipality}\" #{name} #{s.address}")
      puts "Google: #{url}"
      json = JSON.parse(open(url).read)
      if json["responseData"].nil?
        raise "Borked by #{s.name} // #{s.url}"
      end
      json["responseData"]["results"].each_with_index do |result, result_index|
        unescapedUrl = result["unescapedUrl"]
        puts "Skoleporten: #{unescapedUrl}"
        embed_path = open(unescapedUrl).read.match(/(RapportHandler\.ashx.*?)\'/)
        if embed_path.nil? or embed_path[1].nil?
          puts "No document embedder found – skipping" 
          next
        end
        puts "Embedded document: #{embed_path[1]}"
        doc = Nokogiri::HTML(open("http://skoleporten.utdanningsdirektoratet.no/"+embed_path[1]))

        # last cell of second row
        rows = doc.css('table tr')[1]
        if rows.nil?
          puts "No table on this page - skip" 
          next
        end
        value = rows.css('td')[-1].text.to_i

        if value and value != 0
          puts "\n*** Found #{value} for #{s.name}\n"
          s.student_body_count = value
          s.save!
          break
        end
        puts "Nothing found – attempt ##{result_index}"
        sleep 0.5
      end
    end
  end

  desc "geocode_schools", "Ask google where unlocated schools are"
  def geocode_schools
    require './environment'
    require 'nokogiri'
    require 'CGI'
    require 'open-uri'
    require 'geokit'
    Geokit::Geocoders::google = ENV['GOOGLE_GEOCODING_KEY']
    schools = School.find(:all, :conditions => {:location => nil}).asc(:name)
    puts "\nGeocoding #{schools.count} schools. Plz wait.\n\n"
    schools.each_with_index do |s, i| 
      success = false
      puts "##{i} #{s.name} / #{s.county} / #{s.municipality} (#{s.test_results.length} tests)"
      name = s.name.gsub('Grunnskole', '') # term seems to be deprecated
      url = "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q="  + CGI.escape("site:skoleporten.utdanningsdirektoratet.no \"#{s.municipality}\" #{name}")
      puts "Googling for #{url}"
      json = JSON.parse(open(url).read)
      json["responseData"]["results"].each_with_index do |result, result_index|
        unescapedUrl = result["unescapedUrl"]
        puts "Skoleporten: #{unescapedUrl}"
        doc = Nokogiri::HTML(open(unescapedUrl))
        school_name = doc.css('#hovedinnhold .heading7').text
        puts "!!! We have a match on name" if school_name == name
        raw_address = doc.css('#ctl00_PlaceHolderMain_rapportDetaljert_enhetsinfo_divAddresse').text
        raw_address = doc.css('#ctl00_PlaceHolderMain_enhetsinfo_divAddresse').text if raw_address.empty?
        address_parts = raw_address.match(/\s+(.*)\r\s+(.*)\r\n\s*(.*)\r/)
        if address_parts.nil? or address_parts.length < 4
          puts "Appears not to be a page with addresses – failed on URL #{i} in search. Trying next…"
          next
        end
        address = "#{address_parts[1]}, #{address_parts[2]} #{address_parts[3]}"

        puts "Attemping coding of: #{address}"
        bounds = Geokit::Geocoders::GoogleGeocoder.geocode(s.municipality, :bias => 'no').suggested_bounds
        res = Geokit::Geocoders::GoogleGeocoder.geocode("#{address}", :bias => bounds)

        if res.success?
          puts res
          s.address = address
          s.location = { :lat => res.lat, :lon => res.lng }
          s.save!
          success = true
          break
        else
         puts "Could not geocode – failed on URL #{i} in search. Trying next…"
        end
      end
      puts "*** Meh! Geocoding failed for school '#{name}' in '#{s.municipality}.'" if not success
      puts "\n"
    end
    puts "Done"
  end
end