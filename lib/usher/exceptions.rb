class Usher
  # Exception raised when generation is attempted and the route cannot be determined
  class UnrecognizedException < RuntimeError; end
  # Raised when a validator fails during recognition
  class ValidationException < RuntimeError; end
  # Raised when generation attempts to create a route and a parameter is missing
  class MissingParameterException < RuntimeError; end
  # Raised when a route is added with identical variable names and allow_identical_variable_names? is false
  class MultipleParameterException < RuntimeError; end
  # Raised when a route is added with two regex validators
  class DoubleRegexpException < RuntimeError; end
end