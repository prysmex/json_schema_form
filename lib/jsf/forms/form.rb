module JSF
  module Forms
    DEFAULT_LOCALE = 'en'.freeze
    AVAILABLE_LOCALES = ['es', 'en'].freeze
    VERSION = '3.2.0'.freeze
    
    # A `Form` is a 'object' schema that is used to validate a `JSF::Forms::Document`.
    #
    # @todo add more description
    #
    # It follows the following recursive structure:
    #
    # - definitions (only in top level)
    #   - JSF::Forms::ResponseSet
    #     - JSF::Forms::Response
    #   - JSF::Schema or JSF::Forms::Form
    # - properties
    #   - JSF::Forms::Field
    # - allOf
    #   - JSF::Forms::Form
    #
    class Form < BaseHash
    
      include JSF::Core::Schemable
      include JSF::Validations::Validatable
      include JSF::Core::Buildable
      include JSF::Core::Type::Objectable
    
      set_strict_type('object')

      CONDITIONAL_FIELDS = [
        JSF::Forms::Field::Select,
        JSF::Forms::Field::Switch,
        JSF::Forms::Field::NumberInput
      ].freeze
    
      SCORABLE_FIELDS = [
        JSF::Forms::Field::Checkbox,
        JSF::Forms::Field::Slider,
        JSF::Forms::Field::Switch,
        JSF::Forms::Field::Select
      ].freeze

      COMPONENT_PROPERTY_CLASS_PROC = Proc.new do |value|
        is_string = value.is_a?(::String)

        hash = {
          # fields
          'checkbox' => JSF::Forms::Field::Checkbox,
          'component' => JSF::Forms::Field::Component,
          'date_input' => JSF::Forms::Field::DateInput,
          'file_input' => JSF::Forms::Field::FileInput,
          'markdown' => JSF::Forms::Field::Markdown,
          'number_input' => JSF::Forms::Field::NumberInput,
          'select' => JSF::Forms::Field::Select,
          'signature' => JSF::Forms::Field::Signature,
          'slider' => JSF::Forms::Field::Slider,
          'static' => JSF::Forms::Field::Static,
          'switch' => JSF::Forms::Field::Switch,
          'text_input' => JSF::Forms::Field::TextInput,
          'section' => JSF::Forms::Section
        }

        if is_string
          hash[value]
        else
          hash.find{|component, klass| klass == value || value.is_a?(klass) }&.first
        end
      end

      # TODO remove after 3.2.0 migrate!
      DEPRECATED_PROPERTY_MAP = Proc.new do |value|
        if value.dig(:displayProperties, :useSection)
          JSF::Forms::Section
        elsif value.key?(:$ref)
          if value.dig(:displayProperties, :isSelect)
            JSF::Forms::Field::Select
          else
            ::JSF::Forms::Field::Component
          end
        else
          case value[:type]
          when 'string'
            if value[:format] == 'date-time'
              JSF::Forms::Field::DateInput
            else
              JSF::Forms::Field::TextInput
            end
          when 'number'
            if value&.dig(:displayProperties, :useSlider)
              JSF::Forms::Field::Slider
            else
              JSF::Forms::Field::NumberInput
            end
          when 'boolean'
            JSF::Forms::Field::Switch
          when 'array'
            if value.dig(:items, :format) == 'uri'
              JSF::Forms::Field::FileInput
            else
              JSF::Forms::Field::Checkbox
            end
          when 'null'
            if value&.dig(:displayProperties, :useHeader) || value&.dig(:displayProperties, :useInfo)
              JSF::Forms::Field::Markdown
            elsif value[:static]
              JSF::Forms::Field::Static
            end
          end
        end
      end

      # converts and Integer into a string that can be used for
      # JSF::Forms::ComponentRef and JSF::Forms::Form inside 'definitions'
      #
      # @param [Integer] id
      # @return [String]
      def self.component_ref_key(id)
        "shared_schema_template_#{id}"
      end
      
      # Defined in a Proc so it can be reused:
      ATTRIBUTE_TRANSFORM = ->(attribute, value, instance, init_options) {
    
        klass = case instance
        when JSF::Forms::Form
    
          case attribute
          when 'definitions'
            if value[:isResponseSet]
              JSF::Forms::ResponseSet
            elsif value[:type] == 'object' #replaced schemas
              JSF::Forms::Form
            elsif value.key?(:$ref) # shared definition
              JSF::Forms::ComponentRef
            end
          when 'allOf'
            JSF::Forms::Condition
          when 'properties'
            component_name = value.dig(:displayProperties, :component)
            if component_name
              COMPONENT_PROPERTY_CLASS_PROC.call(component_name)
            else
              DEPRECATED_PROPERTY_MAP.call(value)
            end
          end
          
        end
        
        # return if a condition is met, otherwise let error be raised
        return klass.new(value, init_options) if klass

        raise StandardError.new("JSF::Forms::Form transform conditions not met: (attribute: #{attribute}, value: #{value}, meta: #{instance.meta})")
      }
    
      # Utility proc to DRY code, expands a condition type to a path
      #
      # @param [Symbol] type
      # @return [Array]
      CONDITION_TYPE_TO_PATH= ->(type) {
        case type.to_sym
        when :const
          [:const]
        when :not_const
          [:not, :const]
        when :enum
          [:enum]
        when :not_enum
          [:not, :enum]
        else
          raise ArgumentError.new("#{type} is not a whitelisted condition type")
        end
      }
    
      update_attribute 'definitions', default: ->(data) { self.meta[:is_subschema] ? nil : {}.freeze }
      update_attribute 'properties', default: ->(data) { {}.freeze }
      update_attribute 'required', default: ->(data) { [].freeze }
      update_attribute 'allOf', default: ->(data) { [].freeze }
      update_attribute 'type', default: ->(data) { self.meta[:is_subschema] ? nil : 'object' }
      update_attribute 'schemaFormVersion', default: ->(data) { self.meta[:is_subschema] ? nil : VERSION }
      update_attribute '$schema', default: ->(data) { self.meta[:is_subschema] ? nil : "http://json-schema.org/draft-07/schema#" }
      attribute? 'availableLocales', default: ->(data) { self.meta[:is_subschema] ? nil : [].freeze }
      
      def initialize(obj={}, options={})
        options = {
          attributes_transform_proc: JSF::Forms::Form::ATTRIBUTE_TRANSFORM
        }.merge(options)
    
        super(obj, options)
      end
    
      ##################
      ###VALIDATIONS####
      ##################
      
      # Validation schema used for building own errors hash
      #
      # @param passthru [Hash] Options passed
      # @return [Dry::Schema::JSON] Schema
      def validation_schema(passthru)
        is_subschema = meta[:is_subschema]
        Dry::Schema.JSON do
          config.validate_keys = true
    
          before(:key_validator) do |result|
            JSF::Validations::DrySchemaValidatable::WITHOUT_SUBSCHEMAS_PROC.call(result.to_h)
          end
    
          required(:allOf).array(:hash)
          required(:properties).value(:hash)
          required(:required).value(:array?).array(:str?)
          if !is_subschema
            optional(:'$id').filled(:string)
            required(:'$schema').filled(:string)
            required(:availableLocales).value(:array?).array(:str?)
            required(:definitions).value(:hash)
            required(:schemaFormVersion).value(eql?: VERSION)
            optional(:'title').maybe(:string) #ToDo deprecate?
            required(:type).filled(Types::String.enum('object'))
            if passthru[:is_inspection]
              required(:hasScoring) { bool? }
            end
          else
            optional(:'$schema').filled(:string)
            optional(:type).filled(Types::String.enum('object'))
          end
    
        end
      end
      
      # Build instance's erros hash from the validation_schema. It also validates
      # the following:
      #
      # - ensure referenced component properties exist
      # - ensure property $id key matches with field id
      # - ensure referenced response sets exist
      # - ensure JSF::Forms::Field::Component only exist in root form
      # - ensure components have a pair in 'definitions'
      # - ensure only allowed fields contain (conditional) fields
      #
      # @param passthru [Hash{Symbol => *}] Options passed
      # @return [Hash{Symbol => *}] Errors
      def errors(**passthru)
        errors_hash = JSF::Validations::DrySchemaValidatable::CONDITIONAL_SCHEMA_ERRORS_PROC.call(
          passthru,
          self
        )

        children_errors = super

        # validate sorting
        if run_validation?(passthru, self, :sorting)
          unless self.verify_sort_order
            add_error_on_path(
              errors_hash,
              ['base'],
              "incorrect sorting, should start with 0 and increase consistently"
            )
          end
        end

        self[:definitions]&.each do |k, v|
          # ensure referenced component properties exist
          if run_validation?(passthru, self, :component_presence)
            if v.is_a?(JSF::Forms::ComponentRef) && v.component.nil?
              add_error_on_path(
                errors_hash,
                ['base'],
                "missing component field for component reference (#{k})"
              )
            end
          end
        end
    
        self[:properties]&.each do |k, field|

          # ensure property $id key matches with field id
          if run_validation?(passthru, self, :match_key)
            if field['$id'] != "#/properties/#{k}"
              add_error_on_path(
                children_errors,
                ['properties', k, '$id'],
                "'#{field['$id']}' did not match property key '#{k}'"
              )
            end
          end

          # ensure referenced response sets exist
          if run_validation?(passthru, self, :response_set_presence)
            if field.respond_to?(:response_set) && field.response_set_id && field.response_set.nil?
              add_error_on_path(
                children_errors,
                (['properties', k] + field.class::RESPONSE_SET_PATH),
                "response set #{field.response_set_id} not found"
              )
            end
          end

          # ensure JSF::Forms::Field::Component only exist in root form
          if run_validation?(passthru, self, :component_in_root)
            if self.meta[:is_subschema] && field.is_a?(JSF::Forms::Field::Component)
              add_error_on_path(
                errors_hash,
                ['base'],
                "components can only exist in root schema (#{k})"
              )
            end
          end

          # ensure components have a pair in 'definitions'
          if run_validation?(passthru, self, :component_ref_presence)
            if field.is_a?(JSF::Forms::Field::Component)
              # response should be found
              if field.component_definition.nil?
                add_error_on_path(
                  errors_hash,
                  ['base'],
                  "missing component reference for field #{field.component_definition_pointer}"
                )
              end
            end
          end

          # ensure only allowed fields contain (conditional) fields
          if CONDITIONAL_FIELDS.include?(field.class)
          else
            if run_validation?(passthru, self, :conditional_fields)
              if field.dependent_conditions.size > 0
                fields = JSF::Forms::Form::CONDITIONAL_FIELDS.map{|klass| klass.name.split('::').last}.join(', ')
                add_error_on_path(
                  errors_hash,
                  ['base'],
                  "only the following fields can have conditionals (#{fields})"
                )
              end
            end
          end

        end

        children_errors.merge(errors_hash)
      end

      # Checks that all properties are valid for locale, if field
      # respond to 'response_set', also check that response set is
      # valid for locale
      #
      # @param locale [String,Symbol] locale
      # @return [Boolean] if valid
      def valid_for_locale?(locale = DEFAULT_LOCALE)
        prop = nil

        # check properties and their response_sets
        self.each_form(ignore_sections: true) do |form|
          prop = form&.properties&.any? do |k,v|
            if v.respond_to?(:response_set)
              !v.valid_for_locale?(locale) || !v.response_set&.valid_for_locale?(locale)
            else
              !v.valid_for_locale?(locale)
            end
          end
    
          break prop if prop
        end

        !prop
      end
    
      ##############
      ###METHODS####
      ##############

      def example(*args, &block)
        JSF::Forms::FormBuilder.example(*args, &block)
      end
    
      ###########################
      ###COMPONENT MANAGEMENT####
      ###########################

      # Util
      #
      # @see .component_ref_key
      def component_ref_key(*args)
        self.class.component_ref_key(*args)
      end
    
      # Gets all component definitions, which may be only the reference
      # or the replaced form
      #
      # @return [Hash{String => JSF::Forms::Form, JSF::Forms::ComponentRef}]
      def component_definitions
        self[:definitions].select do |k,v|
          v.is_a?(JSF::Forms::ComponentRef) || v.is_a?(JSF::Forms::Form)
        end
      end

      # Adds a JSF::Forms::ComponentRef to the 'definitions' key
      #
      # @param [Integer] db_id (DB id)
      # @return [JSF::Forms::ComponentRef]
      def add_component_definition(db_id:, definition: nil)
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer
        
        definition ||= JSF::Forms::FormBuilder.example('component_ref')
        definition = self.add_definition(component_ref_key(db_id), definition)
        definition.db_id = db_id if definition.is_a?(JSF::Forms::ComponentRef)
        definition
      end

      # Finds a JSF::Forms::ComponentRef from a db_id
      #
      # @param [Integer] db_id
      # @return [JSF::Forms::ComponentRef, JSF::Forms::Form]
      def get_component_definition(db_id:)
        self['definitions'].find do |k,v|
          k == component_ref_key(db_id)
        end&.last
      end

      # Removes a JSF::Forms::ComponentRef or JSF::Forms::Form from the 'definitions' key
      #
      # @param [Integer] db_id (DB id)
      # @return [JSF::Forms::Form] mutated self
      def remove_component_definition(db_id:)
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer
        key = component_ref_key(db_id)

        self.remove_definition(key)
      end

      # Adds a component. If index is passed, it will also add a JSF::Forms::Field::Component
      # on the properties key
      #
      # @param [Integer] db_id (DB id)
      # @param [Integer] index
      # @return [JSF::Forms::ComponentRef]
      def add_component_pair(db_id:, index:, definition: nil, options: {})
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer
        key = component_ref_key(db_id)

        # add property
        component = JSF::Forms::FormBuilder.example('component')
        prop = case index
        when Integer
          insert_property_at_index(index, key, component, options)
        when :append
          append_property(key, component, options)
        when :prepend
          prepend_property(key, component, options)
        else
          raise ArgumentError.new("invalid index argument #{index}")
        end

        prop.db_id = db_id

        # add definition
        add_component_definition(db_id: db_id, definition: definition)
      end

      # Removes a component ref. If remove_component is true, it will also remove the matching JSF::Forms::Field::Component
      #
      # @param [Integer] db_id (DB id)
      # @param [Boolean] remove_component set to true to also remove related JSF::Forms::Field::Component
      # @return [JSF::Forms::Form] mutated self
      def remove_component_pair(db_id:)
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer
        key = component_ref_key(db_id)

        # remove property
        # self.remove_property(key)
        self[:properties].reject! do |k,v|
          k == key
        end
        resort!

        # remove definition
        self.remove_definition(key)
      end
    
      ##############################
      ###RESPONSE SET MANAGEMENT####
      ##############################
    
      # get responseSets
      #
      # @return [Hash{String => JSF::Forms::ResponseSet}]
      def response_sets
        self[:definitions].select do |k,v|
          v[:isResponseSet]
        end
      end
    
      # Adds a new response_set
      #
      # @param [String] id
      # @param [Hash] definition
      # @return [JSF::Forms::ResponseSet]
      def add_response_set(id, definition)
        self.add_definition(id, definition)
      end
    
      ##########################
      ###PROPERTY MANAGEMENT####
      ##########################
    
      # get properties
      #
      # @return [Hash{String => JSF::Forms::Field::*}]
      def properties
        self[:properties]
      end
    
      # get own and dynamic properties
      #
      # @return [Hash{String => JSF::Forms::Field::*}]
      def merged_properties(**args)
        properties = {}
        each_form(**args) do |form|
          properties.merge!(form&.properties || {})
        end
        properties
      end
    
      # gets the property definition inside the properties key
      #
      # @param [String, Symbol]
      # @return [JSF::Forms::Field::*]
      def get_property(property)
        self.dig(:properties, property)
      end
    
      # gets the property definition of the first match in a root or subschema property
      #
      # @param [String, Symbol]
      # @return [JSF::Forms::Field::*]
      def get_merged_property(property, **args)
        prop = nil
        each_form(**args) do |form|
          props = form&.properties
          if props&.key?(property)
            prop = props[property] 
            break
          end
        end
        prop
      end
    
      # Adds a property with a sort value of 0 and resorts all other properties
      #
      # @see insert_property_at_index for arguments
      #
      # @return [JSF::Forms::Field::*] added property
      def prepend_property(*args, &block)
        insert_property_at_index(self.min_sort || 0, *args, &block)
      end
    
      # Adds a property with a sort value 1 more than the max and resorts all other properties
      #
      # @see insert_property_at_index for arguments
      #
      # @return [JSF::Forms::Field::*] added property
      def append_property(*args, &block)
        max_sort = self.max_sort
        index = max_sort.nil? ? 0 : max_sort + 1
        insert_property_at_index(index, *args, &block)
      end
    
      # Adds a property with a specified sort value and resorts all other properties
      #
      # @param id [String,Symbol] name of the property
      # @param definition [Hash] the schema to add
      # @param options[:required] [Boolean] if the property should be required
      # @return [JSF::Forms::Field::*] added property
      def insert_property_at_index(index, id, definition, options={}, &block)
        prop = add_property(id, definition, options, &block)
        prop.sort = (index - 0.5)
        resort!
        prop
      end

      # calls remove_property and resorts the form
      #
      # @return [<Type>] <description>
      def remove_property(*args)
        val = super
        resort!
        val
      end
    
      # Moves a property to a specific sort value and resorts needed properties
      #
      # @param id [String,Symbol] name of property to move
      # @param target [Integer] sort value to set
      # @return [void]
      def move_property(id, target)
        property = self[:properties]&.find{|k,v| v.key_name == id.to_s }&.last
        return unless property

        current = property.sort
        range = Range.new(*[current, target].sort)
        selected = sorted_properties.select{|prop| range.include?(prop.sort) }
        if target > current
          selected.each{|prop| prop.sort -= 1 }
        else
          selected.each{|prop| prop.sort += 1 }
        end
        property.sort = target
        resort!
      end
    
      # gets the minimum sort value for all properties
      #
      # @return [Integer]
      def min_sort
        self[:properties]&.map{|k,v| v&.sort }&.min
      end
    
      # gets the maximum sort value for all properties
      #
      # @return [Integer]
      def max_sort
        self[:properties]&.map{|k,v| v&.sort }&.max
      end
    
      # gets a property by a sort value
      #
      # @return [JSF::Forms::Field]
      def get_property_by_sort(i)
        self[:properties]&.find{|k,v| v&.sort == i}&.last
      end
    
      # Checks if all sort values are consecutive and starting with 0
      #
      # @return [Boolean]
      def verify_sort_order
        for i in 0...(self[:properties]&.size || 0)
          return false if get_property_by_sort(i).nil?
        end
        true
      end
    
      # Sorts 'properties' by sort
      #
      # @return [Array<JSF::Forms::Field>]
      def sorted_properties
        self[:properties]&.values&.sort_by{|v| v&.sort} || []
      end
    
      # fixes sorting in case sort values are not consecutive.
      #
      # @return [void]
      def resort!
        sorted = self.sorted_properties
        for i in 0...self[:properties].size
          property = sorted[i]
          property.sort = i
        end
      end
    
      # Retrieves a condition
      #
      # @param dependent_on [Symbol] name of property the condition depends on
      # @param type [Symbol] type of condition to filter by
      # @param value [String,Boolean,Integer] Value that makes the condition TRUE
      # @return [JSF::Schema]
      def get_condition(dependent_on, type, value)
        cond_path = CONDITION_TYPE_TO_PATH.call(type)
        self[:allOf]&.find do |condition|
          if [:enum, :not_enum].include?(type)
            condition.dig(:if, :properties, dependent_on, *cond_path)&.include?(value)
          else
            condition.dig(:if, :properties, dependent_on, *cond_path) == value
          end
        end
      end
    
      # Appends a new condition or retrieves a matching existing one
      #
      # @param dependent_on [Symbol] name of property the condition depends on
      # @param type [Symbol] type of condition to filter by
      # @param value [String,Boolean,Integer] Value that makes the condition TRUE
      # @return condition [JSF::Schema] added or retrieved condition hash
      def add_condition(dependent_on, type, value)
        raise ArgumentError.new('dependent property not found') if self.get_property(dependent_on).nil?

        #ensure transform is triggered
        self[:allOf] = (self[:allOf] || []) << {
          if: {
            required: [dependent_on.to_s],
            properties: {
              :"#{dependent_on}" => SuperHash::Utils.bury({}, *CONDITION_TYPE_TO_PATH.call(type), value)
            }
          },
          then: {}
        }
        self[:allOf].last
      end
    
      # Adds a dependent property inside a subschema
      #
      # @param sort_value [Integer, :prepend, :append]
      # @param property_id [String,Symbol] name of property to be added
      # @param definition [Hash] the property to be added
      # @param dependent_on [Symbol] name of property the condition depends on
      # @param type [Symbol] type of condition
      # @param value [Symbol] value that makes the condition TRUE
      # @return [JSF::Forms::Field::*] the added property
      def insert_conditional_property_at_index(sort_value, property_id, definition, dependent_on:, type:, value:, **options, &block)
        unless sort_value.is_a?(Integer) || [:prepend, :append].include?(sort_value)
          raise ArgumentError.new("sort must be an Integer, :prepend or :append, got #{sort_value}")
        end
    
        condition = get_condition(dependent_on, type, value) || add_condition(dependent_on, type, value)
        added_property = case sort_value
        when :prepend
          condition[:then].prepend_property(property_id, definition, options, &block)
        when :append
          condition[:then].append_property(property_id, definition, options, &block)
        else
          condition[:then].insert_property_at_index(sort_value, property_id, definition, options, &block)
        end
        added_property
      end
    
      # Appends a dependent property inside a subschema
      #
      # @return [JSF::Forms::Field::*]
      def append_conditional_property(*args, **kwargs, &block)
        insert_conditional_property_at_index(:append, *args, **kwargs, &block)
      end
    
      # Prepends a dependent property inside a subschema
      #
      # @return [JSF::Forms::Field::*]
      def prepend_conditional_property(*args, **kwargs, &block)
        insert_conditional_property_at_index(:prepend, *args, **kwargs, &block)
      end

      ###########
      #Utilities#
      ###########

      # If returns true if inside the root key 'definitions'
      #
      # @return [Boolean]
      def is_component_definition?
        self.meta[:path].first == 'definitions'
      end

      # Util that recursively iterates and yields each JSF::Forms::Form along with other relevant
      # params.
      #
      # @param ignore_all_of [Boolean] if true, does not iterate into forms inside a allOf
      # @param ignore_definitions [Boolean]
      # @param ignore_sections [Boolean] if true, does not iterate into forms inside a JSF::Forms::Section
      # @param is_create [Boolean] pass true to consider 'hideOnCreate' display property
      # @param levels [Integer] Max depth of allOf nesting to starting from start_level
      # @param skip_tree_when_hidden [Boolean] forces skiping trees when hidden
      # @param start_level [Integer] Depth of allOf nesting to ignore (0 includes current)
      #
      # @yieldparam [JSF::Forms::Form] form, the current form
      # @yieldparam [JSF::Forms::Condition] condition, condition the form depends on
      # @yieldparam [Proc] skip_branch_proc, halts execution in a branch if returns true
      # @yieldparam [Integer] nested level, 0 for root form
      #
      # @return [void]
      def each_form(
          current_level: 0,
          ignore_all_of: false,
          ignore_definitions: true,
          ignore_sections: false,
          is_create: false,
          levels: nil,
          skip_tree_when_hidden: false,
          start_level: 0,
          &block
        )
          # stop execution if levels limit matches
          return if !levels.nil? && current_level >= (start_level + levels)

          # create kwargs hash to dry code when calling recursive
          kwargs = {}
          kwargs[:ignore_sections] = ignore_sections
          kwargs[:ignore_definitions] = ignore_definitions
          kwargs[:ignore_all_of] = ignore_all_of
          kwargs[:is_create] = is_create
          kwargs[:levels] = levels
          kwargs[:skip_tree_when_hidden] = skip_tree_when_hidden
          kwargs[:start_level] = start_level

          # yield only if reached start_level or start_level is nil
          if start_level.nil? || current_level >= start_level
            condition = self.meta[:parent] if self.meta[:parent].is_a?(JSF::Forms::Condition)
            skip_branch_proc = Proc.new{ return }
            yield(self, condition, skip_branch_proc, current_level)
          end

          # iterate properties and call recursive on JSF::Forms::Section
          unless ignore_sections
            self.properties&.each do |key, prop|
              next unless prop.is_a?(JSF::Forms::Section)

              if skip_tree_when_hidden && !prop.visible(is_create: is_create)
                next
              end
              
              prop[:items]&.each_form(
                current_level: current_level + 1,
                **kwargs,
                &block
              )
            end
          end

          # iterate definitions and call recursive on JSF::Forms::Form
          unless ignore_definitions
            self[:definitions]&.each do |key, prop|
              next unless prop.is_a?(JSF::Forms::Form)
              
              prop&.each_form(
                current_level: current_level + 1,
                **kwargs,
                &block
              )
            end
          end

          # iterate allOf
          unless ignore_all_of
            self[:allOf]&.each do |condition|
              prop = condition.condition_property

              skip_hidden = skip_tree_when_hidden && !prop.visible(is_create: is_create)

              if skip_hidden
                next
              end
    
              # go to next level recursively
              condition[:then]&.each_form(
                current_level: current_level + 1,
                **kwargs,
                &block
              )
    
            end
          end

      end

      # Similar to each_form with the following differences:
      #
      # - adds three yield params, document, empty_document and document_path
      #
      # @note when it encounters a JSF::Forms::Section, it yields the same JSF::Forms::Form
      #   for each value in the document's array. If you want forms to only be yielded once,
      #   use each_form
      #
      # @param skip_property_proc [Proc] skips a property if it returns true when called
      #
      # @yieldparam [JSF::Forms::Form] form
      # @yieldparam [JSF::Forms::Condition] condition
      # @yieldparam [Proc] skip_branch_proc
      # @yieldparam [Hash] document, the current document for the yielded JSF::Forms::Form
      # @yieldparam [Hash] empty_document
      # @yieldparam [Array<String,Integer>] document_path
      #
      # @return [void]
      def each_form_with_document(document, document_path: [], skip_property_proc: nil,  **kwargs, &block)
        empty_document = {}

        # since JSF::Forms::Field::Component and JSF::Forms::Section are already
        # handled, we ignore them in the each_form iterator
        each_form(ignore_sections: true, ignore_definitions: true, **kwargs) do |form, *args|

          yield(form, *args, document, empty_document, document_path)

          # handle all properties that have a value that is a hash or an array because the document_path is modified
          form[:properties].each do |key, property|
            next if kwargs[:skip_tree_when_hidden] && !property.visible(is_create: kwargs[:is_create])
            next if skip_property_proc&.call(key, property)
            
            # go recursive
            case property
            when JSF::Forms::Section
              value = document[key]
              empty_document[key] ||= []
              value&.map&.with_index do |doc, i|
                empty_document[key][i] = property
                  .form
                  .each_form_with_document(
                    doc,
                    document_path: document_path + [key, i],
                    skip_property_proc: skip_property_proc,
                    **kwargs,
                    &block
                  )
              end
            when JSF::Forms::Field::Component
              value = document[key] || {}
              empty_document[key] = property
                .component_definition
                .each_form_with_document(
                  value,
                  document_path: (document_path + [key]),
                  skip_property_proc: skip_property_proc,
                  **kwargs,
                  &block
                )
            end
          end

        end

        empty_document
      end

      # # Recursively calculates the document path for a property
      # #
      # # @ToDo this has the problem that properties inside a section are ignored
      # #
      # # @param [String] key name of the property
      # # @return [Array<String>]
      # def document_path_for_property(key, **kwargs)
      #   path = nil

      #   self.each_form_with_document(
      #     {},
      #     **kwargs
      #   ) do |form, condition, skip_branch_proc, current_level, current_doc, current_empty_doc, document_path|
      #     if form.properties.key?(key.to_s)
      #       path = document_path
      #       break
      #     end
      #   end

      #   path
      # end

      # Builds a new hash considering the following:
      #
      # - removes all nil values
      # - removes all unknown keys
      # - removes all keys with displayProperties.hidden
      # - removes all keys with displayProperties.hideOnCreate if record is new
      # - removes all keys in unactive trees
      #
      # @return [JSF::Forms::Document] mutated document
      def cleaned_document(document, is_create: false, condition_proc: nil, **kwargs)
        # iterate recursively through schemas
        new_document = each_form_with_document(
          document,
          skip_tree_when_hidden: true,
          is_create: is_create,
          **kwargs
        ) do |form, condition, skip_branch_proc, current_level, current_doc, current_empty_doc, document_path|
          
          # skip unactive trees
          skip_branch_proc.call if condition&.evaluate(current_doc, &condition_proc) == false
          
          form[:properties].each do |key, property|
            next unless property.visible(is_create: is_create)

            value = current_doc[key]
            next if value.nil? # skip nil value

            current_empty_doc[key] = value
          end
        end

        new_document['meta'] = document['meta'] if document.key?('meta')
        new_document
      end

      # Calculates the maximum attainable score given a document. This
      # considers which paths are active in the form.
      #
      # @note does not consider forms inside 'definitions' key
      #
      # @todo consider Section count
      #
      # @param document [Hash{String}, JSF::Forms::Document]
      # @return [Float, NilClass]
      def set_specific_max_scores!(document, is_create: false, condition_proc: nil, **kwargs)

        score_value = self.score_initial_value

        # iterate recursively through schemas
        specific_max_score_document = each_form_with_document(
          document,
          skip_tree_when_hidden: true,
          is_create: is_create,
          **kwargs
        ) do |form, condition, skip_branch_proc, current_level, current_doc, current_empty_doc, document_path|

          # skip unactive trees
          skip_branch_proc.call if condition&.evaluate(current_doc, &condition_proc) == false

          # iterate properties
          form[:properties].each do |k, prop|
            next unless prop.visible(is_create: is_create)
            next unless JSF::Forms::Form::SCORABLE_FIELDS.include?(prop.class)

            value = current_doc.dig(k)

            field_score = if value.nil?
              prop.max_score
            else

              # check for any visible child field
              visible_children = prop.dependent_conditions.any? do |cond|
                next unless cond.evaluate(current_doc, &condition_proc)

                cond.dig(:then, :properties)&.any? do |k,v|
                  v.visible(is_create: is_create)
                end
              end
        
              if visible_children
                prop.score_for_value(value)
              else
                prop.max_score
              end
            end

            # set for field
            current_empty_doc[k] ||= field_score

            # sum values
            score_value = [score_value, field_score].compact.inject(&:+)
          end
        end

        document['meta'] ||= {}
        document['meta']['specific_max_score_hash'] = specific_max_score_document
        document['meta']['specific_max_score_total'] = score_value
        
        score_value
      end

      def set_scores!(document, is_create: false, condition_proc: nil, **kwargs)
        score_value = self.score_initial_value

        # iterate recursively through schemas
        score_document = each_form_with_document(
          document,
          skip_tree_when_hidden: true,
          is_create: is_create,
          **kwargs
        ) do |form, condition, skip_branch_proc, current_level, current_doc, current_empty_doc, document_path|

          # skip unactive trees
          skip_branch_proc.call if condition&.evaluate(current_doc, &condition_proc) == false

          # iterate properties and increment score_value if needed
          form[:properties].each do |k, prop|
            next unless prop.visible(is_create: is_create)
            next unless prop.respond_to?(:score_for_value)

            value = current_doc.dig(k)
            field_score = prop.score_for_value(value) if !value.nil?

            # set for field
            current_empty_doc[k] = field_score

            # update global score
            score_value = [score_value, field_score].compact.inject(&:+)
          end
        end

        document['meta'] ||= {}
        document['meta']['score_hash'] = score_document
        document['meta']['score_total'] = score_value

        score_value
      end

      def set_failures!(document, is_create: false, condition_proc: nil, **kwargs)
        total_failed = 0

        # iterate recursively through schemas
        failed_document = each_form_with_document(
          document,
          skip_tree_when_hidden: true,
          is_create: is_create,
          **kwargs
        ) do |form, condition, skip_branch_proc, current_level, current_doc, current_empty_doc, document_path|

          # skip unactive trees
          skip_branch_proc.call if condition&.evaluate(current_doc, &condition_proc) == false

          # iterate properties
          form[:properties].each do |k, prop|
            next unless prop.visible(is_create: is_create)
            next unless prop.respond_to?(:value_fails?)

            value = current_doc.dig(k)
            failed = !!prop.value_fails?(value)

            # set for field
            current_empty_doc[k] = failed

            # add global failed
            total_failed += 1 if failed
          end
        end

        document['meta'] ||= {}
        document['meta']['failed_hash'] = failed_document
        document['meta']['failed_total'] = total_failed

        total_failed
      end

      # Checks if the form has fields with scoring
      #
      # @return [Boolean]
      def scored?(**args)
        has_scoring = false
        each_form(**args) do |form|
          form.properties&.each do |key, field|
            if field.scored?
              has_scoring = true
              break 
            end
          end
        end
        has_scoring
      end

      # Initial value when scoring a document
      #
      # @return [Float, NilClass]
      def score_initial_value
        (self[:hasScoring] || self.scored?) ? 0.0 : nil
      end
    
      # Calculates the MAXIMUM ATTAINABLE score considering all possible branches
      # A block is REQUIRED to resolve whether a conditional field is visible or not
      #
      # @todo consider hideOnCreate
      # @todo support non repeatable JSF::Forms::Section
      #
      # @param [Boolean] skip_hidden
      # @param [Proc] &block
      # @return [Nil|Float]
      def max_score(skip_hidden: true, &block)
        self[:properties]&.inject(nil) do |acum, (name, field)|

          raise StandardError.new('JSF::Forms::Section field is not supported for max_score') if field.is_a?(JSF::Forms::Section)
          next acum if skip_hidden && field.hidden?
    
          # Field may have conditional fields so we go recursive trying all possible
          # values to calculate the max score
          field_score = if CONDITIONAL_FIELDS.include?(field.class) && field.has_dependent_conditions?

            # 1) Calculate a set of values that can affect own score
            # 2) Calculate a set of values that can trigger branches, affecting score
            score_relevant_values = case field
            when JSF::Forms::Field::Select
              field.response_set[:anyOf].map do |obj|
                obj[:const]
              end
            when JSF::Forms::Field::Switch
              [true, false]
            when JSF::Forms::Field::NumberInput
              # ToDo, this logic assumes only equal and not equal are supported

              (field.dependent_conditions || []).map do |condition|
                sub_condition = condition[:if][:properties].values[0]
                if sub_condition.key?(:not)
                  'BP8;x&/dTF2Qn[RG45>?234/>?#5dsgfhDFGH++?asdf.' #some very random text
                else
                  sub_condition[:const]
                end
              end
            else
              StandardError.new("conditional field #{field.class} is not yet supported for max_score")
            end
        
            # iterate posible values and take only the max_score
            score_relevant_values&.map do |value|

              # get the matching dependent conditions for a value and 
              # calculate MAX score for all of them
              value_dependent_conditions = field.dependent_conditions_for_value({"#{name}" => value}, &block)
              sub_schemas_max_score = value_dependent_conditions.inject(nil) do |acum_score, condition|
                [
                  acum_score,
                  condition[:then]&.max_score(&block)
                ].compact.inject(&:+)
              end

              field_score_for_value = field.respond_to?(:score_for_value) ? field.score_for_value(value) : nil
              [
                sub_schemas_max_score,
                field_score_for_value
              ].compact.inject(&:+)
            end&.compact&.max
          
          # Field has score but not conditional fields
          elsif SCORABLE_FIELDS.include? field.class
            field.max_score
          else
            nil
          end
    
          [ acum, field_score ].compact.inject(&:+)
        end
      end
    
      # Builds a new hash where the values of translatable fields are localized
      #
      # @param [Hash{String}, Document] document 
      # @param [Symbol] locale <description>
      #
      # @return [Hash{String}]
      def i18n_document(document, locale: DEFAULT_LOCALE, missing_locale_msg: 'Missing Translation')
        document.each_with_object({}) do |(key, value), hash|
            
          i18n_value = if JSF::Forms::Document::ROOT_KEYWORDS.include?(key)
            value
          else
            property = self.get_merged_property(key, ignore_sections: true)

            case property
            when JSF::Forms::Field::Checkbox
              value.map{ |v|
                property.i18n_value(v, locale) || missing_locale_msg
              }
            when JSF::Forms::Field::Select
              property.i18n_value(value, locale) || missing_locale_msg
            when JSF::Forms::Field::Slider
              property.i18n_value(value, locale) || missing_locale_msg
            when JSF::Forms::Field::Switch
              property.i18n_value(value, locale) || missing_locale_msg
            # parse date
            when JSF::Forms::Field::DateInput
              value.class == DateTime ? value : DateTime.parse(value)
            # go recursive on section
            when JSF::Forms::Section
              value&.map do |doc|
                property.form.i18n_document(doc, locale: locale, missing_locale_msg: missing_locale_msg)
              end
            # go recursive on component
            when JSF::Forms::Field::Component
              property
                .component_definition
                .i18n_document(value, locale: locale, missing_locale_msg: missing_locale_msg)
            else
              value
            end
          end

          hash[key] = i18n_value
        end
      end

      # Changes all important references to support a 'duplicate' feature. 
      #
      # @note
      # 
      # - 'const' key inside the response sets is NOT modified since it does not have to be unique,
      #    JSF::Forms::Condition(s) values are also not migrated for that reason
      # - does not migrate JSF::Forms::Field::Component, because the property key must not change
      #
      # @ToDo consider shared fields
      #
      # @return [JSF::Forms::Form] new instance with changed ids
      def dup_with_new_references(
        property_id_proc: ->(id){ id.slice(0...-6) + SecureRandom.uuid[0...6] },
        response_set_id_proc: ->(id){ SecureRandom.uuid }
      )
        migrated_response_sets = {}

        serialized_form = self.as_json
        dupped_form = self.class.new(serialized_form)

        dupped_form.each_form(ignore_definitions: false) do |form, condition, skip_branch_proc|

          migrated_props = {}
        
          # migrate properties
          prop_keys = form['properties'].keys
          prop_keys.each do |prop_key|
            prop = form['properties'][prop_key]
            next if prop.is_a?(JSF::Forms::Field::Static)
            next if prop.is_a?(JSF::Forms::Field::Component)

            new_key = migrated_props[prop_key] ||= property_id_proc.call(prop_key)      
            
            # remove the prop
            form['properties'].delete(prop_key)
            
            # migrate property
            prop['$id'] = "#/properties/#{new_key}"

            # set new prop
            form['properties'][new_key] = prop
        
            # migrate response sets
            if prop.respond_to?(:response_set_id)
              id = prop.response_set_id.sub('#/definitions/', '')
              new_id = migrated_response_sets[id] ||= response_set_id_proc.call(id)
              root_form = form.meta[:is_subschema] ? form.root_parent : form
        
              # only migrate once
              if root_form['definitions'].key?(id)
                resp_set = root_form['definitions'].delete(id)
                root_form['definitions'][new_id] = resp_set
              end
        
              prop.response_set_id = new_id
            end

          end

          # migrate conditions
          form[:allOf].each do |condition|
            prop_key = condition.condition_property_key
            new_key = migrated_props[prop_key] ||= property_id_proc.call(prop_key)
        
            # set property key
            cond_hash = condition.dig('if', 'properties')
            cond_hash[new_key] = cond_hash.delete(prop_key)

            # update required to match property key
            condition['if']['required'] = [new_key]
          end
        
          # migrate required
          form[:required].map!{|k| migrated_props[k] }
        end

        dupped_form
      end
    
      # Mutates the entire Form to a json schema compliant
      #
      # @return [void]
      def legalize!
        if !self.meta[:is_subschema]
          self.delete('schemaFormVersion')
          self.delete('availableLocales')
          self.delete('hasScoring')
        end
      end
    
      # Allows the definition of migrations to 'upgrade' schemas when the standard changes
      # The method is only the last migration script (not versioned)
      #
      # @return [void]
      def migrate!
        # add schemaFormVersion
        if !self.meta[:is_subschema]
          self[:schemaFormVersion] = VERSION
        end

        # add displayProperties.component to all properties
        self.properties.each do |key, prop|

          # migrate header to markdown
          if prop.dig(:displayProperties).key?('useHeader')
            prop.dig(:displayProperties)&.delete('useHeader')
            level = prop.dig(:displayProperties)&.delete('level')
            prop.dig(:displayProperties, :i18n, :label).transform_values! do |value|
              if value
                if level == 1
                  "# #{value}"
                else
                  "## #{value}"
                end
              end
            end
            SuperHash::Utils.bury(prop, :displayProperties, :kind, nil)
          end

          prop.dig(:displayProperties)&.delete('useInfo')
          prop.dig(:displayProperties)&.delete('icon')
          prop.dig(:displayProperties)&.delete('useSlider')
          prop.dig(:displayProperties)&.delete('isSelect')
          prop.delete('static')

          # add component to all properties
          component_name = COMPONENT_PROPERTY_CLASS_PROC.call(prop)
          SuperHash::Utils.bury(prop, :displayProperties, :component, component_name) if component_name

        end

      end
    
      private
    
      # redefined as private to favor append*, prepend* methods
      def add_property(*args, &block)
        super(*args, &block)
      end

      # Raises an error if form is NOT the root form
      #
      # @param [String] error_msg
      # @return [<Type>] <description>
      def raise_if_subschema(msg = 'method can only be called for root form')
        raise StandardError.new(msg) if meta[:is_subschema]
      end

      # Raises error if form is the root form
      #
      # @param [<Type>] msg <description>
      # @return [<Type>] <description>
      def raise_unless_subschema(msg = 'method cannot be called for root form')
        raise StandardError.new(msg) unless meta[:is_subschema]
      end
    
    end
  end
end