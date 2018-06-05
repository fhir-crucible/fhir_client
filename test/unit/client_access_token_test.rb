require_relative '../test_helper'

class ClientAccessTokenTest < Test::Unit::TestCase

  def client
    @client ||= FHIR::Client.new("basic-test")
  end

  def test_can_configure_client_with_access_token_authentication
    # stub out a request for a resource, once configured with the access token
    # the auth methed should be a bearer token with the provided access token
    # the stub only works on calls that have the correct authentication header
    stub_request(:get, /Patient\/example/).
                        with(headers:{"Authorization"=>"Bearer some token"}).
                        to_return(body: "{}", headers: {"Content-Type" => "application/json"} )
    client.set_auth_from_token("id","secret", {access_token: "some token",
                                                auto_configure: false});


    assert_equal "{}", client.read(FHIR::Patient, "example").response[:body]

  end

  def test_can_configure_client_with_refresh_token_for_authentication
    new_token = "{\"access_token\": \"New access Token\"}"
    # stub request for requesting a new access token from an auth server token endpoint
    #   this will return the expected new access token
    stub_request(:post, /auth\/token/).to_return(body: new_token, headers: {"Content-Type" => "application/json"} )

    # stub out a request for a resource, once configured with the access token
    # the auth method should be a bearer token with the access token retrieved
    # from the previous call to get a new access token
    # the stub only works on calls that have the correct authentication header

    stub_request(:get, /Patient\/example/).
                        with(headers:{"Authorization"=>"Bearer New access Token"}).
                        to_return(body: "{}", headers: {"Content-Type" => "application/json"} )
    token = client.set_auth_from_token("id","secret", {access_token: "some token",
                                                       auto_configure: false,
                                                       expires_in: -1,
                                                       refresh_token: "My Refresh Token",
                                                       token_path: "/auth/token"});

    assert_equal "New access Token", token.token
    # make a call to test the stubbed out method with auth type
    assert_equal "{}", client.read(FHIR::Patient, "example").response[:body]
  end

  # Need to provide at a minimum an access_token or a refresh_token, it can be
  # both but need at least one of them, otherwise there is nothing to configure
  # against
  def test_must_supply_either_an_access_token_or_a_refresh_token
    begin
      client.set_auth_from_token("id","secret", {})
      assert false, "Should not be able to configure client without either an access or refresh token"
    rescue
      assert_equal "Must provide an access_token or a refresh_token", $!.message
    end
  end

  # Make sure that we can auto configure the auth and token endpoints from a
  # capability statement.
  def test_can_configure_access_token_with_auto_configure
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    capabilitystatement = File.read(File.join(root, 'fixtures', 'oauth_capability_statement.json'))
    stub_request(:get, /metadata/).to_return(body: capabilitystatement)
    token = client.set_auth_from_token("id","secret", {access_token: "some token",
                                                       auto_configure: true});

    assert_equal "https://authorize.smarthealthit.org/authorize", token.client.options[:authorize_url]
    assert_equal "https://authorize.smarthealthit.org/token", token.client.options[:token_url]
  end



end
