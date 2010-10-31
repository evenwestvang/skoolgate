require './environment'

get '/' do
  haml :index
end

get '/get_markers/:lat/:lon/:lat2/:lon2/:detail_level' do
  box = [[params[:lat].to_f, params[:lon].to_f], [params[:lat2].to_f, params[:lon2].to_f]]
  if params[:detail_level] == "0"
    objects = School.where(:location.within => {"$box" => box}).only(:name, :location, :result_average, :student_body_count)
  else
    objects = Municipality.where(:location.within => {"$box" => box}).only(:name, :location, :result_average, :student_body_count)
  end
  objects.map { |s| {:id => s.id, :body => s.student_body_count, :name => s.name, :avg => s.result_average, :lat => s.location[0], :lon => s.location[1]}}.to_json
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet, :style => :compact
end

# <a href="http://github.com/you"><img style="position: absolute; top: 0; left: 0; border: 0;" src="http://s3.amazonaws.com/github/ribbons/forkme_left_green_007200.png" alt="Fork me on GitHub" /></a>

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
