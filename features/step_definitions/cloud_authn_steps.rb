require 'base64'
require 'json'

# Step definitions for the cloud authenticator integration features
# (authn-iam, authn-azure, authn-gcp).
#
# These steps drive real Conjur (brought up by docker-compose) against the
# cloud provider's real metadata/STS services. They are only meaningful when
# run on the matching cloud agent, so the features carry @authn_iam /
# @authn_azure / @authn_gcp tags and are gated by RUN_AWS_TESTS /
# RUN_AZURE_TESTS / RUN_GCP_TESTS in the pipeline.

# --- authn-iam -------------------------------------------------------------

# authn-iam matches the Conjur host to the AWS caller identity, so the host id
# must be "<account-id>/<role-name>" (supplied via env by the AWS CI stage).
def aws_caller_identity_host_id
  account = ENV.fetch('AWS_ACCOUNT_ID')
  role    = ENV.fetch('AWS_ROLE_NAME')
  "#{account}/#{role}"
end

Given(/^I enable the authn-iam authenticator "([^"]+)" for the AWS caller identity host$/) do |service_id|
  host_id = aws_caller_identity_host_id
  $conjur.load_policy 'root', <<-POLICY
  - !policy
    id: conjur/authn-iam/#{service_id}
    body:
    - !webservice
    - !group apps
    - !permit
      role: !group apps
      privilege: [ read, authenticate ]
      resource: !webservice

  - !host
    id: #{host_id}
    annotations:
      authn-iam/#{service_id}: true

  - !grant
    role: !group conjur/authn-iam/#{service_id}/apps
    member: !host #{host_id}
  POLICY

  @cloud_host_id = host_id
  $conjur.authenticator_enable('authn-iam', service_id)
end

When(/^I authenticate via authn-iam as the AWS caller identity host with service id "([^"]+)"$/) do |service_id|
  identity = "host/#{aws_caller_identity_host_id}"
  @cloud_api = Conjur::API.new_from_iam(identity, service_id: service_id)
  @result = @cloud_api.token
end

# --- authn-azure -----------------------------------------------------------

# The authn-azure provider-uri must equal the token's actual issuer
# (https://sts.windows.net/<tenant>/). Derive it from a real IMDS token's `iss`
# claim rather than hardcoding, matching conjur-api-java's resolveProviderUriFromImds.
def azure_provider_uri
  jwt = Conjur::API.send(:fetch_azure_jwt,
                         resource_uri: Conjur::API::AzureAuthenticator::DEFAULT_RESOURCE,
                         client_id: (ENV['USER_ASSIGNED_IDENTITY_CLIENT_ID'] unless ENV['USER_ASSIGNED_IDENTITY_CLIENT_ID'].to_s.empty?),
                         imds_base_url: Conjur::API::AzureAuthenticator::DEFAULT_IMDS_BASE,
                         imds_api_version: Conjur::API::AzureAuthenticator::DEFAULT_IMDS_VER)
  payload = JSON.parse(Base64.decode64(jwt.split('.')[1]))
  issuer  = payload.fetch('iss')
  issuer.end_with?('/') ? issuer : "#{issuer}/"
end

Given(/^I enable the authn-azure authenticator "([^"]+)" for host "([^"]+)" using Azure environment config$/) do |service_id, host_id|
  subscription   = ENV.fetch('AZURE_SUBSCRIPTION_ID')
  resource_group = ENV.fetch('AZURE_RESOURCE_GROUP')
  provider_uri   = azure_provider_uri

  $conjur.load_policy 'root', <<-POLICY
  - !policy
    id: conjur/authn-azure/#{service_id}
    body:
    - !webservice
    - !variable provider-uri
    - !group apps
    - !permit
      role: !group apps
      privilege: [ read, authenticate ]
      resource: !webservice

  - !host
    id: #{host_id}
    annotations:
      authn-azure/subscription-id: "#{subscription}"
      authn-azure/resource-group: "#{resource_group}"

  - !grant
    role: !group conjur/authn-azure/#{service_id}/apps
    member: !host #{host_id}
  POLICY

  @cloud_host_id = host_id
  $conjur.resource("cucumber:variable:conjur/authn-azure/#{service_id}/provider-uri")
         .add_value(provider_uri)
  $conjur.authenticator_enable('authn-azure', service_id)
end

When(/^I authenticate via authn-azure as "([^"]+)" with service id "([^"]+)"(?: and client id "([^"]*)")?$/) do |identity, service_id, client_id|
  # new_from_azure takes service_id and identity positionally; client_id is a keyword.
  opts = {}
  opts[:client_id] = client_id if client_id && !client_id.empty?
  @cloud_api = Conjur::API.new_from_azure(service_id, identity, **opts)
  @result = @cloud_api.token
end

# --- authn-gcp -------------------------------------------------------------

Given(/^I enable the authn-gcp authenticator for host "([^"]+)"$/) do |host_id|
  # authn-gcp is serviceless. The host is matched to the GCP identity token via
  # its authn-gcp/project-id annotation, so the project id must be the one the
  # token was issued for (supplied by ci/get_gcp_token.sh as GCP_PROJECT_ID).
  project_id = ENV.fetch('GCP_PROJECT_ID')

  $conjur.load_policy 'root', <<-POLICY
  - !policy
    id: conjur/authn-gcp
    body:
    - !webservice
    - !group apps
    - !permit
      role: !group apps
      privilege: [ read, authenticate ]
      resource: !webservice

  - !host
    id: #{host_id}
    annotations:
      authn-gcp/project-id: "#{project_id}"

  - !grant
    role: !group conjur/authn-gcp/apps
    member: !host #{host_id}
  POLICY

  @cloud_host_id = host_id
  $conjur.authenticator_enable('authn-gcp', '')
end

When(/^I authenticate via authn-gcp as "([^"]+)" using the pre-fetched token$/) do |identity|
  jwt = ENV['GCP_ID_TOKEN']
  raise 'GCP_ID_TOKEN is not set; run ci/get_gcp_token.sh on a GCP agent first' if jwt.nil? || jwt.empty?

  @cloud_api = Conjur::API.new_from_gcp(identity, jwt: jwt)
  @result = @cloud_api.token
end

# --- shared assertions -----------------------------------------------------

Then(/^I receive a Conjur access token$/) do
  # Conjur access tokens are returned parsed into a Hash of the JWT parts.
  expect(@result).to be_a(Hash)
  expect(@result).to include('protected', 'payload', 'signature')
end

Given(/^the secret "([^"]+)" has value "([^"]+)"$/) do |var_id, value|
  # Declare the variable and grant the cloud host permission to read it, then
  # set the value. @cloud_host_id is captured by the "enable ... authenticator"
  # step that always runs first.
  raise 'no cloud host configured; run the "enable authenticator" step first' unless @cloud_host_id

  $conjur.load_policy 'root', <<-POLICY
  - !variable #{var_id}
  - !permit
    role: !host #{@cloud_host_id}
    privilege: [ read, execute ]
    resource: !variable #{var_id}
  POLICY

  $conjur.resource("cucumber:variable:#{var_id}").add_value(value)
end

Then(/^I can retrieve the secret "([^"]+)" with value "([^"]+)"$/) do |var_id, value|
  expect(@cloud_api.resource("cucumber:variable:#{var_id}").value).to eq(value)
end
