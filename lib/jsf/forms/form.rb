module JSF
  module Forms
    DEFAULT_LOCALE = 'es'
    AVAILABLE_LOCALES = ['es', 'en']
    VERSION = '3.0.0'
    
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
    
      # Proc used to redefine a subschema's instance attributes_transform_proc.
      # ONE reason we need this is that a when we encounter an allOf, JSF::Schema
      # objects are instantiated, but we need them to instantiate JSF::Forms::Field classes,
      # so we override their attributes_transform_proc.
      #
      # @param [Object] instance
      SUBSCHEMA_PROC = Proc.new do |instance|
        instance.instance_variable_set('@attributes_transform_proc', ATTRIBUTE_TRANSFORM)
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
              return JSF::Schema.new(value, init_options.merge(preinit_proc: SUBSCHEMA_PROC))
            end
          when 'allOf'
            return JSF::Schema.new(value, init_options.merge(preinit_proc: SUBSCHEMA_PROC))
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
                elsif !value[:responseSetId].nil? #deprecated, only for compatibility before v3.0.0
                  JSF::Forms::Field::Select
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
          
        when JSF::Schema
    
          case attribute
          when 'then'
            return JSF::Forms::Form.new(value, init_options)
          else
            return JSF::Schema.new(value, init_options.merge(preinit_proc: SUBSCHEMA_PROC ))
          end
          
        end
    
        raise StandardError.new("builder conditions not met: (attribute: #{attribute}, value: #{value}, meta: #{instance.meta})")
      }
    
      # utility to DRY code
      #
      # @param [Symbol], type
      # @return [Array]
      CONDITION_TYPE_TO_PATH= ->(type) {
        case type
        when :const
          [:const]
        when :not_const
          [:not, :const]
        when :enum
          [:enum]
        when :not_enum
          [:not, :enum]
        else
          ArgumentError.new("#{type} is not a whitelisted condition type")
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
    
          required(:properties).value(:hash)
          required(:required).value(:array?).array(:str?)
          required(:allOf).array(:hash)
          if !is_subschema
            optional(:'$id').filled(:string)
            optional(:'title').maybe(:string) #ToDo deprecate?
            required(:type).filled(Types::String.enum('object'))
            required(:schemaFormVersion).value(:string)
            required(:definitions).value(:hash)
            required(:availableLocales).value(:array?).array(:str?)
            required(:'$schema').filled(:string)
            if is_inspection
              optional(:maxScore) { int? | float? | nil? }
            end
          else
            optional(:'$schema').filled(:string)
          end
    
        end
      end
      
      # Build instance's erros hash
      #
      # - get errors from validation_schema
      # - ensure each property key matches the property's $id
      # - ensure only whitelisted properties have conditional properties
      #
      # @param passthru [Hash{Symbol => *}] Options passed
      # @return [Hash{Symbol => *}] Errors
      def own_errors(passthru={})
        errors_hash = JSF::Validations::DrySchemaValidatable::SCHEMA_ERRORS_PROC.call(
          validation_schema(passthru),
          self
        )
    
        self[:properties]&.each do |k,v|
          # check property $id key
          regex = Regexp.new("\\A#/properties\/#{k}\\z")
          if v[:$id]&.match(regex).nil?
            errors_hash["$id_#{k}"] = "$id: '#{v[:$id]}' did not to match #{regex}"
          end

          # ensure response sets exist
          if v.respond_to?(:response_set) && v.response_set_id && v.response_set.nil?
            errors_hash["response_set_#{k}"] = "response set #{v.response_set_id} not found"
          end
    
          if CONDITIONAL_FIELDS.include?(v.class)
          else
            if v.dependent_conditions.size > 0
              fields = JSF::Forms::Form::CONDITIONAL_FIELDS.map{|klass| klass.name.split('::').last}.join(', ')
              msg = "only the following fields can have conditionals (#{fields})"
              errors_hash["conditionals_#{k}"] = msg
            end
          end
        end
        
        errors_hash
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
    
      # Gets all component definitions, which may be only the referenced
      # or the replaced form
      #
      # @return [Hash{String => JSF::Forms::Form, JSF::Schema}]
      def component_definitions
        self[:definitions].select do |k,v|
          !v.key?(:isResponseSet) && 
              (v.key?(:$ref) || v[:type] == 'object')
        end
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
      # @return [String] passed id
      def add_response_set(id, definition)
        new_definitions_hash = {}.merge(self[:definitions])
        new_definitions_hash[id] = definition
        self[:definitions] = new_definitions_hash
        self[:definitions][id]
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
    
      # get dynamic properties
      #
      # @return [Hash{String => JSF::Forms::Field::*}]
      def dynamic_properties(**args)
        properties = {}
        subschema_iterator(**args) do |_, then_hash|
          properties.merge!(then_hash&.properties || {})
        end
        properties
      end
    
      # get own and dynamic properties
      #
      # @return [Hash{String => JSF::Forms::Field::*}]
      def merged_properties(**args)
        (self[:properties] || {})
          .merge(self.dynamic_properties(**args))
      end
    
      # gets the property definition inside the properties key
      #
      # @param [String, Symbol]
      # @return [JSF::Forms::Field::*]
      def get_property(property)
        self.dig(:properties, property)
      end
    
      # gets the property definition of the first matched key in subschemas
      #
      # @param [String, Symbol]
      # @return [JSF::Forms::Field::*]
      def get_dynamic_property(property, **args)
        property = property
        subschema_iterator(**args) do |_, then_hash|
          props = then_hash&.properties
          break props[property] if props&.key?(property)
        end
      end
    
      # gets the property definition of the first match in a root or subschema property
      #
      # @param [String, Symbol]
      # @return [JSF::Forms::Field::*]
      def get_merged_property(property, **args)
        property = property
        if self[:properties].key?(property)
          self[:properties][property]
        else
          get_dynamic_property(property, **args)
        end
      end
    
      # Adds a property with a sort value of 0 and resorts all other properties
      #
      # @see insert_property_at_index for arguments
      #
      # @return [JSF::Forms::Field::*] added property
      def prepend_property(*args)
        insert_property_at_index(self.min_sort, *args)
      end
    
      # Adds a property with a sort value 1 more than the max and resorts all other properties
      #
      # @see insert_property_at_index for arguments
      #
      # @return [JSF::Forms::Field::*] added property
      def append_property(*args)
        insert_property_at_index((self.max_sort + 1), *args)
      end
    
      # Adds a property with a specified sort value and resorts all other properties
      #
      # @param id [String,Symbol] name of the property
      # @param definition [Hash] the schema to add
      # @param options[:required] [Boolean] if the property should be required
      # @return [JSF::Forms::Field::*] added property
      def insert_property_at_index(index, id, definition, options={})
    
        prop = add_property(id, definition, options)
        SuperHash::Utils.bury(prop, :displayProperties, :sort, (index - 0.5))
        resort!
        prop
      end
    
      # Moves a property to a specific sort value and resorts needed properties
      #
      # @param target [Integer] sort value to set
      # @param id [String,Symbol] name of property to move
      # @return [JSF::Forms::Field::*] mutated self
      def move_property(target, id)
        prop = self[:properties]&.find{|k,v| v.key_name == id.to_s }
        if !prop.nil?
          current = prop[1][:displayProperties][:sort]
          range = Range.new(*[current, target].sort)
          selected = sorted_properties.select{|k| range.include?(k[:displayProperties][:sort]) }
          if target > current
            selected.each{|k| k[:displayProperties][:sort] -= 1 }
          else
            selected.each{|k| k[:displayProperties][:sort] += 1 }
          end
          prop[1][:displayProperties][:sort] = target
          resort!
        end
        self
      end
    
      # gets the minimum sort value for all properties
      #
      # @return [Integer]
      def min_sort
        self[:properties]&.map{|k,v| v&.dig(:displayProperties, :sort) }&.min || 0
      end
    
      # gets the maximum sort value for all properties
      #
      # @return [Integer]
      def max_sort
        self[:properties]&.map{|k,v| v&.dig(:displayProperties, :sort) }&.max || 0
      end
    
      # gets a property by a sort value
      #
      # @return [JSF::Forms::Field]
      def get_property_by_sort(i)
        self[:properties]&.find{|k,v| v&.dig(:displayProperties, :sort) == i}
      end
    
      # Checks if all sort values are consecutive and starting with 0
      #
      # @return [Boolean]
      def verify_sort_order
        for i in 0...(self[:properties]&.size || 0)
          return false if get_property_by_sort(i).blank?
        end
        true
      end
    
      # Sorts 'properties' by sort
      #
      # @return [Array<JSF::Forms::Field>]
      def sorted_properties
        self[:properties]&.values&.sort_by{|v| v&.dig(:displayProperties, :sort)} || []
      end
    
      # fixes sorting in case sort values are not consecutive.
      #
      # @return [void]
      def resort!
        sorted = self.sorted_properties
        for i in 0...self[:properties].size
          property = sorted[i]
          property[:displayProperties][:sort] = i
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
      def add_or_get_condition(dependent_on, type, value)
        raise ArgumentError.new('dependent property not found') if self.get_property(dependent_on).nil?
        condition = get_condition(dependent_on, type, value)
        if condition.nil?
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
          condition = self[:allOf].last
        end
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
      def insert_conditional_property_at_index(sort_value, property_id, definition, dependent_on:, type:, value:, **options)
        unless sort_value.is_a?(Integer) || [:prepend, :append].include?(sort_value)
          raise ArgumentError.new("sort must be an Integer, :prepend or :append, got #{sort_value}")
        end
    
        condition = add_or_get_condition(dependent_on, type, value)
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
      def append_conditional_property(*args, &block)
        insert_conditional_property_at_index(:append, *args, &block)
      end
    
      # Prepends a dependent property inside a subschema
      #
      # @return [JSF::Forms::Field::*]
      def prepend_conditional_property(*args, &block)
        insert_conditional_property_at_index(:prepend, *args, &block)
      end

      ###########
      #Utilities#
      ###########

      # Iterates and yields each JSF::Form along with its condition.
      # If 'skip_when_false' is true and the returned value from the yield equals false,
      # then the iteration of that tree is halted
      #
      # @todo consider else key in allOf
      #
      # @param start_level [Integer] Depth of allOf nesting to ignore (0 for root)
      # @param levels [Integer] Max depth of allOf nesting to starting from start_level
      # @param skip_when_false [Boolean]
      # @return [Nil]
      def schema_form_iterator(start_level: 0, levels: nil, skip_when_false: false, current_level: 0, &block)
        return if !start_level.nil? && !levels.nil? && current_level >= (start_level + levels)
        return if self[:allOf].nil?
    
        #root
        if current_level == 0 && current_level >= start_level
          yield( nil, self, nil, current_level )
        end
        current_level += 1
    
        #recursive allOf
        self[:allOf].each do |condition_subschema|
          if start_level.nil? || current_level >= start_level
            returned_value = yield(
              condition_subschema[:if],
              condition_subschema[:then],
              self,
              current_level
            )
            next if skip_when_false && (returned_value == false)
          end
          condition_subschema[:then]&.schema_form_iterator(
            start_level: start_level,
            levels: levels,
            skip_when_false: skip_when_false,
            current_level: current_level + 1,
            &block
          )
        end
    
        nil
      end
    
      # Calls 'schema_form_iterator' with a default start_level of 1 to include only subschemas
      # supports same params as 'schema_form_iterator'
      def subschema_iterator(start_level: 1, **args, &block)
        schema_form_iterator(start_level: start_level, **args, &block)
      end
    
      # Calculates the maximum attainable score considering all possible branches
      # A block is required to resolve whether a conditional field is visible or not
      # @return [Nil|Float]
      def max_score(skip_hidden: true, &block)
        self[:properties].inject(nil) do |acum, (name, field)|
          next acum if skip_hidden && field.hidden?
    
          # Field may have conditional fields so we go recursive trying all possible
          # values to calculate the max score
          field_score = if CONDITIONAL_FIELDS.include?(field.class)
            
            # can we generalize this?
            # - 1) when fields respond_to :possible_values
            # - 2) when fileds don't respond_to :possible_values get values from conditions
            possible_values = case field
            when JSF::Forms::Field::Select
              field.response_set[:anyOf].map do |obj|
                obj[:const]
              end
            when JSF::Forms::Field::Switch
              [true, false]
            when JSF::Forms::Field::NumberInput
              field.dependent_conditions&.map do |condition|
                condition_value = condition[:if][:properties].values[0]
                if condition_value.key?(:not)
                  'BP8;x&/dTF2Qn[RG' #some very random text
                else
                  condition_value[:const]
                end
              end || []
            end
        
            #iterate all posible values and take only the max_score
            possible_values&.map do |value|
              dependent_conditions = field.dependent_conditions_for_value({"#{name}" => value}, &block)
              sub_schemas_max_score = dependent_conditions.inject(nil) do |acum_score, condition|
                [
                  acum_score,
                  condition[:then]&.max_score(&block)
                ].compact.inject(&:+)
              end
              [
                sub_schemas_max_score,
                (field.respond_to?(:score_for_value) ? field.score_for_value(value) : nil)
              ].compact.inject(&:+)
            end&.compact&.max
          
          # Field hash score but not conditional fields
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
      def i18n_document(document, is_inspection: false, locale: :es)
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
    
      def i18n_document_value(attr_name, value, is_inspection: false, locale: :es, property: nil)
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
      #   - pass {skip_when_false: true} to include only visible properties
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