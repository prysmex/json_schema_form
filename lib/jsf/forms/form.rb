# frozen_string_literal: true

module JSF
  module Forms
    DEFAULT_LOCALE = 'en'.freeze
    AVAILABLE_LOCALES = %w[es en].freeze
    VERSION = '3.4.0'.freeze
    SCHEMA_VERSION = 'https://json-schema.org/draft/2020-12/schema'.freeze

    # A `Form` is a 'object' schema that is used to validate a `JSF::Forms::Document`.
    #
    # @todo add more description
    #
    # It follows the following recursive structure:
    #
    # - $defs (only in top level)
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
      include JSF::Validations::DrySchemaValidatable
      include JSF::Core::Buildable
      include JSF::Core::Type::Objectable
      include JSF::Forms::Concerns::DisplayProperties

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

      COMPONENT_PROPERTY_CLASS_PROC = proc do |value|
        is_string = value.is_a?(::String)

        hash = {
          # fields
          'checkbox' => JSF::Forms::Field::Checkbox,
          'shared' => JSF::Forms::Field::Shared,
          'date_input' => JSF::Forms::Field::DateInput,
          'file_input' => JSF::Forms::Field::FileInput,
          'geopoints' => JSF::Forms::Field::GeoPoints,
          'markdown' => JSF::Forms::Field::Markdown,
          'number_input' => JSF::Forms::Field::NumberInput,
          'select' => JSF::Forms::Field::Select,
          'signature' => JSF::Forms::Field::Signature,
          'slider' => JSF::Forms::Field::Slider,
          'static' => JSF::Forms::Field::Static,
          'switch' => JSF::Forms::Field::Switch,
          'text_input' => JSF::Forms::Field::TextInput,
          'time_input' => JSF::Forms::Field::TimeInput,
          'video' => JSF::Forms::Field::Video,
          'slideshow' => JSF::Forms::Field::Slideshow,
          'section' => JSF::Forms::Section
        }

        if is_string
          hash[value]
        else
          hash.find { |_component, klass| klass == value || value.is_a?(klass) }&.first
        end
      end

      # converts and Integer into a string that can be used for
      # JSF::Forms::SharedRef and JSF::Forms::Form inside '$defs'
      #
      # @return [String]
      def self.shared_ref_key
        "shared_#{SecureRandom.uuid[0...6]}"
      end

      # Defined in a Proc so it can be reused:
      ATTRIBUTE_TRANSFORM = ->(attribute, value, instance, init_options) {
        klass = case instance
        when JSF::Forms::Form

          case attribute
          when '$defs'
            if value[:isResponseSet]
              JSF::Forms::ResponseSet
            elsif value[:type] == 'object' # replaced schemas
              JSF::Forms::Form
            elsif value.key?(:$ref) # shared definition
              JSF::Forms::SharedRef
            end
          when 'allOf'
            JSF::Forms::Condition
          when 'properties'
            component = value.dig(:displayProperties, :component)
            COMPONENT_PROPERTY_CLASS_PROC.call(component)
          end

        end

        # return if a condition is met, otherwise let error be raised
        return klass.new(value, init_options) if klass

        raise StandardError.new("Transform conditions not met: (attribute: #{attribute}, value: #{value}, meta: #{instance.meta}), #{instance.class}")
      }

      # Utility proc to DRY code, expands a condition type to a path
      #
      # @param [Symbol] type
      # @return [Array]
      CONDITION_TYPE_TO_PATH = ->(type) {
        case type.to_sym
        when :const
          [:const]
        when :not_const
          %i[not const]
        when :enum
          [:enum]
        when :not_enum
          %i[not enum]
        else
          raise ArgumentError.new("#{type} is not a whitelisted condition type")
        end
      }

      update_attribute '$defs', default: ->(_data) { meta[:is_subschema] ? nil : {}.freeze }
      update_attribute 'properties', default: ->(_data) { {}.freeze }
      update_attribute 'required', default: ->(_data) { [].freeze }
      update_attribute 'allOf', default: ->(_data) { [].freeze }
      update_attribute 'type', default: ->(_data) { 'object' }
      update_attribute 'schemaFormVersion', default: ->(_data) { meta[:is_subschema] ? nil : VERSION }
      update_attribute '$schema', default: ->(_data) { meta[:is_subschema] ? nil : SCHEMA_VERSION }
      attribute? 'availableLocales', default: ->(_data) { meta[:is_subschema] ? nil : [].freeze }

      def initialize(obj = {}, options = {})
        options = {
          attributes_transform_proc: ATTRIBUTE_TRANSFORM
        }.merge(options)

        super
      end

      ###############
      # VALIDATIONS #
      ###############

      # Validation schema used for building own errors hash
      #
      # @param passthru [Hash{Symbol => *}] Options passed
      # @return [Dry::Schema::JSON] Schema
      def dry_schema(passthru)
        is_subschema = meta[:is_subschema]
        scoring = run_validation?(passthru, :scoring, optional: true)
        exam = run_validation?(passthru, :exam, optional: true)

        cache_key = "#{is_subschema}#{scoring}#{exam}"

        # TODO: this could later be implemented for all schema classes by centralizing it
        # dry_schema_config
        instance = self
        if (dry_schema_config = passthru[:dry_schema_config])
          id = dry_schema_config[:id]
          raise StandardError.new('id is required when using dry_schema_config') unless id

          cache_key += id
        end

        dry_schema_config_proc = dry_schema_config&.[](:proc)

        self.class.cache(cache_key) do
          Dry::Schema.JSON do
            config.validate_keys = true

            before(:key_validator) do |result| # result.to_h (shallow dup)
              JSF::Validations::DrySchemaValidated::WITHOUT_SUBSCHEMAS_PROC.call(result.to_h)
            end

            # support customizing with proc
            instance_exec(:root, instance, &dry_schema_config_proc) if dry_schema_config_proc

            required(:allOf).array(:hash)
            required(:properties).value(:hash)
            required(:required).value(:array?).array(:str?)
            required(:type).value(eql?: 'object')

            if !is_subschema
              required(:$schema).value(eql?: SCHEMA_VERSION)
              required(:availableLocales).value(:array?).array(:str?)
              required(:$defs).value(:hash)
              required(:schemaFormVersion).value(eql?: VERSION)
              optional(:title).maybe(:string) # TODO: deprecate?
              if exam
                required(:$id).filled { str? & format?(/^((?!#).)*$/) } # does not contain '#'
                required(:displayProperties).hash do
                  # support customizing with proc
                  instance_exec(:displayProperties, instance, &dry_schema_config_proc) if dry_schema_config_proc

                  required(:component).value(eql?: 'exam')
                  required(:passingGrade).filled(:integer, gt?: 0, lteq?: 100)
                  required(:gradeWeight).filled(:integer, gt?: 0, lteq?: 100)
                  optional(:maxTakes).filled(:integer, gt?: 0)
                  # optional(:hidden).filled(:bool)
                  required(:sort).filled(:integer)
                  required(:i18n).hash do
                    required(:label).hash do
                      AVAILABLE_LOCALES.each do |locale|
                        optional(locale.to_sym).maybe(:string)
                      end
                    end
                  end
                end
              elsif scoring
                optional(:hasScoring) { bool? }
                optional(:disableScoring) { bool? }
                optional(:displayProperties).hash do
                  # support customizing with proc
                  instance_exec(:displayProperties, instance, &dry_schema_config_proc) if dry_schema_config_proc
                  optional(:suggestedReportSchemaTemplates).array { str? & format?(/\d+/) }
                end
              else
                optional(:displayProperties).hash do
                  # support customizing with proc
                  instance_exec(:displayProperties, instance, &dry_schema_config_proc) if dry_schema_config_proc
                end
                optional(:$id).filled(:string)
              end
            else
              # optional(:$schema).filled(:string)
            end
          end
        end
      end

      # Build instance's erros hash from the dry_schema. It also validates
      # the following:
      #
      # - ensure referenced shared properties exist
      # - ensure property $id key matches with field id
      # - ensure referenced response sets exist
      # - ensure JSF::Forms::Field::Shared only exist in root form
      # - ensure shareds have a pair in '$defs'
      # - ensure only allowed fields contain (conditional) fields
      #
      # @param passthru [Hash{Symbol => *}] Options passed
      # @return [Hash{Symbol => *}] Errors
      def errors(**passthru)
        errors_hash = super

        if run_validation?(passthru, :subschema_properties) &&
           meta[:is_subschema] &&
           properties.none? { |_k, v| v.visible(is_create: false) }
          add_error_on_path(
            errors_hash,
            'properties',
            'at least 1 property must exist'
          )
        end

        # validate sorting
        if run_validation?(passthru, :sorting)
          unless verify_sort_order
            add_error_on_path(
              errors_hash,
              'base',
              "incorrect sorting, should start with 0 and increase consistently"
            )
          end
        end

        self[:$defs]&.each do |k, v|
          # ensure referenced shared properties exist
          if run_validation?(passthru, :shared_presence)
            if v.is_a?(JSF::Forms::SharedRef) && v.shared.nil?
              add_error_on_path(
                errors_hash,
                'base',
                "missing shared field for shared reference (#{k})"
              )
            end
          end
        end

        self[:properties]&.each do |k, field|
          # ensure property $id key matches with field id
          if run_validation?(passthru, :match_key)
            if field['$id'] && field['$id'] != "#/properties/#{k}"
              add_error_on_path(
                errors_hash,
                ['properties', k, '$id'],
                "'#{field['$id']}' did not match property key '#{k}'"
              )
            end
          end

          # ensure referenced response sets exist
          if run_validation?(passthru, :response_set_presence)
            if field.respond_to?(:response_set) && field.response_set_id && field.response_set.nil?
              add_error_on_path(
                errors_hash,
                (['properties', k] + field.class::RESPONSE_SET_PATH),
                "response set #{field.response_set_id} not found"
              )
            end
          end

          # ensure JSF::Forms::Field::Shared only exist in root form
          if run_validation?(passthru, :shared_in_root)
            if meta[:is_subschema] && field.is_a?(JSF::Forms::Field::Shared)
              add_error_on_path(
                errors_hash,
                'base',
                "shareds can only exist in root schema (#{k})"
              )
            end
          end

          # ensure shareds have a pair in '$defs'
          if run_validation?(passthru, :shared_ref_presence)
            if field.is_a?(JSF::Forms::Field::Shared)
              # response should be found
              if field.shared_def.nil?
                add_error_on_path(
                  errors_hash,
                  'base',
                  "missing shared reference for field #{field.shared_def_pointer}"
                )
              end
            end
          end

          # ensure only allowed fields contain (conditional) fields
          if CONDITIONAL_FIELDS.include?(field.class)
          else
            if run_validation?(passthru, :conditional_fields)
              if field.dependent_conditions.size > 0
                fields = CONDITIONAL_FIELDS.map { |klass| klass.name.split('::').last }.join(', ')
                add_error_on_path(
                  errors_hash,
                  'base',
                  "only the following fields can have conditionals (#{fields})"
                )
              end
            end
          end
        end

        errors_hash
      end

      # Checks that all properties are valid for locale, if field
      # respond to 'response_set', also check that response set is
      # valid for locale
      #
      # If no properties are present, returns false unless subschema
      #
      # @param locale [String,Symbol] locale
      # @return [Boolean]
      def valid_for_locale?(locale = DEFAULT_LOCALE, ignore_defs: false, no_props_validity: meta[:is_subschema])
        return false if dig('displayProperties', 'component') == 'exam' && i18n_label(locale).to_s.empty?

        any_property = false

        # check properties and their response_sets
        each_form(ignore_sections: true, ignore_defs:) do |form|
          return false if form.properties.any? do |k, v|
            next unless v.visible(is_create: false)

            any_property = true

            is_invalid = if v.respond_to?(:response_set)
              !v.valid_for_locale?(locale) || !v.response_set&.valid_for_locale?(locale)
            else
              !v.valid_for_locale?(locale)
            end

            yield k, v if block_given? && is_invalid

            is_invalid
          end
        end

        any_property ? true : no_props_validity
      end

      ###########
      # METHODS #
      ###########

      def example(*, &)
        JSF::Forms::FormBuilder.example(*, &)
      end

      ########################
      # COMPONENT MANAGEMENT #
      ########################

      # Util
      #
      # @see .shared_ref_key
      def shared_ref_key
        self.class.shared_ref_key
      end

      # Gets all shared $defs, which may be only the reference
      # or the replaced form
      #
      # @return [Hash{String => JSF::Forms::Form, JSF::Forms::SharedRef}]
      def shared_defs
        self[:$defs].select do |_k, v|
          v.is_a?(JSF::Forms::SharedRef) || v.is_a?(JSF::Forms::Form)
        end
      end

      # Adds a JSF::Forms::SharedRef to the '$defs' key
      #
      # @param [Integer] db_id (DB id)
      # @return [JSF::Forms::SharedRef]
      def add_shared_def(db_id:, definition: nil)
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer

        definition ||= JSF::Forms::FormBuilder.example('shared_ref')
        definition = add_def(shared_ref_key, definition)
        definition.db_id = db_id if definition.is_a?(JSF::Forms::SharedRef)
        definition
      end

      # Finds a JSF::Forms::SharedRef from a db_id
      #
      # @param [Integer] db_id
      # @return [NilClass, JSF::Forms::SharedRef, JSF::Forms::Form]
      def get_shared_def(db_id:)
        self['$defs'].find do |_k, v|
          v.respond_to?(:db_id) && v.db_id == db_id
        end&.last
      end

      # Removes a JSF::Forms::SharedRef or JSF::Forms::Form from the '$defs' key
      #
      # @param [Integer] db_id (DB id)
      # @return [NilClass, JSF::Forms::Form] mutated self
      def remove_shared_def(db_id:)
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer

        key = get_shared_def(db_id:)&.key_name
        remove_def(key) if key
      end

      # Adds a shared. If index is passed, it will also add a JSF::Forms::Field::Shared
      # on the properties key
      #
      # @param [Integer] db_id (DB id)
      # @param [Integer] index
      # @return [JSF::Forms::SharedRef]
      def add_shared_pair(db_id:, index:, key: shared_ref_key, definition: nil, options: {}, &)
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer

        # add definition
        def_obj = get_shared_def(db_id:) || add_shared_def(db_id:, definition:)

        # add property
        shared = JSF::Forms::FormBuilder.example('shared')
        prop = case index
        when Integer
          insert_property_at_index(index, key, shared, options, &)
        when :append
          append_property(key, shared, options, &)
        when :prepend
          prepend_property(key, shared, options, &)
        else
          raise ArgumentError.new("invalid index argument #{index}")
        end

        prop.shared_def_pointer = def_obj.key_name

        def_obj
      end

      # Removes a shared ref.
      #
      # @param [Integer] db_id (DB id)
      # @return [JSF::Forms::Form] mutated self
      def remove_shared_pair(db_id:)
        raise TypeError.new("db_id must be integer, got: #{db_id}, #{db_id.class}") unless db_id.is_a? Integer

        # remove property
        self[:properties].reject! do |_k, v|
          v.is_a?(JSF::Forms::Field::Shared) && v.db_id == db_id
        end
        resort!

        # remove definition
        remove_shared_def(db_id:)
      end

      ###########################
      # RESPONSE SET MANAGEMENT #
      ###########################

      # get responseSets
      #
      # @return [Hash{String => JSF::Forms::ResponseSet}]
      def response_sets
        self[:$defs].select do |_k, v|
          v[:isResponseSet]
        end
      end

      # Adds a new response_set
      #
      # @param [String] id
      # @param [Hash] definition
      # @return [JSF::Forms::ResponseSet]
      def add_response_set(id, definition)
        add_def(id, definition)
      end

      #######################
      # PROPERTY MANAGEMENT #
      #######################

      # get properties
      #
      # @return [Hash{String => JSF::Forms::Field::*}]
      def properties
        self[:properties]
      end

      # TODO: deprecate, use reduce_each_form
      #
      # get own and dynamic properties
      #
      # @return [Hash{String => JSF::Forms::Field::*}]
      def merged_properties(**args)
        reduce_each_form({}, **args) do |acum, form|
          acum.merge!(form&.properties || {})
        end
      end

      # similar to Array.reduce
      #
      def reduce_each_form(init_value, **args)
        each_form(**args) do |form|
          init_value = yield(init_value, form)
        end
        init_value
      end

      # gets the property definition inside the properties key
      #
      # @param [String, Symbol]
      # @return [JSF::Forms::Field::*]
      def get_property(property)
        dig(:properties, property)
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
      def prepend_property(*, &)
        insert_property_at_index(min_sort || 0, *, &)
      end

      # Adds a property with a sort value 1 more than the max and resorts all other properties
      #
      # @see insert_property_at_index for arguments
      #
      # @return [JSF::Forms::Field::*] added property
      def append_property(*, &)
        max_sort = self.max_sort
        index = max_sort.nil? ? 0 : max_sort + 1
        insert_property_at_index(index, *, &)
      end

      # Adds a property with a specified sort value and resorts all other properties
      #
      # @param id [String,Symbol] name of the property
      # @param definition [Hash] the schema to add
      # @param options[:required] [Boolean] if the property should be required
      # @return [JSF::Forms::Field::*] added property
      def insert_property_at_index(index, id, definition, options = {}, &)
        prop = add_property(id, definition, options, &)
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
        property = self[:properties]&.find { |_k, v| v.key_name == id.to_s }&.last
        return unless property

        current = property.sort
        range = Range.new(*[current, target].sort)
        selected = sorted_properties.select { |prop| range.include?(prop.sort) }
        if target > current
          selected.each { |prop| prop.sort -= 1 }
        else
          selected.each { |prop| prop.sort += 1 }
        end
        property.sort = target
        resort!
      end

      # gets the minimum sort value for all properties
      #
      # @return [Integer]
      def min_sort
        self[:properties]&.map { |_k, v| v&.sort }&.min
      end

      # gets the maximum sort value for all properties
      #
      # @return [Integer]
      def max_sort
        self[:properties]&.map { |_k, v| v&.sort }&.max
      end

      # gets a property by a sort value
      #
      # @return [JSF::Forms::Field]
      def get_property_by_sort(i)
        self[:properties]&.find { |_k, v| v&.sort == i }&.last
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
        self[:properties]&.values&.sort_by { |v| v&.sort } || []
      end

      # fixes sorting in case sort values are not consecutive.
      #
      # @return [void]
      def resort!
        sorted = sorted_properties
        for i in 0...self[:properties].size
          property = sorted[i]
          property.sort = i
        end
      end

      # Retrieves a condition
      #
      # @param dependent_on [Symbol] name of property the condition depends on
      # @param type [Symbol] type of condition to filter by
      # @param value [*] Value that makes the condition TRUE
      # @return [Array<JSF::Schema>, NilClass]
      def get_conditions(dependent_on, type, value = nil)
        cond_path = CONDITION_TYPE_TO_PATH.call(type)

        self[:allOf]&.select do |condition|
          prop_schema = condition.dig(:if, :properties, dependent_on)
          next unless prop_schema

          condition_value = prop_schema.dig(*cond_path)

          if %i[enum not_enum].include?(type.to_sym)
            condition_value&.include?(value)
          else
            condition_value == value
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
        raise ArgumentError.new('dependent property not found') if get_property(dependent_on).nil?

        # ensure transform is triggered
        self[:allOf] = (self[:allOf] || []) << {
          if: {
            required: [dependent_on.to_s],
            properties: {
              "#{dependent_on}": SuperHash::Utils.bury({}, *CONDITION_TYPE_TO_PATH.call(type), value)
            }
          },
          then: {}
        }
        self[:allOf].last
      end

      def find_or_add_condition(dependent_on, type, value, &)
        condition = get_conditions(dependent_on, type, value)&.first || add_condition(dependent_on, type, value)
        condition[:then].instance_eval(&) if block_given?
        condition
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
      def insert_conditional_property_at_index(sort_value, property_id, definition, dependent_on:, type:, value:, **options, &)
        unless sort_value.is_a?(Integer) || %i[prepend append].include?(sort_value)
          raise ArgumentError.new("sort must be an Integer, :prepend or :append, got #{sort_value}")
        end

        condition = find_or_add_condition(dependent_on, type, value)
        subform = condition[:then]

        case sort_value
        when :prepend
          subform.prepend_property(property_id, definition, options, &)
        when :append
          subform.append_property(property_id, definition, options, &)
        else
          subform.insert_property_at_index(sort_value, property_id, definition, options, &)
        end
      end

      # Appends a dependent property inside a subschema
      #
      # @return [JSF::Forms::Field::*]
      def append_conditional_property(...)
        insert_conditional_property_at_index(:append, ...)
      end

      # Prepends a dependent property inside a subschema
      #
      # @return [JSF::Forms::Field::*]
      def prepend_conditional_property(...)
        insert_conditional_property_at_index(:prepend, ...)
      end

      #############
      # Utilities #
      #############

      # If returns true if inside the root key '$defs'
      #
      # @return [Boolean]
      def is_shared_def?
        meta[:path].first == '$defs'
      end

      # @return [JSF::Forms::Form]
      def validation_schema!(ignore_defs: false, **)
        # remove not visible fields from required
        each_form(ignore_defs:) do |form|
          form[:required]&.select! do |name|
            form[:properties][name].visible(**)
          end
        end

        # legalize, schema
        send_recursive(:legalize!)

        self
      end

      # Util that recursively iterates and yields each JSF::Forms::Form along with other relevant
      # params.
      #
      # @param ignore_all_of [Boolean] if true, does not iterate into forms inside a allOf
      # @param ignore_defs [Boolean]
      # @param ignore_sections [Boolean] if true, does not iterate into forms inside a JSF::Forms::Section
      # @param is_create [Boolean] pass true to consider 'hideOnCreate' display property
      # @param levels [Integer] Max depth of allOf nesting to starting from start_level
      # @param skip_tree_when_hidden [Boolean] forces skiping trees when hidden
      # @param start_level [Integer] Depth of allOf nesting to ignore (0 includes current)
      #
      # @yieldparam [JSF::Forms::Form] form, the current form
      # @yieldparam [JSF::Forms::Condition] condition, condition the form depends on
      # @yieldparam [Integer] nested level, 0 for root form
      #
      # @return [void]
      def each_form(
          current_level: 0,
          ignore_all_of: false,
          ignore_defs: true,
          ignore_sections: false,
          is_create: false,
          levels: nil,
          skip_tree_when_hidden: false,
          start_level: 0,
          &
        )
          # stop execution if levels limit matches
          return if !levels.nil? && current_level >= (start_level + levels)

          # create kwargs hash to dry code when calling recursive
          kwargs = {}
          kwargs[:ignore_sections] = ignore_sections
          kwargs[:ignore_defs] = ignore_defs
          kwargs[:ignore_all_of] = ignore_all_of
          kwargs[:is_create] = is_create
          kwargs[:levels] = levels
          kwargs[:skip_tree_when_hidden] = skip_tree_when_hidden
          kwargs[:start_level] = start_level

          # yield only if reached start_level or start_level is nil
          if start_level.nil? || current_level >= start_level
            condition = meta[:parent] if meta[:parent].is_a?(JSF::Forms::Condition)
            skip_branch = catch(:skip_branch) do
              yield(self, condition, current_level)
              false
            end
            return if skip_branch
          end

          # iterate properties and call recursive on JSF::Forms::Section
          unless ignore_sections
            properties&.each_value do |prop|
              next unless prop.is_a?(JSF::Forms::Section)

              next if skip_tree_when_hidden && !prop.visible(is_create:)

              prop[:items]&.each_form(
                current_level: current_level + 1,
                **kwargs,
                &
              )
            end
          end

          # iterate $defs and call recursive on JSF::Forms::Form
          unless ignore_defs
            self[:$defs]&.each_value do |prop|
              next unless prop.is_a?(JSF::Forms::Form)

              prop&.each_form(
                current_level: current_level + 1,
                **kwargs,
                &
              )
            end
          end

          # iterate allOf
          return if ignore_all_of

          self[:allOf]&.each do |cond|
            prop = cond.condition_property

            next if skip_tree_when_hidden && !prop.visible(is_create:)

            # go to next level recursively
            cond[:then]&.each_form(
              current_level: current_level + 1,
              **kwargs,
              &
            )
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
      # @yieldparam [JSF::Forms::Form] form
      # @yieldparam [JSF::Forms::Condition] condition
      # @yieldparam [Hash] document, the current document for the yielded JSF::Forms::Form
      # @yieldparam [Hash] empty_document
      # @yieldparam [Array<String,Integer>] document_path
      #
      # @return [void]
      def each_form_with_document(document, section_or_shared: nil, document_path: [], skip_on_condition: false, condition_proc: nil, **kwargs, &)
        empty_document = {}

        # since JSF::Forms::Field::Shared and JSF::Forms::Section are already
        # handled, we ignore them in the each_form iterator
        each_form(ignore_sections: true, ignore_defs: true, **kwargs) do |form, condition, *args|
          # skip unactive trees
          throw(:skip_branch, true) if skip_on_condition && condition&.evaluate(document, &condition_proc) == false

          yield(
            form,
            condition,
            *args,
            document,
            empty_document,
            document_path,
            section_or_shared
          )

          # handle all properties that have a value in which the document_path is modified (sections, shared)
          form[:properties].each do |key, property|
            next if kwargs[:skip_tree_when_hidden] && !property.visible(is_create: kwargs[:is_create])

            # go recursive
            if !kwargs[:ignore_sections] && property.is_a?(JSF::Forms::Section)
              if !property.repeatable?
                document[key] ||= []
                document[key].push({}) if document[key].empty?
              end
              empty_document[key] ||= []
              document[key]&.map&.with_index do |doc, i|
                empty_document[key][i] = property
                  .form
                  .each_form_with_document(
                    doc,
                    document_path: document_path + [key, i],
                    skip_on_condition:,
                    section_or_shared: property,
                    condition_proc:,
                    **kwargs,
                    &
                  )
              end
            elsif !kwargs[:ignore_defs] && property.is_a?(JSF::Forms::Field::Shared)
              value = document[key] || {}
              empty_document[key] = property
                .shared_def
                .each_form_with_document(
                  value,
                  document_path: (document_path + [key]),
                  skip_on_condition:,
                  section_or_shared: property,
                  condition_proc:,
                  **kwargs,
                  &
                )
            end
          end
        end

        empty_document
      end

      # @return void
      def each_sorted_property(**)
        is_create = false

        all_sorted_properties = []
        offsets = {}
        find_index = ->(prop) { all_sorted_properties.size - all_sorted_properties.reverse.find_index { |a| a[0] == prop } - 1 }

        each_form(
          skip_tree_when_hidden: true,
          ignore_defs: false,
          is_create:,
          **
        ) do |form, condition, _current_level|
          current_arrays = form.sorted_properties.each_with_object([]) do |property, array|
            next unless property.visible(is_create:)

            value = [property]
            array.push(value)
          end

          key_names = current_arrays.map { |a| a[0].key_name }

          index = nil
          if condition
            offset_key = condition.condition_property_key
            offset = (offsets[offset_key] ||= [])
            index = find_index.call(condition.condition_property) + offset.size + 1
            offsets[offset_key] += key_names
          elsif (parent = form.meta[:parent])
            section_or_shared = if parent.class == JSF::Forms::Section
              parent
            elsif form&.key_name&.match?(/\Ashared_schema_template_\d+\z/)
              all_sorted_properties.find do |array|
                prop = array.first
                prop.is_a?(JSF::Forms::Field::Shared) && prop.shared_def == form
              end&.first
            end

            index = find_index.call(section_or_shared) + 1 if section_or_shared
          end

          index ||= 0

          all_sorted_properties.insert(index, *current_arrays)
        end

        all_sorted_properties.each { |arr| yield(*arr) }
      end

      # @return void
      def each_sorted_form_with_document(document, **)
        is_create = false

        all_sorted_properties = []
        offsets = {}
        find_index = ->(prop) { all_sorted_properties.size - all_sorted_properties.reverse.find_index { |a| a[0] == prop } - 1 }
        increment_section_offsets = ->(path, increment) {
          path.each do |v|
            next unless offsets.key?(v)

            offsets[v] += increment
          end
        }

        each_form_with_document(
          document,
          skip_on_condition: true,
          skip_tree_when_hidden: true,
          is_create:,
          **
        ) do |form, condition, _current_level, current_doc, _current_empty_doc, document_path, section_or_shared|
          current_arrays = form.sorted_properties.each_with_object([]) do |property, array|
            next unless property.visible(is_create:)

            value = [property, current_doc, document_path]
            array.push(value)
          end

          key_names = current_arrays.map { |a| a[0].key_name }

          index = nil
          if condition
            offset_key = condition.condition_property_key
            offset = (offsets[offset_key] ||= [])
            index = find_index.call(condition.condition_property) + offset.size + 1
            offsets[offset_key] += key_names
          elsif section_or_shared
            if section_or_shared.is_a?(JSF::Forms::Section)
              offset_key = section_or_shared.key_name

              if offsets.key?(offset_key)
                # add section entry
                insert_at = find_index.call(section_or_shared) + offsets[offset_key].size + 1
                all_sorted_properties.insert(insert_at, all_sorted_properties.find { |a| a[0] == section_or_shared })

                # increment section offsets
                increment_section_offsets.call(document_path, [offset_key])
              end

              offsets[offset_key] = []

              # remove all offsets of inner sections
              section_or_shared[:items].each_form do |form, condition|
                offsets.delete(condition.condition_property_key) if condition
                form.properties.each_value do |v|
                  next unless v.is_a?(JSF::Forms::Section)

                  offsets.delete(v.key_name)
                end
              end
            end

            index = find_index.call(section_or_shared) + 1
          end

          index ||= 0

          # increment section offsets
          increment_section_offsets.call(document_path, key_names)

          all_sorted_properties.insert(index, *current_arrays)
        end

        all_sorted_properties.each { |arr| yield(*arr) }
      end

      # Builds a new hash considering the following:
      #
      #   - removes all nil values
      #   - removes all unknown keys
      #   - removes all keys with displayProperties.hidden
      #   - removes all keys with displayProperties.hideOnCreate if record is new
      #   - removes all keys in unactive trees
      #
      # @return [JSF::Forms::Document]
      def cleaned_document(document, is_create: false, **)
        # iterate recursively through schemas
        new_document = each_form_with_document(
          document,
          skip_tree_when_hidden: true,
          skip_on_condition: true,
          is_create:,
          **
        ) do |form, _condition, _current_level, current_doc, current_empty_doc, _document_path|
          form[:properties].each do |key, property|
            next unless property.visible(is_create:)

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
      # @note does not consider forms inside '$defs' key
      #
      # @todo consider Section count
      #
      # @param document [Hash{String}, JSF::Forms::Document]
      # @return [Float, NilClass]
      def set_specific_max_scores!(document, is_create: false, condition_proc: nil, **)
        return if self['disableScoring']

        score_value = score_initial_value

        # iterate recursively through schemas
        specific_max_score_document = each_form_with_document(
          document,
          skip_tree_when_hidden: true,
          skip_on_condition: true,
          is_create:,
          **
        ) do |form, _condition, _current_level, current_doc, current_empty_doc, _document_path|
          # iterate properties
          form[:properties].each do |k, prop|
            next unless prop.visible(is_create:)
            next unless (SCORABLE_FIELDS.include?(prop.class) && prop.scored?)

            value = current_doc.dig(k)

            field_score = if value.nil?
              prop.max_score
            else

              # check for any visible child field
              visible_scorable_children = prop.dependent_conditions.any? do |cond|
                next unless cond.evaluate(current_doc, &condition_proc)

                cond[:then]&.scored_with_document?(
                  current_doc,
                  is_create:
                ) # TODO: need to pass more arguments?
              end

              if visible_scorable_children
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

      # @return [Float, NilClass]
      def set_scores!(document, is_create: false, **)
        return if self['disableScoring']

        score_value = score_initial_value

        # iterate recursively through schemas
        score_document = each_form_with_document(
          document,
          skip_tree_when_hidden: true,
          skip_on_condition: true,
          is_create:,
          **
        ) do |form, _condition, _current_level, current_doc, current_empty_doc, _document_path|
          # iterate properties and increment score_value if needed
          form[:properties].each do |k, prop|
            next unless prop.visible(is_create:)
            next unless prop.respond_to?(:score_for_value) && prop.scored?

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

      def set_failures!(document, is_create: false, **)
        total_failed = 0

        # iterate recursively through schemas
        failed_document = each_form_with_document(
          document,
          skip_tree_when_hidden: true,
          skip_on_condition: true,
          is_create:,
          **
        ) do |form, _condition, _current_level, current_doc, current_empty_doc, _document_path|
          # iterate properties
          form[:properties].each do |k, prop|
            next unless prop.visible(is_create:)
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
      def scored?(cache: false, **args)
        return false if cache && self['hasScoring'] == false

        value = if self['disableScoring']
          false
        else
          has_scoring = false
          each_form(**args) do |form|
            form.properties&.each_value do |field|
              if field.scored?
                has_scoring = true
                break
              end
            end
          end
          has_scoring
        end

        self['hasScoring'] = value unless meta[:is_subschema]
        value
      end

      # @return [Boolean]
      def scored_with_document?(document, is_create: false, **_kwargs)
        return false if self['disableScoring']

        each_form_with_document(document) do |form, _condition, _current_level, _current_doc, _current_empty_doc, _document_path, _section_or_shared|
          form[:properties].each_value do |property|
            next unless property.visible(is_create:)
            next if property.is_a?(JSF::Forms::Section)

            return true if property.scored?
          end
        end
        false
      end

      # Initial value when scoring a document
      #
      # @return [Float, NilClass]
      def score_initial_value
        scored?(cache: true) ? 0.0 : nil
      end

      # # Calculates the MAXIMUM ATTAINABLE score considering all possible branches
      # # A block is REQUIRED to resolve whether a conditional field is visible or not
      # #
      # # @todo consider hideOnCreate
      # # @todo support non repeatable JSF::Forms::Section
      # #
      # # @param [Boolean] skip_hidden
      # # @param [Proc] &block
      # # @return [Nil|Float]
      # def max_score(skip_hidden: true, &block)
      #   return if self['disableScoring']

      #   self[:properties]&.inject(nil) do |acum, (name, field)|
      #     if field.is_a?(JSF::Forms::Section)
      #       raise StandardError.new('JSF::Forms::Section field is not supported for max_score')
      #     end
      #     next acum if skip_hidden && field.hidden?

      #     # Field may have conditional fields so we go recursive trying all possible
      #     # values to calculate the max score
      #     field_score = if CONDITIONAL_FIELDS.include?(field.class) && field.has_dependent_conditions?

      #       # 1) Calculate a set of values that can affect own score
      #       # 2) Calculate a set of values that can trigger branches, affecting score
      #       score_relevant_values = case field
      #       when JSF::Forms::Field::Select
      #         field.response_set[:anyOf].map do |obj|
      #           obj[:const]
      #         end
      #       when JSF::Forms::Field::Switch
      #         [true, false]
      #       when JSF::Forms::Field::NumberInput
      #         # TODO: this logic assumes only equal and not equal are supported

      #         (field.dependent_conditions || []).map do |condition|
      #           sub_condition = condition[:if][:properties].values[0]
      #           if sub_condition.key?(:not)
      #             'BP8;x&/dTF2Qn[RG45>?234/>?#5dsgfhDFGH++?asdf.' # some very random text
      #           else
      #             sub_condition[:const]
      #           end
      #         end
      #       else
      #         StandardError.new("conditional field #{field.class} is not yet supported for max_score")
      #       end

      #       # iterate posible values and take only the max_score
      #       score_relevant_values&.map do |value|
      #         # get the matching dependent conditions for a value and
      #         # calculate MAX score for all of them
      #         value_dependent_conditions = field.dependent_conditions_for_value({name.to_s => value}, &block)
      #         sub_schemas_max_score = value_dependent_conditions.inject(nil) do |acum_score, condition|
      #           [
      #             acum_score,
      #             condition[:then]&.max_score(&block)
      #           ].compact.inject(&:+)
      #         end

      #         field_score_for_value = field.respond_to?(:score_for_value) ? field.score_for_value(value) : nil
      #         [
      #           sub_schemas_max_score,
      #           field_score_for_value
      #         ].compact.inject(&:+)
      #       end&.compact&.max

      #     # Field has score but not conditional fields
      #     elsif SCORABLE_FIELDS.include? field.class
      #       field.max_score
      #     else
      #       nil
      #     end

      #     [acum, field_score].compact.inject(&:+)
      #   end
      # end

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
            property = get_merged_property(key, ignore_sections: true)

            case property
            when JSF::Forms::Field::Checkbox
              value.map { |v|
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
                property.form.i18n_document(doc, locale:, missing_locale_msg:)
              end
            # go recursive on shared
            when JSF::Forms::Field::Shared
              property
                .shared_def
                .i18n_document(value, locale:, missing_locale_msg:)
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
      # - does not migrate JSF::Forms::Field::Shared, because the property key must not change
      #
      # @ToDo consider shared fields
      #
      # @return [JSF::Forms::Form] new instance with changed ids
      def dup_with_new_references(
        property_id_proc: ->(id) { id.slice(0...-6) + SecureRandom.uuid[0...6] },
        response_set_id_proc: ->(_id) { SecureRandom.uuid }
      )
        migrated_response_sets = {}
        migrated_props = {}

        each_form(ignore_defs: false) do |form|
          # migrate properties
          prop_keys = form['properties'].keys
          prop_keys.each do |prop_key|
            prop = form['properties'][prop_key]
            next if prop.is_a?(JSF::Forms::Field::Static)
            next if prop.is_a?(JSF::Forms::Field::Shared)

            migrated_props[prop_key] ||= property_id_proc.call(prop_key)

            # migrate response sets
            if prop.respond_to?(:response_set_id)
              id = prop.response_set_id.sub('#/$defs/', '')
              migrated_response_sets[id] ||= response_set_id_proc.call(id)
            end
          end

          # migrate conditions
          # this is not required since all condition_property_keys should be a subset of the form's properties
          form[:allOf].each do |condition|
            prop_key = condition.condition_property_key
            migrated_props[prop_key] ||= property_id_proc.call(prop_key)
          end
        end

        strigified = as_json.to_json

        # migrate keys
        migrated_props.merge(migrated_response_sets).each do |old, key|
          strigified.gsub!(/\b#{old}\b/, key)
        end

        self.class.new(JSON.parse(strigified))
      end

      def sample_document(is_create: false, **_kwargs)
        doc = {}

        # since we start with an empty document, all conditions
        # are evaluated as false. To counter this, first we create
        # a sample document with +skip_on_condition+ as false and then
        # we pass it to +cleaned_document+
        document = each_form_with_document(
          doc,
          skip_tree_when_hidden: true,
          skip_on_condition: false,
          is_create:
        ) do |form, _condition, _current_level, _current_doc, current_empty_doc, _document_path|
          # iterate properties
          form[:properties].each do |k, prop|
            next unless prop.visible(is_create:)
            next unless prop.respond_to?(:sample_value)

            # set for field
            value = prop.sample_value
            value = yield(k, prop, value) if block_given?
            current_empty_doc[k] = value unless value.nil?
          end
        end

        # remove fields that should not exist due to conditions
        cleaned_document(document, is_create:)
      end

      # @note CAREFUL, ignores all logic so all posible fields will be present
      #   on the document
      #
      # @todo handle sections
      #
      # @return [Array<String>]
      def empty_document_with_all_props
        doc = {}

        each_form_with_document(
          doc,
          skip_tree_when_hidden: false,
          skip_on_condition: false,
          is_create: false
        ) do |form, _condition, _current_level, _current_doc, current_empty_doc, _document_path|
          # iterate properties
          form[:properties].each do |k, prop|
            next if prop['type'] == 'null'

            # set for field
            current_empty_doc[k] = nil
          end
        end
      end

      # @param document [JSF::Forms::Document]
      # @return [Hash{String =>*}]
      def collect_values_from_document(document)
        data = {}

        return data unless block_given?

        each_form_with_document(
          document,
          ignore_defs: false
        ) do |form, _condition, _current_level, current_doc, _current_empty_doc, _document_path|
          form.properties.each do |k, v|
            next unless yield(v)

            value = current_doc[k]
            data[k] = value if value
          end
        end

        data
      end

      # @return [void]
      def handle_document_changes(new_document, previous_document, is_create:, callback: nil, **)
        each_form_with_document(
          new_document,
          is_create:,
          **
        ) do |form, _condition, _current_level, current_doc, _current_empty_doc, document_path|
          form[:properties].each do |key, property|
            val = current_doc[key]
            next unless val && previous_document&.dig(*document_path, key) != val
            next unless property.visible(is_create:) # always?

            yield(form, key, property, current_doc, document_path)
          end
        end
      end

      # Mutates the entire Form to a json schema compliant
      #
      # @return [void]
      def legalize!
        if !meta[:is_subschema]
          delete('schemaFormVersion')
          delete('availableLocales')
          delete('hasScoring')
          delete('disableScoring')
        end
        delete('displayProperties')
        self
      end

      # # Allows the definition of migrations to 'upgrade' schemas when the standard changes
      # # The method is only the last migration script (not versioned)
      # #
      # # @return [void]
      # def migrate!
      # end

      private

      # redefined as private to favor append*, prepend* methods
      def add_property(*args, &block)
        super
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