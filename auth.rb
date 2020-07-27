require 'jwt'
require 'time'
require 'octokit'
require 'json'
require 'openssl'
require_relative './config.rb'

module Auth
  include Config

  def authenticate_app
    payload = {
      # The time that this JWT was issued, _i.e._ now.
      iat: Time.now.to_i,

      # JWT expiration time (10 minute maximum)
      exp: Time.now.to_i + (10 * 60),

      # Your GitHub App's identifier number
      iss: Config::APP_IDENTIFIER
    }

    # TODO: Make this a global variable to enable caching

    # Expects the private key in PEM format. Converts the newlines
    @PRIVATE_KEY = OpenSSL::PKey::RSA.new(Config::APP_PRIVATE_KEY.gsub('\n', "\n"))

    # Cryptographically sign the JWT.
    jwt = JWT.encode(payload, @PRIVATE_KEY, 'RS256')

    # Create the Octokit client, using the JWT as the auth token.
    @app_client ||= Octokit::Client.new(bearer_token: jwt)
  end

  # Instantiate an Octokit client, authenticated as an installation of a
  # GitHub App, to run API operations.
  def authenticate_installation
    begin
      @installation_id = get_installation_id
      puts("Obtained installation id: #{@installation_id}")
      @installation_token = @app_client.create_app_installation_access_token(@installation_id)[:token]
      @installation_client = Octokit::Client.new(bearer_token: @installation_token)
    rescue => ex
      # if an exception occurs while authenticating as installation,
      # it means the app is not installed on the repo.
      error_message = "Looks like the '#{Config::APP_NAME}' app is not installed on the repository. Internal error: #{ex}"
      halt 422, { 'Content-Type' => 'application/json' }, { error: error_message }.to_json
    end
  end

  def get_installation_id
    installation_id = 0
    if @payload['installation'] and @payload['installation']['id']
      installation_id = @payload['installation']['id']
    else
      error_message = "Could not find installation id in payload."
      halt 400, { 'Content-Type' => 'application/json' }, { error: error_message }.to_json
    end
    installation_id
  end

  def verify_webhook_signature
    their_signature_header = get_header('HTTP_X_HUB_SIGNATURE') || 'sha1='
    method, their_digest = their_signature_header.split('=')
    our_digest = OpenSSL::HMAC.hexdigest(method, Config::APP_WEBHOOK_SECRET, @payload_raw)
    if their_digest != our_digest
      error_message = 'Received signature from webhook does not match with the calculated signature'
      halt 401, { 'Content-Type' => 'application/json' }, { error: error_message }.to_json
    end

    # The X-GITHUB-EVENT header provides the name of the event.
    # The action value indicates the which action triggered the event.
    puts(event_message: "Received event #{get_header('HTTP_X_GITHUB_EVENT')}")
  end  

  def get_header(name)
    # Rack prefixes the http headers with HTTP_, while Sinatra doesn't.
    http_prefix = 'HTTP_'
    request.env["#{http_prefix}#{name}"] || request.env[name]
  end
end