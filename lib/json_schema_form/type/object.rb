class Hash
  
  def bury *args
    if args.count < 2
      raise ArgumentError.new("2 or more arguments required")
    elsif args.count == 2
      self[args[0]] = args[1]
    else
      arg = args.shift
      self[arg] = {} unless self[arg]
      self[arg].bury(*args) unless args.empty?
    end
    self
  end
end

module JsonSchemaForm
  module Type
    class Object < Base

      # instantiate object classes when setting
      # a property on the properties key
      PROPERTIES_PROC = ->(instance, obj) {
        obj.each do |name, definition|
          path = if instance&.meta&.dig(:path)
            instance.meta[:path].concat([:properties, name])
          else
           [:properties, name]
          end
          obj[name] = instance.class::BUILDER.call(definition, {
            parent: instance,
            path: path
          })
        end
      }

      # instantiate object classes when setting
      # a property on the allOf[:then] key
      All_OF_PROC = ->(instance, allOfArray) {
        allOfArray.map.with_index do |condition_hash, index|
          condition_hash.each do |key, object_schema|
            path = if instance&.meta&.dig(:path)
              instance.meta[:path].concat([:allOf, index, :then])
            else
              [:allOf, index, :then]
            end
            condition_hash[:then] = instance.class::BUILDER.call(
              condition_hash[:then].merge(__skip_required_attrs: [:type]),
              {
                parent: instance,
                is_subschema: true,
                path: path
              }
            )
          end
        end
      }

      # set attribute methods for defaults and transforms.
      # Also validate 'type' key with raisable error
      attribute :type, {
        type: Types::String.enum('object')
      }
      attribute? :required, default: ->(instance) { [].freeze }
      attribute? :properties, default: ->(instance) { {}.freeze }, transform: PROPERTIES_PROC
      attribute? :allOf, default: ->(instance) { [].freeze }, transform: All_OF_PROC

      def validation_schema
        instance = self
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:type).filled(:string).value(included_in?: ['object'])
          optional(:required).value(:array?).array(:str?)
          optional(:properties).value(:hash)
          optional(:allOf).array(:hash) do
            required(:if).hash do
              required(:properties).value(:hash)
            end
            required(:then).value(:hash)
          end
        end
      end

      def schema_validation_hash
        json = super
        json[:properties]&.clear
        json[:allOf]&.each do |condition|
          condition[:then]&.clear
          condition.dig(:if, :properties)&.clear
        end
        json
      end

      def schema_errors
        errors_hash = Marshal.load(Marshal.dump(super)) #new reference
        self.merged_properties.each do |name, prop|
          prop_errors = prop.schema_errors
          unless prop_errors.empty?
            prop_errors.flatten_to_root.each do |k,v|
              array = prop.meta[:path].dup.concat(k.to_s.split('.')).push(v)
              errors_hash.bury(*array)
            end
          end
        end
        errors_hash
      end

      #TODO should this include dynamic properties?
      def validations
        hash = super
        self[:properties].each do|k,v|
          hash[k] = v.validations
        end
        hash.compact
      end

      ###property management###
  
      def add_property(id, definition)
        new_definition = {}.merge(definition)
        new_definition[:'$id'] = "/properties/#{id}"

        hash = self[:properties]
        hash[id] = new_definition
        self[:properties] = self.symbolize_recursive(hash)
      end

      def remove_property(id)
        self[:properties] = self[:properties].reject do |k, v| 
          k == id
        end
      end

      ###required###
  
      def add_required_property(name)
        self[:required] = self[:required].push(name.to_s).uniq
      end
  
      def remove_required_property(name)
        self[:required] = self[:required].reject{|n| n == name.to_s }
      end

      ###general###

      # get properties
      def properties
        self[:properties]
      end

      # get dynamic properties
      def dynamic_properties(levels=nil)
        get_dynamic_forms(levels).map{|f| f[:properties]}.reduce({}, :merge)
      end

      # get own and dynamic properties
      def merged_properties(levels=nil)
        self[:properties].merge(
          self.dynamic_properties(levels)
        )
      end
      
      # Lists the names of the properties defined in the schema
      def property_names
        self&.[](:properties)&.keys || []
      end

      # Lists the names of the dynamic properties defined as sub-schemas
      def dynamic_property_names(levels=nil)
        self.dynamic_properties(levels)&.keys
      end

      # Lists the names of both dynamic and own properties
      def merged_property_names(levels=nil)
        self.merged_properties(levels)&.keys
      end
  
      # returns the property JSON definition inside the properties key
      def get_property(property)
        self&.dig(:properties, property.to_sym)
      end

      def get_dynamic_property(property, levels=nil)
        dynamic_properties(levels).try(:[], property.to_sym)
      end

      def get_merged_property(property, levels=nil)
        merged_properties(levels).try(:[], property.to_sym)
      end

      # returns the property JSON definition inside the properties key
      def has_property?(property)
        !self.get_property(property).nil?
      end

      def has_dynamic_property?(property, levels=nil)
        !self.get_dynamic_property(property, levels).nil?
      end

      def has_merged_property?(property, levels=nil)
        !self.get_merged_property(property, levels).nil?
      end
  
      # returns the type of an property
      def property_type(property)
        get_property(property)[:type]
      end

      def dynamic_property_type(property, levels=nil)
        get_dynamic_property(property, levels=nil)[:type]
      end

      def merged_property_type(property, levels=nil)
        get_merged_property(property, levels=nil)[:type]
      end

      # Returns a Hash with property names and types
      def properties_type_mapping
        hash = {}
        property_names.each do |attr|
          hash[attr] = property_type(attr)
        end
        hash
      end

      def dynamic_properties_type_mapping(levels=nil)
        hash = {}
        dynamic_property_names(levels).each do |attr|
          hash[attr] = dynamic_property_type(attr, levels)
        end
        hash
      end

      def merged_properties_type_mapping(levels=nil)
        hash = {}
        merged_property_names(levels).each do |attr|
          hash[attr] = merged_property_type(attr, levels)
        end
        hash
      end
  
      def get_validations_for_property(property)
        get_property(property).validations
      end

      #TODO
      # def get_validations_for_dynamic_property(property, levels)
      #   get_property(property).validations
      # end

      #todo make this private?
      def get_dynamic_forms(levels=nil, level=0)
        return [] if levels && level >= levels
        forms_array=[]
        self[:allOf]&.each do |condition_hash|
          form = condition_hash[:then]
          forms_array.push(form)
          forms_array = forms_array.concat(form.get_dynamic_forms(levels, level + 1))
        end
        forms_array
      end

    end
  end
end