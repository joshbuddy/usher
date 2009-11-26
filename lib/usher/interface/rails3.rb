class Usher
  module Interface
    class Rails3
    
      @@instance = nil
    
      def initialize
        @usher = Usher.new
        @controller_paths = []
        @configurations_files = []
        
        @@instance = self
      end
      
      def self.instance
        @@instance
      end
      
      def draw(&blk)
        @usher.instance_eval(&blk)
      end
      
      attr_accessor :controller_paths
      
      def add_configuration_file(file)
        @configurations_files << file
      end
      
      def reload
        @usher.reset!
        @configurations_files.each do |c|
          Kernel.load(c)
        end
      end
      alias_method :reload!, :reload
      
      def call(env)
        request = ActionDispatch::Request.new(env)
        response = @usher.recognize(request, request.path_info)
        request.parameters.merge!(response.path.route.default_values) if response.path.route.default_values
        response.params.each{ |hk| request.parameters[hk.first] = hk.last}
        controller = "#{request.parameters[:controller].to_s.camelize}Controller".constantize
        controller.action(request.parameters[:action] || 'index').call(env)
      end

      def recognize(request)
        params = recognize_path(request.path, extract_request_environment(request))
        request.path_parameters = params.with_indifferent_access
        "#{params[:controller].to_s.camelize}Controller".constantize
      end
      
      def load(app)
        @app = app
      end
      
    end
  end
end
