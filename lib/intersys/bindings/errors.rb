module Intersys
  class IntersysException < StandardError; end

  class ObjectNotFound < IntersysException; end
  class MarshallError < IntersysException; end
  class UnMarshallError < IntersysException; end
  class ConnectionError < IntersysException; end
end
