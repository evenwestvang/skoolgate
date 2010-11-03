require './environment'

KLASSES = ["School", "Municipality"]

get '/marker_info/:marker_id' do
  content_type 'text/json', :charset => 'utf-8'
  klass, id = params[:marker_id].split('_')
  if KLASSES.include?(klass)
    klass = klass.constantize 
    return klass.find(id).to_json
  end
end

get '/get_markers/:lat/:lon/:lat2/:lon2/:detail_level' do
  content_type 'text/json', :charset => 'utf-8'
  box = [[params[:lat].to_f, params[:lon].to_f], [params[:lat2].to_f, params[:lon2].to_f]]
  if params[:detail_level] == "0"
    objects = School.where(:location.within => {"$box" => box}).only(:name, :location, :result_average, :student_body_count)
  else
    objects = Municipality.where(:location.within => {"$box" => box}).only(:name, :location, :result_average, :student_body_count)
  end
  objects.map { |o| {
    :id => o.class.to_s << "_" << o.id.to_s, 
    :body => o.student_body_count, 
    :name => o.name, 
    :avg => o.result_average, 
    :lat => o.location[0], 
    :lon => o.location[1]}}.to_json
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet, :style => :compact
end

get '/' do
  haml :index
end

get '/about' do
  haml :about
end

get '/missing_data' do
  haml :missing_data
end


helpers do
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
