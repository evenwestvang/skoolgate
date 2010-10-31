class Io < Thor

  # Don't read this code.

  desc "run_all", "Clean collections and run all import tasks"
  def run_all
    invoke :drop_schools
    invoke :import_schools_from_csv
    invoke :import_test_data_from_csv
    invoke :calculate_averages
  end

  desc "drop_schools", "Indeed"
  def drop_schools
    require './environment'

    puts "Nuking collections…"
    School.delete_all
    puts "Done\n"
  end

  desc "dump_to_csv FILENAME", "Dump to file"
  def dump_to_csv(filename = "./data/geocoded_schools_2008_100_missing.csv")
    require './environment'
    require 'CSV'
    CSV.open(File.expand_path(filename), "wb") do |csv|
      csv << ["Name","Municipality", "County", 
        "Address", "Student body count", "Latitude", "Longitude"]
      School.find(:all).asc(:location).each do |s|
        lat, lon = nil
        if s.location
          lat = s.location[0]
          lon = s.location[1]
        end
        csv << [s.name,s.municipality, s.county, 
                s.address, s.student_body_count, lat, lon]
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

  desc "import_schools_from_csv FILENAME", "Nuke DB and import school data from CSV"
  def import_schools_from_csv(filename = "data/geocoded_schools_2008_100_missing.csv")
    # Hinna skole	Stavanger	Rogaland	Ordfører Tveteraas Gate 11, 4020 STAVANGER	58.9164337	5.7217672
    require './environment'
    require 'CSV'
    puts "School CSV --> Mongo…"
    first = true
    CSV.parse(File.open(filename)) do |row|
      # Skip first row
      if first
        first = false
        next
      end
      d = Hash[*[:name, :municipality, :county, :address, :student_body_count, :lat, :lon].zip(row).flatten]
      county = County.find_or_create_by(:name => d[:county])
      unless municipality = Municipality.first(:conditions => {:name => d[:municipality], :in_county => d[:county]})
        municipality = Municipality.new(:name => d[:municipality])
        municipality.in_county = d[:county]
        municipality.save!
        puts "\nMunicipality #{municipality.name} in #{municipality.in_county} created"
      end
      location = nil
      location = [d[:lat].to_f, d[:lon].to_f] if d[:lat] and d[:lon]
      s = School.new({
        :name => d[:name], :county => d[:county], :municipality => d[:municipality], :student_body_count => d[:student_body_count], :address => d[:address], :location => location
      })
      s.save!
      print "."
    end
    puts "\nImported #{School.count} schools in #{County.count} counties in #{Municipality.count} municipalities"
    puts "Finished"
  end

  desc "import_test_data_from_csv FILENAME", "Import tests from CSV"
  def import_test_data_from_csv(filename = "data/nasjonaleprøver_2008.csv")
    require './environment'
    puts "Test CSV --> Mongo…"
    # Clean
    puts "- cleaning"
    School.all.each do |s| 
      unless s.test_results.empty?
        test_results = []
        s.save!
      end
    end
    # Import
    puts "- importing"
    File.open(filename, 'rb').readlines.each do |line|
      school_data, test_data = populate_test_data_columns(line)
      schools = School.find(:conditions => school_data)
      raise "Could not find school #{line}" if schools.empty?
      raise "Too many schols for #{line}" if schools.length > 1
      school = schools.first
      school.test_results << TestResult.new(test_data)
      school.save
      print "."
    end
    puts "Finished"
  end

  private
  
  def populate_test_data_columns(line) 
    # Fylke;Kommune;Skole;Prøvekode;Gjennomsnitt;% M-nivå 1;% M-nivå 2;% M-nivå 3;% M-nivå 4;% M-nivå 5
    row = line.chomp.split(";")
    school = { :name => row[2],  :county => row[0], :municipality => row[1] }
    school[:municipality].gsub!('(ny)', '')     # robots don't like humans
    test = { :test_code => row[3] }
    test[:result] = row[4].gsub(',','.').to_f
    test[:result] = nil if test[:result] == 0
    test[:year] = 2008
    test[:school_year] = test[:test_code].match(/0(\d)/)[1].to_i

    if test[:result]
      if test[:school_year] == 5
        test[:normalized_result] = (test[:result] - 1) / 2  # 1-3
      elsif test[:school_year] == 8
        test[:normalized_result] = (test[:result] - 1) / 4  # 1-5
      else
        raise "Not a valid year"
      end
    end

    return school, test
  end

end