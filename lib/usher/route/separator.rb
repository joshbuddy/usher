class Usher
  class Route

    class Separator
      private
      def initialize(sep)
        @sep = sep
        @sep_to_s = "#{sep}"
      end

      public
      def to_s
        @sep_to_s
      end

      Dot = Separator.new(:'.')
      Slash = Separator.new(:/)
    end

  end
end