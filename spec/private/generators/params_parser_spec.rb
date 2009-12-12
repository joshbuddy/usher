require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', "spec_helper"))
require "usher"

ParamsParser = Usher::Util::Generators::URL::ParamsParser

describe ParamsParser do
  before :each do
    @usher = Usher.new(:generator => Usher::Util::Generators::URL.new)
    @usher.reset!
  end

  describe "given a route with one dynamic part" do
    before :each do
      @route = @usher.add_named_route :sample, '/sample/:action'
      @path = @route.find_matching_path(Hash.new)
      @params_parser = ParamsParser.new(@path)
    end

    describe "when argument is a String" do
      it "should apply as a value of first dynamic part" do
        @params_parser.parse!('show').should == { :action => 'show' }
      end
    end
  end

  describe "given a route with dynamic parts fully covered with default values" do
    before :each do
      @route = @usher.add_named_route :sample, '/:controller/:action', :default_values => { :controller => 'default', :action => 'index' }
      @path = @route.find_matching_path(Hash.new)
      @params_parser = ParamsParser.new(@path)
    end

    describe "when argument is a Hash" do
      it "should merge it with route default values" do
        @params_parser.parse!(:id => 1).should == { :controller => 'default', :action => 'index', :id => 1 }
      end

      it "given params should be in priority" do
        @params_parser.parse!(:action => 'other-action', :id => 1).should == { :controller => 'default', :action => 'other-action', :id => 1 }
      end
    end

    describe "when argument is a model" do
      before :each do
        @model = Struct.new(:id).new(1)
      end

      it "should extract model#id and merge it with default values" do
        @params_parser.parse!(@model).should == { :controller => 'default', :action => 'index', :id => 1 }
      end
    end

    describe "whem argument is an Array" do
      it "should apply array elements in the order of dynamic parts" do
        @params_parser.parse!(['kontrolla', 'show']).should == { :controller => 'kontrolla', :action => 'show' }
      end

      describe "when extra params are given" do
        it "" do
          pending "er.. example, please?"
        end
      end
    end

    describe "when argument is nil" do
      it "should just use default values as params" do
        @params_parser.parse!(nil).should == { :controller => 'default', :action => 'index' }
      end
    end
  end

  describe "given a route with a lack of default values for dynamic parts" do
    describe "when given params cover all dynamic parts while their count is lesser than dynamic parts count" do
      before :each do
        @route = @usher.add_named_route :sample, '/:one/:two/:three', :default_values => { :one => 'one', :three => 'three' }
        @path = @route.find_matching_path(Hash.new)
        @params_parser = ParamsParser.new(@path)
      end

      describe "when params is a Hash" do
        before :each do
          @params = { :one => 'bir', :two => 'eki' }
        end

        it "should merge given Hash with default params" do
          @params_parser.parse!(@params).should == { :one => 'bir', :two => 'eki', :three => 'three' }
        end
      end

      describe "when params is an Array" do
        before :each do
          @params = ['bir', 'eki']
        end

        it "should apply given Array in the order of dynamic parts" do
          @params_parser.parse!(@params).should == { :one => 'bir', :two => 'eki', :three => 'three' }
        end
      end
    end

    describe "when given params do not cover all dynamic parts even if take default values into account" do
      before :each do
        @route = @usher.add_named_route :sample, '/:one/:two/:three', :default_values => { :one => 'one', :two => 'two' }
        @path = @route.find_matching_path(Hash.new)
        @params_parser = ParamsParser.new(@path)
      end

      describe "when params is an Array" do
        before :each do
          @params = ['bir', 'eki']
        end

        it "should raise MissingParameterException" do
          lambda { @params_parser.parse!(@params) }.should raise_error(Usher::MissingParameterException)
        end
      end
    end
  end
end