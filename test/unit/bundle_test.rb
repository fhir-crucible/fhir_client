require_relative '../test_helper'

class BundleTest < Test::Unit::TestCase
  def test_example_bundle
    client = FHIR::Client.new('feed-test')
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    bundle_xml = File.read(File.join(root, 'fixtures', 'bundle-example.xml'))
    response = {
      code: '200',
      headers: {},
      body: bundle_xml
    }
    clientReply = FHIR::ClientReply.new('feed-test', response)

    bundle = client.parse_reply(FHIR::Bundle, FHIR::Formats::ResourceFormat::RESOURCE_XML, clientReply)

    assert !bundle.nil?, 'Failed to parse example Bundle.'
  end

  def test_next_bundle
    client = FHIR::Client.new('feed-test')
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    bundle_xml = File.read(File.join(root, 'fixtures', 'bundle-example.xml'))
    response = {
      code: '200',
      headers: {},
      body: bundle_xml
    }
    clientReply = FHIR::ClientReply.new('feed-test', response)

    bundle = client.parse_reply(FHIR::Bundle, FHIR::Formats::ResourceFormat::RESOURCE_XML, clientReply)
    next_bundle_xml = File.read(File.join(root, 'fixtures', 'next-bundle-example.xml'))
    WebMock.stub_request(:any, bundle.next_link.url).to_return status: 200, body: next_bundle_xml
    next_bundle = bundle.next_bundle

    assert !next_bundle.nil?, 'Failed to retrieve next Bundle.'
  end

  def test_each
    client = FHIR::Client.new('feed-test')
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    bundle_xml = File.read(File.join(root, 'fixtures', 'bundle-example.xml'))
    response = {
      code: '200',
      headers: {},
      body: bundle_xml
    }
    clientReply = FHIR::ClientReply.new('feed-test', response)

    bundle = client.parse_reply(FHIR::Bundle, FHIR::Formats::ResourceFormat::RESOURCE_XML, clientReply)
    next_bundle_xml = File.read(File.join(root, 'fixtures', 'next-bundle-example.xml'))
    WebMock.stub_request(:any, bundle.next_link.url).to_return status: 200, body: next_bundle_xml

    counter = 0
    bundle.each do |entry|
      counter += 1
    end

    assert counter == 2, "Called block #{counter} times. Expected 2"
  end

  def test_each_no_block
    client = FHIR::Client.new('feed-test')
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    bundle_xml = File.read(File.join(root, 'fixtures', 'bundle-example.xml'))
    response = {
      code: '200',
      headers: {},
      body: bundle_xml
    }
    clientReply = FHIR::ClientReply.new('feed-test', response)

    bundle = client.parse_reply(FHIR::Bundle, FHIR::Formats::ResourceFormat::RESOURCE_XML, clientReply)
    next_bundle_xml = File.read(File.join(root, 'fixtures', 'next-bundle-example.xml'))
    WebMock.stub_request(:any, bundle.next_link.url).to_return status: 200, body: next_bundle_xml

    iterator = bundle.each

    assert iterator.count == 2, "Iterator should have had 2 elements."
  end
end
