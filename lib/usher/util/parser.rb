require 'strscan'

class Usher
  module Util
    class Parser

      def self.for_delimiters(router, valid_regex)
        ParserInstance.new(
          router,
          Regexp.new('((:|\*)?' + valid_regex + '|' + router.delimiters_regex + '|\(|\)|\||\{)')
        )
      end

      class ParserInstance

        def initialize(router, split_regex)
          @router = router
          @split_regex = split_regex
        end

        def parse(path, requirements = nil, default_values = nil)
          parts = Group.new(:all, nil)
          ss = StringScanner.new(path)
          current_group = parts
          while !ss.eos?
            part = ss.scan(@split_regex)
            case part[0]
            when ?*
              var_name = part[1, part.size - 1].to_sym
              current_group << Usher::Route::Variable::Glob.new(part[1, part.size - 1], nil, requirements && requirements[var_name])
            when ?:
              var_name = part[1, part.size - 1].to_sym
              current_group << Usher::Route::Variable::Single.new(part[1, part.size - 1], nil, requirements && requirements[var_name])
            when ?{
              pattern = ''
              count = 1
              variable = ss.scan(/[!:\*]([^,]+),/)
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
              pattern.slice!(pattern.length - 1)
              regex = Regexp.new(pattern)
              if variable
                variable_type = variable.slice!(0).chr.to_sym
                variable_class = case variable_type
                when :'!' then Usher::Route::Variable::Greedy
                when :*   then Usher::Route::Variable::Glob
                when :':' then Usher::Route::Variable::Single
                end
                
                variable_name = variable[0, variable.size - 1].to_sym
                current_group << variable_class.new(variable_name, regex, requirements && requirements[variable_name])
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
            else
              current_group << part
            end
          end unless !path || path.empty?
          paths = calc_paths(parts)
          paths.each do |path|
            path.each_with_index do |part, index|
              part.default_value = default_values[part.name] if part.is_a?(Usher::Route::Variable) && default_values && default_values[part.name]
              case part
              when Usher::Route::Variable::Glob
                part.look_ahead = path[index + 1, path.size].find{|p| !p.kind_of?(Usher::Route::Variable) && !@router.delimiter_chars.include?(p[0])} || nil
              when Usher::Route::Variable
                part.look_ahead = path[index + 1, path.size].find{|p| @router.delimiter_chars.include?(p[0])} || @router.delimiters.first
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
end