#Mongoid doesn't really like making geospatial indexes so:
#use skoolgate_****
#db.schools.ensureIndex({location : "2d"})
#db.municipalities.ensureIndex({location : "2d"})
# index [[ :location, Mongo::GEO2D ]]

# TODO: add thor task for indexing

class County
  include Mongoid::Document
  field :name
  field :link_name, :type => String

  field :result_average, :type => Float
  field :location, :type => Array

  references_many :municipalities
  references_many :schools

  after_create :print_tick
  def print_tick
    print "C "
  end

end

class Municipality
  include Mongoid::Document
  field :name
  field :student_body_count, :type => Integer
  field :result_average, :type => Float
  field :location, :type => Array
  field :link_name, :type => String
  field :year_averages, :type => Hash

  referenced_in :county
  references_many :schools

  scope :by_county, lambda { |county| { :where => { :county_id => county.id } } }

  after_create :add_to_counties
  def add_to_counties
    self.county.municipalities << self
    self.county.save!
    print "M "
  end
end


class School
  include Mongoid::Document
  field :address, :type => String
  field :name, :type => String
  field :link_name, :type => String
  field :student_body_count, :type => Integer
  field :location, :type => Array # latitude longitude
  field :result_average, :type => Float
  field :year_averages, :type => Hash

  referenced_in :county
  referenced_in :municipality

  # embeds
  embeds_many :annual_results

  scope :by_county, lambda { |county| { :where => { :county_id => county.id } } }
  scope :by_municipality, lambda { |municipality| { :where => { :municipality_id => municipality.id } } }
  scope :school_name, lambda { |school_name| { :where => {"annual_results.school_name" => school_name } } }
  scope :in_year, lambda { |year| { :where => {"annual_results.year" => year } } }
  scope :not_in_year, lambda { |year| { :excludes => {"annual_results.year" => year } } }

  after_create :add_to_municipalities

  def find_school_names
    self.annual_results.map(&:school_name).uniq
  end

  def find_school_name
    self.annual_results.school_name
  end

  def add_to_municipalities
    self.municipality.schools << self
    self.municipality.save!
    self.county.schools << self
    self.county.save!
  end

  def add_annual_result year, school_name, subject = nil
    if subject.result.nil?
      print 
      return 
    end
    annual_result = self.annual_results.in_year(year).first
    if annual_result.nil?
      annual_result = AnnualResult.new(:year => year, :school_name => school_name)
      self.annual_results << annual_result
      print year.to_s[-1]
    end
    annual_result.subjects << subject if subject
    self.save!
    return annual_result
  end

end

class AnnualResult
  include Mongoid::Document
  field :school_name, :type => String
  field :year, :type => Integer
  field :result_average, :type => Float

  # embeds
  embeds_many :subjects
  embedded_in :school, :inverse_of => :annual_results

  scope :in_year, lambda { |year| { :where => { :year => year } } }
  
  validates_presence_of :year
  validates_presence_of :school_name  
end

class Subject
  include Mongoid::Document
  field :school_year, :type => Integer
  field :test_code, :type => String
  field :result, :type => Float
  field :normalized_result, :type => Float

  # embeds
  embedded_in :annual_result, :inverse_of => :subjects
  # validations
  validates_presence_of :school_year
  validates_presence_of :test_code
  validates_presence_of :result
end
