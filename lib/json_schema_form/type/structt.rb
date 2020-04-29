# require 'dry-types'

module JsonSchemaForm
  module Type
    # It is preferrable to a Struct because of the in-class
    # API for defining properties as well as per-property defaults.

    class Structt < Hash

      # Defines a property. Options are
      # as follows:
      #
      # * <tt>:default</tt> - Specify a default value for this property,
      #   to be returned before a value is set on the property in a new
      #   Dash.
      #
      # * <tt>:required</tt> - Specify the value as required for this
      #   property, to raise an error if a value is unset in a new or
      #   existing Dash. If a Proc is provided, it will be run in the
      #   context of the Dash instance. If a Symbol is provided, the
      #   property it represents must not be nil. The property is only
      #   required if the value is truthy.
      #
      # * <tt>:message</tt> - Specify custom error message for required property
      #

      PREFIX = '_'.freeze

      def self.property(property_name, options = {})
        # was_sym = property_name.is_a? Symbol
        # property_name = PREFIX + property_name.to_s
        # property_name = property_name.to_sym if was_sym
        
        properties << property_name
  
        if options.key?(:default)
          defaults[property_name] = options[:default]
        elsif defaults.key?(property_name)
          defaults.delete property_name
        end
  
        define_getter_for(property_name)
        define_setter_for(property_name)
  
        @subclasses.each { |klass| klass.property(property_name, options) } if defined? @subclasses
  
        condition = options.delete(:required)
        if condition
          message = options.delete(:message) || "is required for #{name}."
          required_properties[property_name] = { condition: condition, message: message }
        elsif options.key?(:message)
          raise ArgumentError, 'The :message option should be used with :required option.'
        end
      end

    class << self
      attr_reader :properties, :defaults, :required_properties
    end
    instance_variable_set('@properties', Set.new)
    instance_variable_set('@defaults', {})
    instance_variable_set('@required_properties', {})

    # when a class in inherited from this one, add it to subclasses and
    # set instance variables
    def self.inherited(klass)
      super
      (@subclasses ||= Set.new) << klass
      klass.instance_variable_set('@properties', properties.dup)
      klass.instance_variable_set('@defaults', defaults.dup)
      klass.instance_variable_set('@required_properties', required_properties.dup)
    end

    # define a getter for a property
    private_class_method def self.define_getter_for(property_name)
      prefixed_property_name = :"#{PREFIX}#{property_name}"
      if instance_methods.include?(prefixed_property_name)
        raise StandardError.new('invalid property ' + property_name.to_s)
      end
      define_method(prefixed_property_name) { |&block| self.[](property_name, &block) }
    end

    # define a setter for a property
    private_class_method def self.define_setter_for(property_name)
      prefixed_property_name = :"#{PREFIX}#{property_name}="
      if instance_methods.include?(prefixed_property_name)
        raise StandardError.new('invalid property ' + property_name.to_s)
      end
      define_method(prefixed_property_name) { |value| self.[]=(property_name, value) }
    end

    # Check to see if the specified property has already been
    # defined.
    def self.property?(name)
      properties.include? name
    end

    # Check to see if the specified property is
    # required.
    def self.required?(name)
      required_properties.key? name
    end

    # You may initialize a Dash with an attributes hash
    # just like you would many other kinds of data objects.
    def initialize(attributes = {}, &block)
      attributes = attributes.compact
      super(&block)

      #set defaults
      self.class.defaults.each_pair do |prop, value|
        v = begin
          val = value.dup
          if val.is_a?(Proc)
            val.arity == 1 ? val.call(self) : val.call
          else
            val
          end
        rescue TypeError
          value
        end
        self.send("#{PREFIX}#{prop}=", v)
      end

      #set attributes
      attributes.each_pair do |att, value|
        self.send("#{PREFIX}#{att}=", value)
      end

      #validate all required properties
      # self.class.properties.each |prop|
      #   validate!(required_property)
      # end
      self.class.required_properties.each_key do |required_property|
        verify_required_property!(required_property)
      end
    end

    # Retrieve a value (will return the
    # property's default value if it hasn't been set).
    def [](property)
      assert_property_exists! property
      value = super(property)
      # If the value is a lambda, proc, or whatever answers to call, eval the thing!
      if value.is_a? Proc
        self[property] = value.call # Set the result of the call as a value
      else
        yield value if block_given?
        value
      end
    end

    # Set a value on the Dash in a Hash-like way. Only works
    # on pre-existing properties.
    def []=(property, value)
      assert_property_exists! property
      verify_property_to_set! property, value
      super(property, value)
    end

    private

    def assert_property_exists!(property)
      unless self.class.property?(property)
        raise NoMethodError, "The property '#{property}' is not defined for #{self.class.name}."
      end
    end

    def verify_required_property!(property)
      if send("#{PREFIX}#{property}").nil? && required?(property)
        raise ArgumentError,
                "The property '#{property}' #{self.class.required_properties[property][:message]}"
      end
    end

    def verify_property_to_set!(property, value)
      if value.nil? && required?(property)
        raise ArgumentError,
              "The property '#{property}' #{self.class.required_properties[property][:message]}"
      end
    end

    def required?(property)
      return false unless self.class.required?(property)

      condition = self.class.required_properties[property][:condition]
      case condition
      when Proc   then !!instance_exec(&condition)
      when Symbol then !!send(condition)
      else             !!condition
      end
    end

    end
  end
end