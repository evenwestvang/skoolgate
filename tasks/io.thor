# encoding: UTF-8

class Io < Thor

  desc "import_all", "import all schools, afresh"
  def import_all
    require './environment'
    # import_data('data/national_benchmarks_2008.csv', 2008, :fresh => true)
    # import_data('data/national_benchmarks_2009.csv', 2009)
    # import_data('data/national_benchmarks_2010.csv', 2010)
    # import_school_addresses
    # geocode_schools
    # geocode_munis
    # canonical_school_names
    calculate_averages
  end

  ADDRESS_STUDENT_BODY_COUNT_FIELDS = [:county, :municipality, :school_name, :address, :postal_code, :postal_place, :student_body_count]

  desc "canonical_school_names", "Apply names to schools"
  def canonical_school_names
    puts "\n\n*** Writing names into school objects"
    School.all.each do |school|
      school.name = school.annual_results.last.school_name
      school.save!
    end
  end

  desc "geocode_munis", "Geocode municipalities"
  def geocode_munis
    puts "\n\n*** Geocoding municipalities\n"
    require 'open-uri'
    require 'geokit'
    munis = Municipality.where(:location.exists => false).all
    munis.each do |muni|
      puts "Coding #{muni.name}"
      bounds = Geokit::Geocoders::GoogleGeocoder.geocode(muni.name, :bias => 'no').suggested_bounds
      res = Geokit::Geocoders::GoogleGeocoder.geocode("#{muni.name}", :bias => bounds)
      if res
        muni.location = [res.lat, res.lng]
        muni.save!
      else
        puts "\n *** Couldn't code municipality #{muni.name} \n\n"
      end
    end
  end

  desc "geocode_schools", "Geocode schools"
  def geocode_schools
    puts "\n\n*** Geocoding \n"
    require 'open-uri'
    require 'geokit'

    uncoded = 0

    schools = School.where(:address.exists => true).where(:location.exists => false)
    count = schools.count

    schools.each_with_index do |school, index|
      puts "Coding #{school.address} – #{index}/#{count}"
      bounds = Geokit::Geocoders::GoogleGeocoder.geocode(school.municipality.name, :bias => 'no').suggested_bounds
      res = Geokit::Geocoders::GoogleGeocoder.geocode("#{school.address}", :bias => bounds)
      if res.success?
        school.location = [res.lat, res.lng]
        school.save!
        uncoded += 1
      else
        puts "\n *** Couldn't code address #{school.address} \n\n"
      end
    end
    puts "\n\n Uncoded schools – #{uncoded}"
  end

  desc "import_school_addresses", "Import addresses"
  def import_school_addresses
    # require './environment'
    puts "\n\n*** Applying addresses\n"
    require 'CSV'

    rows = []
    CSV.parse(File.read("data/gsi_adresser_og_elevtall_2010.csv"), :col_sep => ";").each do |row|
      keys = Hash[*ADDRESS_STUDENT_BODY_COUNT_FIELDS.zip(row).flatten]
      rows << keys if keys[:student_body_count] != "0"
    end

    schools = School.all
    puts "\n\nMatching addresses for #{schools.length} schools…\n"

    rows.each do |keys|
      keys[:municipality] = sanitize_municipality_name(keys[:municipality])
      keys[:county] = "Svalbard" if keys[:municipality] == "Svalbard"

      county = County.where(:name => /#{keys[:county].strip}/i).first
      raise "#{keys[:county]} not found" if county.nil?
      
      municipality = Municipality.where(:name => /#{keys[:municipality].strip}/i, :county_id => county.id).first
      raise "#{keys[:municipality]} in #{keys[:county]} not found" if municipality.nil?

      school = School.by_municipality(municipality).by_county(county).school_name(keys[:school_name]).first
      school ||= School.by_municipality(municipality).by_county(county).school_name(scrub_name_variants(keys[:school_name])).first
 
      if school
        schools -= [school]
        print "."
        address = ""
        address << "#{keys[:address]}, " if keys[:address]
        address << "#{keys[:postal_code]} #{keys[:postal_place]}".strip
        school.address = address
        school.student_body_count = keys[:student_body_count]
        school.save!
      end
    end

    puts "\n\nCouldn't find school addresses for #{schools.length} schools."
    schools.each do |s|
      names = s.find_school_names
      puts "#{s.find_school_names} in #{s.municipality.name} in #{s.county.name} county"
    end
  end
  

  BENCHMARK_CSV_FIELDS = [:county, :municipality, :school_name, :test_code, :result]

  desc "nuke_collections", "Just what it says"
  def nuke_collections
    puts "\n- Deleting everything…"
    County.delete_all
    Municipality.delete_all
    School.delete_all
  end

  # Sør-Trøndelag;Trondheim;Birralee International School Trondheim AS;NPREG08;4,3;0,0;0,0;0,0;0,0;0,0
  desc "import_data FILENAME OPTIONS", "Import school data from CSV"
  def import_data(filename, year, options = {})
    require 'CSV'
    require 'amatch'
    
    nuke_collections if options[:fresh]
    puts "- Reading #{filename} for #{year} --> MongoDB…"
    rows = []
    CSV.parse(File.read(filename), :col_sep => ";").each do |row|
      keys = Hash[*BENCHMARK_CSV_FIELDS.zip(row).flatten]
      rows << keys if keys[:school_name] and not keys[:school_name].empty?
    end

    unmatched = []

    rows.each do |keys|

      keys[:municipality] = sanitize_municipality_name(keys[:municipality])

      # Ensure county and municipality if we're running fresh. Regexp since they keep changing casing
      county = County.where(:name => /#{keys[:county]}/i).first
      county ||= County.create(:name => keys[:county]) if options[:fresh]
      municipality = Municipality.where(:name => /#{keys[:municipality]}/i, :county_id => county.id).first

      # INCONSISTENCY WORKAROUND: Ok, so yeah, there were no test results for this muni in 2008
      if options[:fresh] or keys[:municipality] == "Vindafjord"
        municipality ||= Municipality.create(:name => keys[:municipality], :county => county)
      end

      # Should never happen, but you ne'er know
      raise "County not found #{keys[:county]}" if county.nil?
      raise "Municipality not found #{keys[:municipality]}" if municipality.nil?

      # Attempt a trivial match
      school = School.by_municipality(municipality).by_county(county).school_name(keys[:school_name]).first
      school ||= School.new({:county => county, :municipality => municipality}) if options[:fresh]

      unless school.nil?
        school.add_annual_result(year, keys[:school_name], Subject.new(clean_test_data(keys))) and print " "
      else
        unmatched << keys and print "!"
      end
    end

    puts "\n\n- Attempting to match #{unmatched.length} results for #{year}\n\n"

    unmatched.each do |keys|
      school = nil
      name = keys[:school_name]
      puts "\nAttempting to match #{name}"

      county = County.where(:name => /#{keys[:county]}/i).first
      municipality = Municipality.where(:name => /#{keys[:municipality]}/i, :county_id => county.id).first
      schools = School.by_municipality(municipality).by_county(county).school_name(keys[:school_name])

      school = schools.first

      puts "!!! Looks like it's been created in the interrim - great" if school
      
      if school.nil?
        match_schools = School.by_county(county).by_municipality(municipality).not_in_year(2009)
        if match_schools.empty?
          # puts "! No available schools available in municipality to match with. Must be new."
          school = School.new({:county => county, :municipality => municipality})
        else
          match_schools.each do |match_school|
            match_school.annual_results.map(&:school_name).each do |match_name|
              if match_name.match(/#{Regexp.escape(name)}/i) || name.match(/#{Regexp.escape(match_name)}/i)
                school = match_school
                puts "# #{name} matches #{match_name} on substrings"
              end
            end
          end
          scrubbed_name = scrub_name_variants(name)
          if school.nil? and scrubbed_name.length > 4
            scored_schools = match_schools.map do |school|
              match_names = school.annual_results.map(&:school_name).map { |name| scrub_name_variants(name) }
              score = scrubbed_name.levenshtein_similar(match_names).sort.reverse[0]
              [score, school]
            end
            scored_schools.sort! {|a,b| b[0] <=> a[0]}
            if scored_schools[0][0] > 0.6
              school = scored_schools[0][1]
              puts "\n + Probable match for #{name} in #{scored_schools[0][1].annual_results.map(&:school_name).inspect} with score of #{scored_schools[0][0]}"
            else
              puts "\n- No match for #{name} in #{scored_schools[0][1].annual_results.map(&:school_name).inspect} with score of #{scored_schools[0][0]}"
            end
          end
        end
        if school.nil?
          puts "! New school #{name}"
          school = School.new({:county => county, :municipality => municipality})
        end
      end
      puts "Adding results for #{keys[:school_name]} for year #{year} and with data #{Subject.new(clean_test_data(keys))}"
      school.add_annual_result(year, keys[:school_name], Subject.new(clean_test_data(keys))) and print " "
    end

    puts "\nImported #{School.count} schools in #{County.count} counties in #{Municipality.count} municipalities"
    puts "Finished"
  end

  desc "calculate_averages", "Run through stats. Calculate averages"
  def calculate_averages
    puts "\n\n*** Calculating school avgs"
    
    School.all.each do |school|
      school.annual_results.each do |year|
        normalized = year.subjects.map { |subject| subject.normalized_result }.compact
        year.result_average = (normalized.inject { |a, b| a + b }) / normalized.length unless normalized.empty?
      end
      normalized = school.annual_results.map { |year| year.result_average }.compact
      school.result_average = (normalized.inject { |a, b| a + b }) / normalized.length unless normalized.empty?
      school.save!
    end
    puts "Writing yearly averages into school objects"
    School.all.each do |school|
      school.annual_results.each do |annual_result|
        school.year_averages ||= {}
        school.year_averages[annual_result.year.to_s] = annual_result.result_average
      end
      school.save!
    end
    puts "Muni school avgs"
    Municipality.all.each do |muni|
      schools = School.by_municipality(muni)
      avgs = schools.map(&:result_average).compact
      muni.result_average = (avgs.inject { |a, b| a + b }) / avgs.length unless avgs.empty?
      body_count = schools.map(&:student_body_count).compact
      muni.student_body_count = (body_count.inject { |a, b| a + b }) unless body_count.empty?
      
      year_averages = {}
      muni.year_averages = {}
      schools.each do |school|
        school.annual_results.each do |annual_result|
          year_averages[annual_result.year.to_s] ||= []
          year_averages[annual_result.year.to_s] << annual_result.result_average
        end
      end
      year_averages.each_pair do |key,value|
        average = (value.inject { |a, b| a + b }) / value.length
        muni.year_averages[key] = average
      end
      muni.save!
    end

    puts "Calculating county avgs"
    County.all.each do |county|
      avgs = School.by_county(county).map(&:result_average).compact
      county.result_average = (avgs.inject { |a, b| a + b }) / avgs.length unless avgs.empty?
      county.save!
    end
  end


  private

  no_tasks do


  # INCONSISTENCY WORKAROUND: Names do change
  MUNI_NAME_MAPPING = {
    "Kåfjord" => "Gáivuotna Kåfjord",
    "Deatnu-Tana" => "Deatnu Tana",
    "Guovdageaidnu-Kautokeino" => "Guovdageaidnu Kautokeino",
    "Kautokeino" => "Guovdageaidnu Kautokeino",
    "Karasjohka-Karasjok" => "Karasjohka Karasjok",
    "Karasjok" => "Karasjohka Karasjok",
    "Porsanger" => "Porsanger Porsángu Porsanki",
    "Unjárga-Nesseby" => "Unjárga Nesseby",
    "Unjargga Nesseby" => "Unjárga Nesseby",
    "Nesseby" => "Unjárga Nesseby",
    "Aurskog Høland" => "Aurskog-Høland",
    "Kvam herad" => "Kvam"
  }

  def sanitize_municipality_name name
    # INCONSISTENCY WORKAROUND: Ok, so they put qualifiers in the municipality names in 2009
    name = name.gsub(/\s\(.*\)/, '')
    name = name.gsub(/(\si\s).*/, '')
    name = MUNI_NAME_MAPPING[name] if MUNI_NAME_MAPPING[name]
    name
  end

  def scrub_name_variants(name)
    name.gsub(/skole|skule|Avd|\s-\s|barnehage|kombinerte|avdeling|den\snorske\sskolen|DNS|kombinert|oppvekstsenter|oppvekst|oppveksttun|nærmiljøsenter|Avd/i,'')
  end

    def clean_test_data(keys)
      test = {}
      keys[:result] ||= "0" # Argh, this sometimes comes back as nil for 2010. Blame excel.
      test[:result] = keys[:result].gsub(',','.').to_f
      test[:result] = nil if test[:result] == 0
      test[:test_code] = keys[:test_code]
      test[:school_year] = keys[:test_code].match(/0(\d)/)[1].to_i
      if test[:result]
        if test[:school_year] == 5
          test[:normalized_result] = (test[:result] - 1) / 2  # 1-3
        elsif test[:school_year] == 8
          test[:normalized_result] = (test[:result] - 1) / 4  # 1-5
        elsif test[:school_year] == 9
          test[:normalized_result] = (test[:result] - 1) / 4  # 1-5
        else
          raise "Not a valid class"
        end
      end
      return test
    end
  end

end