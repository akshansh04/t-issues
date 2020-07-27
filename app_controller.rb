require 'sinatra'

class TIssuesApp < Sinatra::Application

  post '/get-similar-issues' do
    puts('/get-similar-issues called')

    content_type :json
    status 200
    message = '/get-similar-issues called'
    { message: message }.to_json
  end
  
  run! if __FILE__ == $0 
end