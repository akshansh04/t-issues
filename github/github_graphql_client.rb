# Adapted from https://github.com/github/graphql-client
require "graphql/client"
require "graphql/client/http"

module GitHubGraphQLClient
  HTTP = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
    def headers(context)
      { "User-Agent": "My Client", "Authorization": "Bearer #{context[:installation_token]}"}
    end
  end

  # Fetch latest schema on init, this will make a network request
  # Schema = GraphQL::Client.load_schema(HTTP)

  Schema = GraphQL::Client.load_schema("#{Dir.pwd}/github/github_graphql_schema.json")
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end