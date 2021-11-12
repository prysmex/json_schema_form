module JSF
  module Forms
    DEFAULT_LOCALE = 'es'.freeze
    AVAILABLE_LOCALES = ['es', 'en'].freeze
    VERSION = '3.0.0'.freeze
    
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
    
        case instance
        when JSF::Forms::Form
    
          case attribute
          when 'definitions'
            if value[:isResponseSet]
              return JSF::Forms::ResponseSet.new(value, init_options)
            elsif value[:type] == 'object' #replaced schemas
              return JSF::Forms::Form.new(value, init_options)
            elsif value.key?(:$ref) # shared definition
              return JSF::Forms::ComponentRef.new(value, init_options)
            end
          when 'allOf'
            return JSF::Forms::Condition.new(value, init_options)
          when 'properties'
            if value.key?(:$ref)
              if value.dig(:displayProperties, :isSelect)
                return JSF::Forms::Field::Select.new(value, init_options)
              else
                return ::JSF::Forms::Field::Component.new(value, init_options)
              end
            end
    
            klass = case value[:type]
              when 'string', :string
                if value[:format] == 'date-time'
                  JSF::Forms::Field::DateInput
                else
                  JSF::Forms::Field::TextInput
                end
              when 'number', :number, 'integer', :integer
                if value&.dig(:displayProperties, :useSlider)
                  JSF::Forms::Field::Slider
                else
                  JSF::Forms::Field::NumberInput
                end
              when 'boolean', :boolean
                JSF::Forms::Field::Switch
              when 'array', :array
                if value.dig(:items, :format) == 'uri'
                  JSF::Forms::Field::FileInput
                elsif value.dig(:displayProperties, :useSection)
                  JSF::Forms::Field::Section
                else
                  JSF::Forms::Field::Checkbox
                end
              when 'null', :null
                if value&.dig(:displayProperties, :useHeader)
                  JSF::Forms::Field::Header
                elsif value&.dig(:displayProperties, :useInfo)
                  JSF::Forms::Field::Info
                elsif value[:static]
                  JSF::Forms::Field::Static
                end
              end
      
            return klass.new(value, init_options) if klass
          end
          
        end
    
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
        is_inspection = passthru[:is_inspection]
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
            if is_inspection
              optional(:maxScore) { int? | float? | nil? }
            end
          else
            optional(:'$schema').filled(:string)
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

      # Checks locale vality for the following:
      #
      #   - JSF::Forms::Field::* (recursive)
      #     - JSF::Forms::ResponseSet
      #
      # @param locale [String,Symbol] locale
      # @return [Boolean] if valid
      def valid_for_locale?(locale = DEFAULT_LOCALE)
    
        # check properties and their response_sets
        prop = self.schema_form_iterator do |_, then_hash|
          invalid_property = then_hash&.properties&.any? do |k,v|
            if v.respond_to?(:response_set)
              !v.valid_for_locale?(locale) || !v.response_set&.valid_for_locale?(locale)
            else
              !v.valid_for_locale?(locale)
            end
          end
    
          break invalid_property if invalid_property
        end

        !prop
      end
    
      ##############
      ###METHODS####
      ##############
    
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
      def add_component_ref(db_id:)
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer
        
        component_ref = JSF::Forms::FormBuilder.example('component_ref') do |obj|
          obj['$ref'] = db_id
        end
        key = component_ref_key(db_id)
        self.add_definition(key, component_ref)
      end

      # Finds a JSF::Forms::ComponentRef from a db_id
      #
      # @param [Integer] db_id
      # @return [JSF::Forms::ComponentRef]
      def get_component_ref(db_id:)
        self['definitions'].find do |k,v|
          v.is_a?(JSF::Forms::ComponentRef) && v.db_id == db_id
        end&.last
      end

      # Removes a JSF::Forms::ComponentRef or JSF::Forms::Form from the 'definitions' key
      #
      # @param [Integer] db_id (DB id)
      # @return [JSF::Forms::Form] mutated self
      def remove_component_ref(db_id:)
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
      def add_component_pair(db_id:, index:, options: {})
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer
        key = component_ref_key(db_id)

        # add property
        component = JSF::Forms::FormBuilder.example('component') do |obj|
          obj['$ref'] = "#/definitions/#{key}"
        end
        case index
        when Integer
          insert_property_at_index(index, key, component, options)
        when :append
          append_property(key, component, options)
        when :prepend
          prepend_property(key, component, options)
        else
          raise ArgumentError.new("invalid index argument #{index}")
        end

        # add definition
        add_component_ref(db_id: db_id)
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
          v.is_a?(JSF::Forms::Field::Component) && v.db_id == db_id
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
        schema_form_iterator(**args) do |_, then_hash|
          properties.merge!(then_hash&.properties || {})
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
        schema_form_iterator(**args) do |_, then_hash|
          props = then_hash&.properties
          break props[property] if props&.key?(property)
        end
      end
    
      # Adds a property with a sort value of 0 and resorts all other properties
      #
      # @see insert_property_at_index for arguments
      #
      # @return [JSF::Forms::Field::*] added property
      def prepend_property(*args)
        insert_property_at_index(self.min_sort || 0, *args)
      end
    
      # Adds a property with a sort value 1 more than the max and resorts all other properties
      #
      # @see insert_property_at_index for arguments
      #
      # @return [JSF::Forms::Field::*] added property
      def append_property(*args)
        max_sort = self.max_sort
        index = max_sort.nil? ? 0 : max_sort + 1
        insert_property_at_index(index, *args)
      end
    
      # Adds a property with a specified sort value and resorts all other properties
      #
      # @param id [String,Symbol] name of the property
      # @param definition [Hash] the schema to add
      # @param options[:required] [Boolean] if the property should be required
      # @return [JSF::Forms::Field::*] added property
      def insert_property_at_index(index, id, definition, options={})
        prop = add_property(id, definition, options)
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
            properties: {
              :"#{dependent_on}" => SuperHash::Utils.bury({}, *CONDITION_TYPE_TO_PATH.call(type), value)
            }
          },
          then: {
            properties: {}
          }
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
      def insert_conditional_property_at_index(sort_value, property_id, definition, dependent_on:, type:, value:, **options)
        unless sort_value.is_a?(Integer) || [:prepend, :append].include?(sort_value)
          raise ArgumentError.new("sort must be an Integer, :prepend or :append, got #{sort_value}")
        end
    
        condition = get_condition(dependent_on, type, value) || add_condition(dependent_on, type, value)
        added_property = case sort_value
        when :prepend
          condition[:then].prepend_property(property_id, definition, options)
        when :append
          condition[:then].append_property(property_id, definition, options)
        else
          condition[:then].insert_property_at_index(sort_value, property_id, definition, options)
        end
        yield(condition[:then], added_property) if block_given?
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

      # Same as subschema_iterator, but includes the current JSF::Forms::Form
      #
      # @todo yield condition and parent if not root form
      #
      # @param start_level [Integer] Depth of allOf nesting to ignore (0 includes current)
      # @param levels [Integer] Max depth of allOf nesting to starting from start_level
      #
      # @yieldparam [NilClass] condition
      # @yieldparam [JSF::Forms::Form] form
      # @yieldparam [NilClass] parent form
      # @yieldparam [Integer] current_level
      #
      # @return [NilClass]
      def schema_form_iterator(start_level: 0, levels: nil, **args, &block)
        return if levels == 0

        yield( nil, self, nil, 0 ) if start_level == 0

        subschema_iterator(current_level: 1, levels: levels, start_level: start_level, **args, &block)
      end
    
      # Iterates and yields each JSF::Form along with its condition.
      # If 'skip_when_false' is true and the returned value from the yield equals false,
      # then the iteration of that tree is halted
      #
      # @todo consider else key in allOf
      #
      # @param start_level [Integer] Depth of allOf nesting to ignore (0 includes current)
      # @param levels [Integer] Max depth of allOf nesting to starting from start_level
      # @param skip_when_false [Boolean]
      #
      # @yieldparam [JSF::Schema] condition
      # @yieldparam [JSF::Forms::Form] form
      # @yieldparam [JSF::Forms::Form] parent form
      # @yieldparam [Integer] current_level
      #
      # @return [NilClass]
      def subschema_iterator(start_level: 0, levels: nil, skip_when_false: false, current_level: 0, &block)
        
        # stop execution if levels limit matches
        return if !levels.nil? && current_level >= (start_level + levels)

        self[:allOf]&.each do |condition_subschema|

          # skip all subschemas until first match on start_level
          if start_level.nil? || current_level >= start_level
            returned_value = yield(
              condition_subschema[:if],
              condition_subschema[:then],
              self,
              current_level
            )

            # allow skipping tree execution
            next if skip_when_false && (returned_value == false)
          end

          # go to next level recursively
          condition_subschema[:then]&.subschema_iterator(
            start_level: start_level,
            levels: levels,
            skip_when_false: skip_when_false,
            current_level: current_level + 1,
            &block
          )
        end

        nil
      end
    
      # Calculates the MAXIMUM ATTAINABLE score considering all possible branches
      # A block is REQUIRED to resolve whether a conditional field is visible or not
      #
      # @todo consider hideOnCreate
      #
      # @param [Boolean] skip_hidden
      # @param [Proc] &bloclk
      # @return [Nil|Float]
      def max_score(skip_hidden: true, &block)
        self[:properties]&.inject(nil) do |acum, (name, field)|
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
    
      # Builds a new localized hash based on the Form's fields responses
      #
      # @param [Hash{String}, Document] document 
      # @param [Boolean] is_inspection <description>
      # @param [Symbol] locale <description>
      #
      # @return [Hash{String}]
      def i18n_document(document, is_inspection: false, locale: DEFAULT_LOCALE)
        merged_properties = self.merged_properties #precalculate for performance
    
        raise StandardError.new('schema not found') if merged_properties.nil?
        document.each_with_object({}) do|(name, v), hash|
          name = name.to_s
          if v.nil? || is_inspection && JSF::Forms::Document::ROOT_KEYWORDS.include?(name)
            hash[name] = v
          else
            value = self.i18n_document_value(
              name,
              v,
              locale: locale,
              property: merged_properties[name],
            )
            hash[name] = value.nil? ? 'Missing Translation' : value
          end
        end
      end
    
      def i18n_document_value(attr_name, value, is_inspection: false, locale: DEFAULT_LOCALE, property: nil)
        return if value.nil?
        
        #for performance, allow passing the property
        property ||= get_merged_property(attr_name)
        return unless property.present?
    
        case property
        when JSF::Forms::Field::Checkbox
          value.map{|v| property.i18n_value(v, locale) }
        when JSF::Forms::Field::Slider
          property.dig(:displayProperties, :i18n, :enum, locale, value.to_i.to_s)
        when JSF::Forms::Field::Select
          property.i18n_value(value, locale)
        when JSF::Forms::Field::DateInput
          value.class == DateTime ? value : DateTime.parse(value) 
        when JSF::Forms::Field::Switch
          label = value ? :trueLabel : :falseLabel
          property.dig(:displayProperties, :i18n, label, locale)
        when JSF::Forms::Field::Component
          property
            .component_definition
            .i18n_document(value, locale: locale, is_inspection: is_inspection)
        else
          value
        end
      end

      # Builds a document with a key for each property on the schema form.
      # It yields a condition and a value that can be validated with a json-schema compliant
      # validator.
      # 
      # If the validator returns false and you pass {skip_when_false: true}, it will build
      # a document with only 'visible properties'
      #
      # @param [Hash{String}], document
      # @return [Hash{String}]
      def nil_document(document, **args, &block)
        #root
        obj = self[:properties].transform_values{|v| nil}
    
        #subschemas
        subschema_iterator(**args) do |if_hash, then_hash, parent_schema, current_level|
          key = if_hash[:properties].keys.first
          value = yield( if_hash, {"#{key}" => document[key]}, parent_schema.dig(:properties, key) )
    
          obj.merge!( then_hash[:properties].transform_values{|v| nil} ) if value
    
          value
        end
    
        obj
      end
    
      # Mutates the entire Form to a json schema compliant
      #
      # @ return [JSF::Forms::Form] a mutated Form
      def compile!
        self.response_sets.each do |_, response_set|
          response_set.compile! if response_set&.respond_to?(:compile!)
        end

        self.component_definitions do |_, comp_def|
          comp_def.compile! if definition&.respond_to?(:compile!)
        end

        self.schema_form_iterator do |_, then_hash|
          then_hash[:properties]&.each do |id, definition|
            definition.compile! if definition&.respond_to?(:compile!)
          end
        end

        self
      end
    
      # Allows the definition of migrations to 'upgrade' schemas when the standard changes
      # The method is only the last migration script (not versioned)
      #
      # @return [Form] a mutated instance of the Form
      def migrate!(options={})
    
        # migrate properties
        self.schema_form_iterator do |_, then_hash|
          then_hash[:properties]&.each do |id, definition|
            if definition&.respond_to?(:migrate!)
              puts 'migrating ' + definition.class.to_s.demodulize
              definition.migrate!
            end
          end
        end
    
        # migrate response sets
        self[:definitions]&.each do |id, definition|
          if definition&.respond_to?(:migrate!)
            puts 'migrating response set'
            definition.migrate!
          end
        end
    
        self
      end
    
      private
    
      # redefined as private to favor append*, prepend* methods
      def add_property(*args)
        super(*args)
      end
    
    end
  end
end