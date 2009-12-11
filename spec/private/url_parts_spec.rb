require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"
require 'rack/test'

module PathAndRequestHelper
  def stub_path_with(scheme, host, port)
    generate_with = Usher::Route::GenerateWith.new(scheme, port, host)

    route = stub 'route'
    route.stub! :generate_with => generate_with

    path = stub 'path'
    path.stub! :route => route

    path
  end

  def stub_path
    stub_path_with nil, nil, nil
  end

  def rack_request_for(url)
    Rack::Request.new(Rack::MockRequest.env_for(url))
  end
end

describe Usher::Util::Generators::URL::UrlParts do
  include PathAndRequestHelper

  before :all do
    ::UrlParts = Usher::Util::Generators::URL::UrlParts
  end

  describe "#url" do
    describe "when generate_with is provided" do
      before :each do
        @path = stub_path_with 'https', 'overridden', 9443
        @request = rack_request_for 'http://localhost'
      end

      it "should return url with parts provided by generate_with" do
        url_parts = UrlParts.new(@path, @request)
        url_parts.url.should == "https://overridden:9443"
      end

      describe "when port is standard" do
        describe "when scheme is https" do
          before :each do
            @path = stub_path_with 'https', 'overridden', 443
            @request = rack_request_for 'http://localhost:8080'
          end

          it "should not add port to url" do
            url_parts = UrlParts.new(@path, @request)
            url_parts.url.should == "https://overridden"
          end
        end

        describe "when scheme is http" do
          before :each do
            @path = stub_path_with 'http', 'overridden', 80
            @request = rack_request_for 'http://localhost:8080'
          end

          it "should not add port to url" do
            url_parts = UrlParts.new(@path, @request)
            url_parts.url.should == "http://overridden"
          end
        end
      end

      describe "when scheme is not given" do
        before :each do
          @path = stub_path_with nil, 'overridden', 8443
        end

        describe "when request is Rack's one" do
          before :each do
            @request = rack_request_for 'https://localhost'
          end

          it "should extract scheme from request" do
            url_parts = UrlParts.new(@path, @request)
            url_parts.url.should == "https://overridden:8443"
          end
        end

        describe "when request is an AbstractRequest (Rails < 2.3)" do
          before :each do
            @request = stub 'request'
            @request.stub! :protocol => 'https://'
          end

          it "should call #protocol, not #scheme" do
            url_parts = UrlParts.new(@path, @request)
            url_parts.url.should == "https://overridden:8443"
          end
        end
      end
    end

    describe "when generate_with is empty" do
      before :each do
        @path = stub_path
        @request = mock 'request'
      end

      it "should just extract the url" do
        @request.should_receive(:url).and_return('http://localhost')

        url_parts = UrlParts.new(@path, @request)
        url_parts.url.should == 'http://localhost'
      end
    end
  end
end
