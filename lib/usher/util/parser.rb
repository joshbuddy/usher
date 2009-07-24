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

        def parse_and_expand(path, requirements = nil, default_values = nil)
          Usher::Route::Util.expand_path(parse(path, requirements, default_values))
        end

        def parse(path, requirements = nil, default_values = nil)
          parts = Usher::Route::Util::Group.new(:all, nil)
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
              new_group = Usher::Route::Util::Group.new(:any, current_group)
              current_group << new_group
              current_group = new_group
            when ?)
              current_group = current_group.parent.group_type == :one ? current_group.parent.parent : current_group.parent
            when ?|
              unless current_group.parent.group_type == :one
                detached_group = current_group.parent.pop
                new_group = Usher::Route::Util::Group.new(:one, detached_group.parent)
                detached_group.parent = new_group
                detached_group.group_type = :all
                new_group << detached_group
                new_group.parent << new_group
              end
              current_group.parent << Usher::Route::Util::Group.new(:all, current_group.parent)
              current_group = current_group.parent.last
            else
              current_group << part
            end
          end unless !path || path.empty?
          parts
        end

      end

    end
  end
end