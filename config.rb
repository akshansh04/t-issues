# frozen_string_literal: true
# require 'dotenv/load' # Manages environment variables. Un-comment for dev env

module Config
  APP_IDENTIFIER = ENV['GITHUB_APP_IDENTIFIER']
  APP_PRIVATE_KEY = ENV['GITHUB_PRIVATE_KEY']
  APP_WEBHOOK_SECRET = ENV['GITHUB_WEBHOOK_SECRET']
  APP_NAME = 't-issues'

  def self.validate
    if APP_IDENTIFIER.nil? || APP_IDENTIFIER.empty?
      raise "Environment variable GITHUB_APP_IDENTIFIER not set."
    end

    if APP_PRIVATE_KEY.nil? || APP_PRIVATE_KEY.empty?
      raise "Environment variable GITHUB_PRIVATE_KEY not set."
    end

    if APP_WEBHOOK_SECRET.nil? || APP_WEBHOOK_SECRET.empty?
      raise "Environment variable GITHUB_WEBHOOK_SECRET not set."
    end

  end
end