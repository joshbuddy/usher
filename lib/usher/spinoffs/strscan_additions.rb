require 'strscan'

#TODO: rewrite this in C and commit this addition back to community
class StringScanner
  #      scan_before(pattern)
  #
  #
  # Scans the string until the +pattern+ is matched. As opposed to #scan_until,
  # it does not include a matching pattern into a returning value and sets
  # pointer just _before_ the pattern position.
  # If there is no match, +nil+ is returned.
  #
  #  s = StringScanner.new("Fri Dec 12 1975 14:39")
  #  s.scan_until(/1/)        # -> "Fri Dec "
  #  s.scan(/1/)              # -> "1"
  #  s.scan_until(/1/)        # -> nil
  #
  def scan_before(pattern)
    return nil unless self.exist?(pattern)
    pattern_size = self.matched_size
    result = self.scan_until(pattern)
    pattern_size.times { result.chop! }
    self.pos = self.pos - pattern_size
    result
  end
end