require_relative './github_graphql_client'

module GitHubGraphQL
  ListIssuesQuery = GitHubGraphQLClient::Client.parse <<-'GRAPHQL'
      query($owner: String!, $repo: String!, $after: String) {
        repository(owner:$owner, name:$repo) {
          issues(first:100, after:$after) {
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