require 'dry-types'

module Types
  include Dry.Types()
end

module JsonSchemaForm
  # It is preferrable to a Struct because of the in-class
  # API for defining attributes as well as per-attribute defaults.

  class CustomStruct < Hash

    include Types

    # Defines a attribute. Options are
    # as follows:
    #
    # * <tt>:type</tt> - Dry Type definition
    # * <tt>:default</tt> - Default value that can also be a proc evaluated at the instance level
    # * <tt>:transform</tt> - A proc that will be evaluated at the instance level

    # PREFIX = '_'.freeze

    def self.deep_symbolize!(object)
      case object
      when Hash
        object.each do |k, v|
          if v.is_a?(::Hash)
            deep_symbolize! v
          end
        end
        object.transform_keys!(&:to_sym)
      when Array
        object.map { |val| deep_symbolize! val }
      else
        raise StandardError.new('error')
      end
    end

    def self.attribute?(attribute_name, options = {})
      options = options.merge({required: false})
      _register_attribute(attribute_name, options)
    end

    def self.attribute(attribute_name, options = {})
      options = options.merge({required: true})
      _register_attribute(attribute_name, options)
    end

    def self._register_attribute(attribute_name, options)
      attributes[attribute_name] = options

      if defined? @subclasses
        if options[:required]
          @subclasses.each{ |klass| klass.attribute(attribute_name, options) }
        else
          @subclasses.each{ |klass| klass.attribute?(attribute_name, options) }
        end
      end
      self
    end

    #class level getter for attributes
    class << self
      attr_reader :attributes
    end
    instance_variable_set('@attributes', {})

    # when a class in inherited from this one, add it to subclasses and
    # set instance variables
    def self.inherited(klass)
      super
      (@subclasses ||= Set.new) << klass
      klass.instance_variable_set('@attributes', attributes.dup)
    end

    # Check to see if the specified attribute has already been
    # defined.
    def self.has_attribute?(name)
      !attributes.find{|prop, options| prop == name}.nil?
    end

    # Check to see if the specified attribute is
    # required.
    def self.attr_required?(name)
      !attributes.find{|prop, options| prop == name && options[:required]}.nil?
    end

    attr_reader :skip_required_attrs

    # You may initialize with an attributes hash
    # just like you would many other kinds of data objects.
    def initialize(attributes = {}, &block)

      
      instance_variable_set('@skip_required_attrs',
        attributes.delete(:skip_required_attrs) || []
      )
      
      #handle ActiveSupport::HashWithIndifferentAccess
      self.class.deep_symbolize!(attributes&.as_json)
      super(&block)
      
      #set attributes
      attributes.each do |att, value|
        self[att] = value
      end

      #set defaults
      self.class.attributes.each do |name, options|
        next if attributes.key?(name)
        if !options[:default].nil? && (options[:type] && options[:type].default?)
          raise ArgumentError.new('having both default and type default is not supported')
        end
        #set from options[:default]
        if !options[:default].nil?
          value = begin
            val = options[:default].dup
            if val.is_a?(Proc)
              val.arity == 1 ? val.call(self) : val.call
            else
              val
            end
          rescue TypeError
            options[:default]
          end
          self[name] = value
        #set from options[:type]
        elsif !options[:type].nil? && options[:type].default?
          self[name] = options[:type][Dry::Types::Undefined]
        end
      end

      # validate all attributes
      validate_all_attributes!
    end

    def validate_all_attributes!
      self.class.attributes.each do |name, options|
        validate_attribute!(name)
      end
    end

    #validate all defined attributes
    def validate_attribute!(name)
      prop = self.class.attributes.find{|prop, options| prop == name }
      name = prop[0]
      options = prop[1]
      if options[:required]
        if self[name].nil? && attr_required?(name)
          raise ArgumentError, "The attribute '#{name}' is required"
        end
      else
        # TODO maybe other validations are required?
      end
    end

    # Retrieve a value (will return the
    # attribute's default value if it hasn't been set).
    def [](attribute)
      # assert_attribute_exists! attribute
      value = super(attribute)
      # If the value is a lambda, proc, or whatever answers to call, eval the thing!
      if value.is_a? Proc
        self[attribute] = value.call # Set the result of the call as a value
      else
        yield value if block_given?
        value
      end
    end

    # Set a value on the Dash in a Hash-like way. Only works
    # on pre-existing attributes.
    def []=(attribute, value)
      assert_attribute_exists! attribute

      if attr_required?(attribute) && value.nil?
        raise ArgumentError, "The attribute '#{attribute}' is required"
      end

      #transform value with transform
      transform = self.class.attributes[attribute][:transform]
      if !transform.nil?
        if transform.is_a?(Proc)
          value = transform.call(self, value)
        end
      end
      #transform value with type
      type = self.class.attributes[attribute][:type]
      if !type.nil?
        value = type[value]
      end
      super(attribute, value)
    end

    private

    def assert_attribute_exists!(attribute)
      unless self.class.has_attribute?(attribute)
        raise NoMethodError, "The attribute '#{attribute}' is not defined for #{self.class.name}."
      end
    end

    def attr_required?(attribute)

      !skip_required_attrs.include?(attribute) &&
      self.class.attr_required?(attribute)

      # condition = self.class.required_attributes[attribute][:condition]
      # case condition
      # when Proc   then !!instance_exec(&condition)
      # when Symbol then !!send(condition)
      # else             !!condition
      # end
    end

  end
end