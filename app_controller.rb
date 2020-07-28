require 'sinatra'
require_relative './auth.rb'
require_relative './github/github_client.rb'

class TIssuesApp < Sinatra::Application
  include Auth
  
  Config.validate

  before '/get-similar-issues' do
    get_payload_request(request)
    verify_webhook_signature
    validate_event_type
    authenticate_app
    authenticate_installation
    GitHubClient.init @installation_token
  end

  post '/get-similar-issues' do
    puts('/get-similar-issues called')

    owner = @payload['repository']['owner']['login']
    repo = @payload['repository']['name']
    puts "owner: #{owner}, repo: #{repo}"

    issues_result = GitHubClient.listIssues(owner, repo)
    if issues_result[:error] != nil
      halt 500, { 'Content-Type' => 'application/json' }, { error: issues_result[:error] }.to_json
    end

    # get sim scores
    # add comment for sim > threshold
    content_type :json
    status 200
    # message = '/get-similar-issues called'
    message = issues_result[:issues]
    { issues: message }.to_json
  end

  helpers do
    def get_payload_request(request)
      puts("Reading request payload json")
      # request.body is an IO or StringIO object
      # Rewind in case someone already read it
      request.body.rewind
      # The raw text of the body is required for webhook signature verification
      @payload_raw = request.body.read
      begin
        @payload = JSON.parse @payload_raw
      rescue => e
        error_message = "Invalid JSON (#{e}): #{@payload_raw}"
        halt 400, { 'Content-Type' => 'application/json' }, { error: error_message }.to_json
      end
    end

    def validate_event_type
      event_name = get_header('HTTP_X_GITHUB_EVENT')
      if event_name != 'issues'
        puts("Ignoring event: #{event_name}")
        halt 200
      end
    end
  end
  
  run! if __FILE__ == $0 
end

