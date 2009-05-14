require 'strscan'

class Usher
  class Splitter
    
    def self.for_delimiters(delimiters, valid_regex)
      delimiters_regex = delimiters.collect{|d| Regexp.quote(d)} * '|'
      SplitterInstance.new(
        delimiters,
        Regexp.new('((:|\*)?' + valid_regex + '|' + delimiters_regex + '|\(|\)|\||\{)'),
        Regexp.new(delimiters_regex + '|' + valid_regex)
      )
    end
    
    attr_reader :paths

    class SplitterInstance
      
      def initialize(delimiters, split_regex, url_split_regex)
        @delimiters = delimiters
        @delimiter_chars = delimiters.collect{|d| d[0]}
        @delimiter_chars_map = Hash[*@delimiter_chars.map{|c| [c, c.chr.to_sym]}.flatten]
        @split_regex = split_regex
        @url_split_regex = url_split_regex
      end
      
      def url_split(path)
        parts = path.scan(@url_split_regex)
        parts.map!{ |part| @delimiter_chars_map[part[0]] || part}
        parts
      end

      def split(path, requirements = nil)
        parts = Group.new(:all, nil)
        ss = StringScanner.new(path)
        current_group = parts
        while !ss.eos?
          part = ss.scan(@split_regex)
          case part[0]
          when ?*, ?:
            type = part.slice!(0).chr.to_sym
            current_group << Usher::Route::Variable.new(type, part, requirements && requirements[part.to_sym])
          when ?{
            pattern = '^'
            count = 1
            variable = ss.scan(/[:\*]([^,]+),/)
            until count.zero?
              regex_part = ss.scan(/\{|\}|[^\{\}]+/)
              case regex_part[0]
              when ?{
                count += 1
              when ?}
                count -= 1
              end
              pattern << regex_part
            end
            pattern[pattern.size - 1] = ?$
            regex = Regexp.new(pattern)
            if variable
              variable_type = variable.slice!(0).chr.to_sym
              variable_name = variable[0, variable.size - 1].to_sym
              current_group << Usher::Route::Variable.new(variable_type, variable_name, requirements && requirements[variable_name], regex)
            else
              current_group << regex
            end
          when ?(
            new_group = Group.new(:any, current_group)
            current_group << new_group
            current_group = new_group
          when ?)
            current_group = current_group.parent.type == :one ? current_group.parent.parent : current_group.parent
          when ?|
            unless current_group.parent.type == :one
              detached_group = current_group.parent.pop
              new_group = Group.new(:one, detached_group.parent)
              detached_group.parent = new_group
              detached_group.type = :all
              new_group << detached_group
              new_group.parent << new_group
            end
            current_group.parent << Group.new(:all, current_group.parent)
            current_group = current_group.parent.last
          when *@delimiter_chars
            current_group << part.to_sym
          else
            current_group << part
          end
        end unless !path || path.empty?
        paths = calc_paths(parts)
        paths.each do |path|
          path.each_with_index do |part, index|
            if part.is_a?(Usher::Route::Variable)
              case part.type
              when :*
                part.look_ahead = path[index + 1, path.size].find{|p| !p.is_a?(Symbol) && !p.is_a?(Usher::Route::Variable)} || nil
              when :':'
                part.look_ahead = path[index + 1, path.size].find{|p| p.is_a?(Symbol)} || @delimiters.first.to_sym
              end
            end
          end
        end
        paths
      end

      private

      def cartesian_product!(lval, rval)
        product = []
        (lval.size * rval.size).times do |index|
          val = []
          val.push(*lval[index % lval.size])
          val.push(*rval[index % rval.size])
          product << val
        end
        lval.replace(product)
      end

      def calc_paths(parts)
        if parts.is_a?(Group)
          paths = [[]]
          case parts.type
          when :all
            parts.each do |p|
              cartesian_product!(paths, calc_paths(p))
            end
          when :any
            parts.each do |p|
              cartesian_product!(paths, calc_paths(p))
            end
            paths.unshift([])
          when :one
            cartesian_product!(paths, parts.collect do |p|
              calc_paths(p)
            end)
          end
          paths.each{|p| p.compact!; p.flatten! }
          paths
        else
          [[parts]]
        end

      end
    end
    
    class Group < Array
      attr_accessor :type
      attr_accessor :parent
      
      def inspect
        "#{type}->#{super}"
      end
      
      def initialize(type, parent)
        @type = type
        @parent = parent
      end
    end
    
  end
end