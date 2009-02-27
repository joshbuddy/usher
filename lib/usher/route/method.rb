class Usher
  class Route
    class Method
      private
      attr_reader :name
      def initialize(name = nil)
        @name = name
      end

      public
      def self.for(name)
        name && Methods[name] || Any
      end
  
      Get = Method.new(:get)
      Post = Method.new(:post)
      Put = Method.new(:put)
      Delete = Method.new(:delete)
      Any = Method.new
  
      Methods = {:get => Get, :post => Post, :put => Put, :delete => Delete}
  
    end
  end
end