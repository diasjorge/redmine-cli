module Redmine
  class Field
    def initialize(title, ref, dm=nil)
      @title=title      # The string displayed in the listing table for this field
      @ref=ref        # The attribute referenced from the issue record
      @display_method=dm    # A method used to process the value before displaying (optional)
    end
    def title
      return @title
    end
    def ref
      return @ref
    end
    def display
      return @display_method
    end
  end
end
