#
# Copyright 2013-2017 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'conjur/policy_load_result'
require 'conjur/policy'
require 'conjur/saas'

module Conjur
  class API
    #@!group Policy management
    
    # Append only.
    POLICY_METHOD_POST = :post
    # Allow explicit deletion statements, but don't delete implicitly delete data.
    POLICY_METHOD_PATCH = :patch
    # Replace the policy entirely, deleting any existing data that is not declared in the new policy.
    POLICY_METHOD_PUT = :put

    # Load a policy document into the server.
    #
    # The modes are support for policy loading:
    #
    # * POLICY_METHOD_POST Policy data will be added to the named policy. Deletions are not allowed.
    # * POLICY_METHOD_PATCH Policy data can be added to or deleted from the named policy. Deletions
    # are performed by an explicit `!delete` statement.
    # * POLICY_METHOD_PUT The policy completely replaces the name policy. Policy data which is present
    # in the server, but not present in the new policy definition, is deleted.
    #
    # @param id [String] id of the policy to load.
    # @param policy [String] YAML-formatted policy definition. 
    # @param account [String] Conjur organization account
    # @param method [Symbol] Policy load method to use: {POLICY_METHOD_POST} (default), {POLICY_METHOD_PATCH}, or {POLICY_METHOD_PUT}.
    def load_policy id, policy, account: Conjur.configuration.account, method: POLICY_METHOD_POST
      request = url_for(:policies_load_policy, credentials, account, id)
      PolicyLoadResult.new JSON.parse(request.send(method, policy))
    end

    # Validate a policy load without applying it to the server, reporting what
    # would change.
    #
    # @param id [String] id of the policy to load.
    # @param policy [String] YAML-formatted policy definition.
    # @param account [String] Conjur organization account
    # @param method [Symbol] Policy load method to use: {POLICY_METHOD_POST} (default), {POLICY_METHOD_PATCH}, or {POLICY_METHOD_PUT}.
    # @return [Hash] the dry run result, with keys such as "status", "created", "updated",
    #   "deleted", and "errors". Invalid policy YAML is reported in the result rather than
    #   raised, with "status" set to "Invalid YAML" and details in "errors". This applies
    #   only to the 422 response the server uses for invalid YAML; other error responses
    #   (e.g. 403 for insufficient privileges, 400 for bad request params) have a different
    #   body shape and are raised as the corresponding RestClient exception.
    # @raise [Conjur::FeatureNotAvailable] if the appliance is CyberArk Secrets Manager, SaaS,
    #   or the Conjur server is older than 1.21.1.
    def dry_run_policy id, policy, account: Conjur.configuration.account, method: POLICY_METHOD_POST
      verify_policy_dry_run_support!
      request = url_for(:policies_dry_run_policy, credentials, account, id)
      JSON.parse(request.send(method, policy))
    rescue RestClient::UnprocessableEntity => e
      JSON.parse(e.response.body)
    end

    # Fetch the current policy data from the server.
    #
    # @param id [String] id of the policy to fetch.
    # @param account [String] Conjur organization account
    # @param return_json [Boolean] Return the policy as JSON instead of the default YAML.
    # @param depth [Integer, nil] Maximum depth of the returned policy tree (nil for the full tree).
    # @param limit [Integer, nil] Maximum number of policy objects to return (nil for no limit).
    # @return [String] the policy document, formatted as YAML or JSON.
    # @raise [Conjur::FeatureNotAvailable] if the appliance is CyberArk Secrets Manager, SaaS,
    #   or the Conjur server is older than 1.21.1.
    def fetch_policy id, account: Conjur.configuration.account, return_json: false, depth: nil, limit: nil
      verify_policy_dry_run_support!
      options = {}
      options[:depth] = depth if depth
      options[:limit] = limit if limit
      request = url_for(:policies_fetch_policy, credentials, account, id, options)
      content_type = return_json ? 'application/json' : 'application/x-yaml'
      request.get('Content-Type' => content_type).body
    end

    #@!endgroup

    private

    def verify_policy_dry_run_support!
      if Conjur::Saas.appliance_url?(Conjur.configuration.appliance_url)
        raise Conjur::FeatureNotAvailable, "Policy dry run and fetch are not supported in CyberArk Secrets Manager, SaaS"
      end

      verify_min_server_version!('1.21.1')
    end
  end
end
