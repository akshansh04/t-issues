require 'octokit'
require_relative './github_graphql'
require_relative './github_graphql_client'

module GitHubClient
  def self.init(installation_token)
    @context = { installation_token: installation_token }
    @installation_client = Octokit::Client.new(bearer_token: installation_token)
  end

  def self.listIssues(owner, repo, max_pages=10)
    all_issues = []
    fetched_pages = 0
    after = nil
    while fetched_pages < max_pages do
      params = {
        "owner": owner,
        "repo": repo,
        "after": after
      }
      
      issues_response = GitHubGraphQLClient::Client.query(GitHubGraphQL::ListIssuesQuery, variables: params, context: @context)
      # puts "issues_response.inspect: #{issues_response.inspect}"
      if(issues_response.data && issues_response.data.repository && issues_response.data.repository.issues && issues_response.data.repository.issues.edges)
        issues = issues_response.data.repository.issues.edges
        if issues.length == 0
          break
        else
          after = issues[issues.length-1].cursor
          all_issues.append(*issues)
        end
        fetched_pages += 1
      else
        puts "Unexpected response from GitHub list issues API. Response: #{issues_response.inspect}"
        return {
          error: { message: 'Unexpected response from GitHub list issues API', response: issues_response.inspect},
          issues: nil
        }
      end
    end
    return {
      error: nil,
      issues: all_issues.map {|issue| { :url=> issue.node.url, :title=> issue.node.title, :number=> issue.node.number }}
    }
  end

  def self.add_issue_comment(owner, repo, number, comment)
    @installation_client.add_comment("#{owner}/#{repo}", number, comment)
  end
end