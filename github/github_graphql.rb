require_relative './github_graphql_client'

module GitHubGraphQL
  ListIssuesQuery = GitHubGraphQLClient::Client.parse <<-'GRAPHQL'
      query($owner: String!, $repo: String!, $before: String) {
        repository(owner:$owner, name:$repo) {
          issues(last:100, before:$before) {
            edges {
              node {
                title
                url
                number
              }
              cursor
            }
          }
        }
      }
    GRAPHQL
end