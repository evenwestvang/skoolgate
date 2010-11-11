class Io < Thor

  # Don't read this code.

  SCHOOL_CSV_FIELDS = [:name, :municipality, :county, :address, :student_body_count, :lat, :lon]

  desc "dump_schools_to_csv FILENAME", "Dump to file"
  def dump_schools_to_csv(filename = "./data/geocoded_schools_2008.csv")
    require './environment'
    require 'CSV'
    CSV.open(File.expand_path(filename), "wb") do |csv|
      csv << SCHOOL_CSV_FIELDS.map { |t| t.to_s }
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

  desc "import_schools_from_csv FILENAME", "Nuke school collection and import school data from CSV"
  def import_schools_from_csv(filename = "data/geocoded_schools_2008.csv")
    # Hinna skole	Stavanger	Rogaland	Ordfører Tveteraas Gate 11, 4020 STAVANGER	58.9164337	5.7217672
    require './environment'
    require 'CSV'
    puts "\n- Deleting schools…"
    School.delete_all
    puts "- School CSV --> Mongo…"
    first = true
    CSV.parse(File.open(filename)) do |row|
      # Skip first row. Unpretty.
      if first
        first = false
        next
      end
      d = Hash[*SCHOOL_CSV_FIELDS.zip(row).flatten]
      find_or_create_counties_and_municipalities(d)
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

  desc "import_test_data_from_csv", "Import tests from CSV"
  def import_test_data_from_csv
    require './environment'
    years = [2009, 2008]
    name_mapping = {
      "Ekholt 1-10 skole - Avd Ungdomsveien" => "Ekholt 1-10 skole",
      "Havnås Oppvekstsenter" => "Havnås Oppvekstsenter - Avdeling skole",
      "Rykkinn skole - Avdeling Berger" => "Rykkinn skole",
      "Steinerskolen i Bærum - GRS" => "Steinerskolen i Bærum",
      "Drøbak Montessori skole AS" => "Drøbak Montessori skole"
    }
    allow = ["Grunnskolen Oslo Kristne Senter"]

    puts "Test CSV --> Mongo…"
    puts "- Cleaning test data off of schools"
    School.all.each do |s| 
      unless s.test_results.empty?
        test_results = []
        s.save!
      end
    end
    years.each do |year|
      puts "- Importing year #{year}"
      count = 0
      filename = "./data/national_benchmarks_#{year}.csv"
      File.open(filename, 'rb').readlines.each do |line|
        school_data, test_data = populate_test_data_columns(line, year)
        school_data[:name] = name_mapping[school_data[:name]] if name_mapping[school_data[:name]]
        schools = School.find(:conditions => school_data)
        raise "Could not find school for \n #{line}" if schools.empty?
        raise "Disambiguana – Too many schols for \n #{line}" if schools.length > 1
        school = schools.first
        school.test_results << TestResult.new(test_data)
        school.save
        count += 1
        print "."
      end
      puts "Got #{count} results."
    end
    puts "Finished"
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

  private


  # TODO: Write a small DSL for CSV files :)

  def populate_test_data_columns(line, year) 
    # Fylke;Kommune;Skole;Prøvekode;Gjennomsnitt;% M-nivå 1;% M-nivå 2;% M-nivå 3;% M-nivå 4;% M-nivå 5
    row = line.chomp.split(";")
    school = { :name => row[2],  :county => row[0], :municipality => row[1] }
    school[:municipality].gsub!('(ny)', '')     # robots don't like humans
    test = { :test_code => row[3] }
    test[:result] = row[4].gsub(',','.').to_f
    test[:result] = nil if test[:result] == 0
    test[:year] = year
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


  no_tasks do
    def find_or_create_counties_and_municipalities(d)
      county = County.find_or_create_by(:name => d[:county])
      unless municipality = Municipality.first(:conditions => {:name => d[:municipality], :in_county => d[:county]})
        municipality = Municipality.new(:name => d[:municipality])
        municipality.in_county = d[:county]
        municipality.save!
        puts "\nMunicipality #{municipality.name} in #{municipality.in_county} created"
      end
    end

  end

end