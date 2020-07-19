module JsonSchemaForm
  module Type
    class Object < Base

      PROPERTIES_PROC = ->(instance, value) {
        value.transform_values do |definition|
          BUILDER.call(definition, {parent: instance})
        end
      }

      All_OF_PROC = ->(instance, value) {
        value.map do |obj|
          schema_object = JsonSchemaForm::Type::Object.new(
            obj[:then].merge(skip_required_attrs: [:type]), 
            {parent: instance, is_subschema: true}
          )
          obj.merge({
            then: schema_object
          })
        end
      }

      # attribute :type, {
      #   type: Types::String.enum('object')
      # }
      attribute? :required, default: ->(instance) { [].freeze }
      attribute? :properties, default: ->(instance) { {}.freeze }, transform: PROPERTIES_PROC
      attribute? :allOf, default: ->(instance) { [].freeze }, transform: All_OF_PROC

      def validation_schema
        instance = self
        super.merge(
          Dry::Schema.JSON do
            #config.validate_keys = true
            required(:type).filled(:string).value(included_in?: ['object'])
            optional(:required).value(:array?).array(:str?)
            optional(:properties).hash do
              instance.properties.each do |name, prop|
                optional(name.to_sym).hash(prop.validation_schema)
              end
            end
            optional(:allOf).array(:hash) do
              required(:if).hash do
                required(:properties).value(:hash)
              end
              required(:then).value(:hash)
            end
            # instance._all_of_schemas(self)
          end
        )
      end

      def validation_hash
        json = self.as_json
        json['properties']&.clear
        json['allOf']&.each do |condition|
          condition['then']&.clear
          condition.dig('if', 'properties')&.clear
        end
        json
      end

      def errors
        errors_hash = super
        self.merged_properties.each do |name, prop|
          errors = prop.errors
          errors_hash[name] = errors unless errors.empty?
        end
        errors_hash
      end

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
        self[:allOf].each do |condition_hash|
          form = condition_hash[:then]
          forms_array.push(form)
          forms_array = forms_array.concat(form.get_dynamic_forms(levels, level + 1))
        end
        forms_array
      end

    end
  end
end