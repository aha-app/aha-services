module Schema
  module ClassMethods
    # Gets the current schema for the data attributes that this Service
    # expects.  This schema is used to generate the admin
    # interface.  The attribute types loosely to HTML input elements.
    #
    # Example:
    #
    #   class FooService < Service
    #     string :token
    #   end
    #
    #   FooService.schema
    #   # => [[:string, :token]]
    #
    # Returns an Array of [Symbol attribute type, Symbol attribute name] tuples.
    def schema
      @schema ||= []
    end

    # Public: Adds the given attributes as String attributes in the Service's
    # schema.
    #
    # Example:
    #
    #   class FooService < Service
    #     string :token
    #   end
    #
    #   FooService.schema
    #   # => [[:string, :token]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def string(*attrs)
      add_to_schema :string, attrs
    end

    # Public: Adds the given attributes as Password attributes in the Service's
    # schema.
    #
    # Example:
    #
    #   class FooService < Service
    #     password :token
    #   end
    #
    #   FooService.schema
    #   # => [[:password, :token]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def password(*attrs)
      add_to_schema :password, attrs
    end

    # Public: Adds the given attributes as Boolean attributes in the Service's
    # schema.
    #
    # Example:
    #
    #   class FooService < Service
    #     boolean :digest
    #   end
    #
    #   FooService.schema
    #   # => [[:boolean, :digest]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def boolean(*attrs)
      add_to_schema :boolean, attrs
    end
  
    # Adds the given attributes to the Service's data schema.
    #
    # type  - A Symbol specifying the type: :string, :password, :boolean.
    # attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def add_to_schema(type, attrs)
      attrs.each do |attr|
        schema << [type, attr.to_sym]
      end
    end
  end
end