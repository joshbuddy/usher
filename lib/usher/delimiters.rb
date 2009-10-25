class Delimiters < Array
  def unescaped
    self.map do |delimiter|
      (delimiter[0] == ?\\) ?
              delimiter[1..-1] :
              delimiter
    end

    # TODO: Delimiters#regex and so on
    #
    # TODO: caching
  end
end