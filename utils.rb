require 'net/http'
require_relative './config.rb'

module Utilities
  SIMILARITY_THRESHOLD = 0.75
  MAX_SIMILAR_ISSUES = 10

  def get_similar_issues(issues)
    issue_map = get_issue_map(issues)
    puts 'issue_map'
    puts issue_map
    similarity_scores = get_similarity_scores(issues)
    current_issue_id = @payload['issue']['number']
    similar_issues = ''
    similar_issues_count = 0

    similarity_scores.each { |issue|  
      if issue['score'].to_f >= SIMILARITY_THRESHOLD and similar_issues_count < MAX_SIMILAR_ISSUES        
        if issue['id'].to_i != @payload['issue']['number']   
          similar_issues = "#{similar_issues}- ##{issue['id']} #{issue_map[issue['id']]}\n"
          similar_issues_count += 1
        end
      else
        break
      end
    }
    similar_issues
  end

  def get_issue_map(issues)
    issue_map = {}
    issues.each { |issue| 
      issue_map[issue[:number]] = issue[:title] 
    }
    issue_map
  end

  def get_similarity_scores(issues)
    source = @payload['issue']['title']
    target = issues.map {|issue| { :id=> issue[:number], :string=> issue[:title] }}
    response = send_request(source, target)
    # similarity_scores = response.map { |issue| { :id => issue.id, :score => issue.score }}
    # similarity_scores
    JSON.parse(response)
  end

  def send_request(source, target)
    uri = URI("http://#{Config::MATCHMAKING_CLUSTER_IP}/")
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json; charset=utf-8'
    req.body = { source: source, target: target }.to_json
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    
    if res.code.to_i != 200
      halt res.code, { 'Content-Type' => 'application/json' }, { error: res.message }.to_json
    end
    res.body
  end
end