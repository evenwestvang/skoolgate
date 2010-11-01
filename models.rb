#Mongoid doesn't really like making geospatial indexes so:
#use skoolgate_****
#db.schools.ensureIndex({location : "2d"})
#db.municipalities.ensureIndex({location : "2d"})

class School
 include Mongoid::Document
 field :name, :type => String
 field :municipality, :type => String
 field :county, :type => String
 field :address, :type => String
 field :student_body_count, :type => Integer
 field :location, :type => Array # latitude longitude
 field :result_average, :type => Float
 field :county, :type => String
 field :municipality, :type => String
 # embeds
 embeds_many :test_results
 # indexes
 index [[ :location, Mongo::GEO2D ]]
 # validations
 validates_presence_of :name
 validates_presence_of :municipality
 validates_presence_of :county
end

class TestResult
 include Mongoid::Document
 field :school_year, :type => Integer
 field :test_code, :type => String
 field :result, :type => Float
 field :normalized_result, :type => Float
 field :year, :type => Integer

 # embeds
 embedded_in :school, :inverse_of => :test_results
 # validations
 validates_presence_of :school_year
 validates_presence_of :test_code
 validates_presence_of :result
 validates_presence_of :year

 before_save :set_normalized_result

 def self.humanized_name
   map = { "REG" => "regning", "LES" => "lesning", "ENG" => "engelsk" }
   map.each_pair { |k,v| return v if test_code.match(k)} 
 end
end

class County
 include Mongoid::Document
 field :name
 field :result_average, :type => Float
 field :location, :type => Array
end

class Municipality
 include Mongoid::Document
 field :name
 field :student_body_count, :type => Integer
 field :result_average, :type => Float
 field :location, :type => Array
 field :in_county, :type => String
end

