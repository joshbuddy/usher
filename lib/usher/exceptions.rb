class Usher
  class UnrecognizedException < RuntimeError; end
  class ValidationException < RuntimeError; end
  class MissingParameterException < RuntimeError; end
  class MultipleParameterException < RuntimeError; end
end