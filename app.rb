require './environment'
require 'benchmark'

KLASSES = ["School", "Municipality"]
VALID_YEAR_STRINGS = (2008..2010).map(&:to_s)

get '/usecontrast' do
  @map_options = { :useContrast => true, :fullscreen => true }
  haml :index
end

get '/ll/:lat/:lon' do |lat, lon|
  @map_options = { :ll => [lat.to_f, lon.to_f], :fullscreen => true }
  haml :index
end

get '/' do
  @map_options = { :fullscreen => true }
  haml :index
end


get '/marker_info/:marker_id' do |marker_id|
  content_type 'text/json', :charset => 'utf-8'
  klass, id = marker_id.split('_')
  if KLASSES.include?(klass)
    klass = klass.constantize 
    res = klass.find(id)
    res[:school_url] = BASE_URL + school_url(res) if res.is_a? School
    return res.to_json
  end
end

get '/get_markers/:lat/:lon/:lat2/:lon2/:year' do |lat, lon, lat2, lon2, year|
  content_type 'text/json', :charset => 'utf-8'
  box = [[lat.to_f, lon.to_f], [lat2.to_f, lon2.to_f]]
  year = nil unless VALID_YEAR_STRINGS.include?(year)
  year ||= "2010"
  objects = nil
  result = {}

  if School.where(:location.within => {"$box" => box}).limit(401).count < 400
    result[:detailLevel] = "schools"
    objects = School.where(:location.within => {"$box" => box}).
      only(:name, :location, :result_average, :year_averages, :student_body_count)
  else
    result[:detailLevel] = "municipalities"
    objects = Municipality.where(:location.within => {"$box" => box}).
      only(:name, :location, :year_averages, :result_average, :student_body_count)
  end
  
  result[:objects] = objects.map { |o| {
    :id => id_for_object(o), 
    :name => o.name,
    :body => o.student_body_count, 
    :avg => o.year_averages[year], 
    :lat => o.location[0], 
    :lon => o.location[1]}}
  result.to_json
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet, :style => :compact
end

get '/statistikk' do
  schools = School.all
  @lon_average_json = schools.map do |s| 
    if s.location && s.location[0] && s.location[0] > 0
      {:name => "#{s.name} i #{s.municipality.name}", :x => s.result_average, :y => s.location[0]}
    end
  end.compact.to_json
  @size_quality = schools.map do |s| 
    if s.location && s.location[0] && s.location[0] > 0
      {:name => "#{s.name} i #{s.municipality.name}", :x => s.result_average, :y => s.student_body_count}
    end
  end.compact.to_json
  @page_title = "- statistikk"
  haml :statistics
end

get '/skolene' do
  @counties = County.all.order_by(:name.asc)
  @page_title = "for alle skolene i Norge"
  haml :schools
end

get '/skolene/:county' do |county|
  @county = County.where(:link_name => county).first
  @page_title = "for skolene i #{@county.name} fylke"
  haml :schools_for_county
end

get '/skolene/:county/:municipality' do |county, muni|
  @county = County.where(:link_name => county).first
  @municipality = Municipality.by_county(@county).where(:link_name => muni).first
  @page_title = "for skolene i #{@municipality.name} kommune"
  haml :schools_for_municipality
end

get '/skolene/:county/:municipality/:name' do |county, muni, name|
  @county = County.where(:link_name => county).first
  @municipality = Municipality.by_county(@county).where(:link_name => muni).first
  @school = School.by_municipality(@municipality).where(:link_name => name).first
  @page_title = "for #{@school.name}"

  @has_position = false
  if @school.location.length == 2
    @map_options = {
      :map_id => "school_map_canvas", 
      :ll => [@school.location[0].to_f, @school.location[1].to_f],
      :popInfoBoxFor => id_for_object(@school)}
    @has_position = true
  end
  haml :school
end

get '/om' do
  @page_title = "om tjenesten"
  haml :about
end

helpers do
  def id_for_object(obj)
    obj.class.to_s << "_" << obj.id.to_s
  end
  
  def school_url(school)
    "/skolene/#{school.county.link_name}/#{school.municipality.link_name}/#{school.link_name}"
  end
  
  def link_to_school(school)
    link_to school.name, school_url(school)
  end

  def partial(page, options={})
    haml page, options.merge!(:layout => false)
  end

  def link_to(*args)
    case args.length
      when 1 then url = args[0]; text = url.gsub('http://','')
      when 2 then text, url = args
      when 3 then text, url, opts = args
    end
    opts ||= {}
    attributes = ""
    opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
    "<a href=\"#{url}\" #{attributes}>#{text}</a>"
  end
end
