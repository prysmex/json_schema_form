module SchemaForm

  DEFAULT_LOCALE = :es
  AVAILABLE_LOCALES = [:es, :en]

  class Form < ::SuperHash::Hasher

    include JsonSchema::SchemaMethods::Schemable
    include JsonSchema::Validations::Validatable
    include JsonSchema::SchemaMethods::Buildable
    include JsonSchema::StrictTypes::Object

    CONDITIONAL_FIELDS = [
      SchemaForm::Field::Select,
      SchemaForm::Field::Switch,
      SchemaForm::Field::NumberInput
    ].freeze

    SCORABLE_FIELDS = [
      SchemaForm::Field::Checkbox,
      SchemaForm::Field::Slider,
      SchemaForm::Field::Switch,
      SchemaForm::Field::Select
    ].freeze

    # Proc used to redefine a subschema's instance builder.
    # ONE reason we need this is that a when we encounter an allOf, JsonSchema::Schema
    # objects are instantiated, but we need them to instantiate SchemaForm::Field classes,
    # so we override their builder.
    SUBSCHEMA_PROC = Proc.new do |instance|
      instance.instance_variable_set('@builder', BUILDER)
    end
    
    # Defined in a Proc so it can be reused:
    BUILDER = ->(attribute, subschema, instance, init_options={}) {

      case instance
      when SchemaForm::Form

        case attribute
        when :definitions
          if subschema[:isResponseSet]
            return SchemaForm::ResponseSet.new(subschema, init_options)
          elsif subschema[:type] == 'object' #replaced schemas
            return SchemaForm::Form.new(subschema, init_options)
          elsif subschema.key?(:$ref) # shared definition
            return JsonSchema::Schema.new(subschema, init_options.merge(preinit_proc: SUBSCHEMA_PROC))
          end
        when :allOf
          return JsonSchema::Schema.new(subschema, init_options.merge(preinit_proc: SUBSCHEMA_PROC))
        when :properties
          if subschema.key?(:$ref)
            if subschema.dig(:displayProperties, :isSelect)
              return SchemaForm::Field::Select.new(subschema, init_options)
            else
              return ::SchemaForm::Field::Component.new(subschema, init_options)
            end
          end

          klass = case subschema[:type]
            when 'string', :string
              if subschema[:format] == 'date-time'
                SchemaForm::Field::DateInput
              elsif !subschema[:responseSetId].nil? #deprecated, only for compatibility before v3.0.0
                SchemaForm::Field::Select
              else
                SchemaForm::Field::TextInput
              end
            when 'number', :number, 'integer', :integer
              if subschema&.dig(:displayProperties, :useSlider)
                SchemaForm::Field::Slider
              else
                SchemaForm::Field::NumberInput
              end
            when 'boolean', :boolean
              SchemaForm::Field::Switch
            when 'array', :array
              if subschema.dig(:items, :format) == 'uri'
                SchemaForm::Field::FileInput
              else
                SchemaForm::Field::Checkbox
              end
            when 'null', :null
              if subschema&.dig(:displayProperties, :useHeader)
                SchemaForm::Field::Header
              elsif subschema&.dig(:displayProperties, :useInfo)
                SchemaForm::Field::Info
              elsif subschema[:static]
                SchemaForm::Field::Static
              end
            end
    
          return klass.new(subschema, init_options) if klass
        end
        
      when JsonSchema::Schema

        case attribute
        when :then
          return SchemaForm::Form.new(subschema, init_options)
        else
          return JsonSchema::Schema.new(subschema, init_options.merge(preinit_proc: SUBSCHEMA_PROC ))
        end
        
      end

      raise StandardError.new("builder conditions not met: (attribute: #{attribute}, subschema: #{subschema}, meta: #{instance.meta})")
    }

    # To prevent manually building conditions, we define this Proc
    # as a utility
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

    update_attribute :definitions, default: ->(instance) { instance.meta[:is_subschema] ? nil : {}.freeze }
    update_attribute :properties, default: ->(instance) { {}.freeze }
    update_attribute :required, default: ->(instance) { [].freeze }
    update_attribute :allOf, default: ->(instance) { [].freeze }
    attribute? :availableLocales, default: ->(instance) { instance.meta[:is_subschema] ? nil : [].freeze }
    
    def initialize(obj={}, options={})
      options = {
        builder: SchemaForm::Form::BUILDER
      }.merge(options)

      super(obj, options)
    end

    ##################
    ###VALIDATIONS####
    ##################
    
    # Validation schema used for building own errors hash
    # @param passthru [Hash] Options passed
    # @return [Dry::Schema::JSON] Schema
    def validation_schema(passthru)
      is_subschema = meta[:is_subschema]
      is_inspection = passthru[:is_inspection]
      Dry::Schema.JSON do
        config.validate_keys = true

        before(:key_validator) do |result|
          JsonSchema::Validations::DrySchemaValidatable::BEFORE_KEY_VALIDATOR_PROC.call(result.to_h)
        end

        required(:properties).value(:hash)
        required(:required).value(:array?).array(:str?)
        required(:allOf).array(:hash)
        if !is_subschema
          optional(:'$id').filled(:string)
          required(:'title').maybe(:string)
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
    # - get errors from validation_schema
    # - ensure each property key matches the property's $id
    # - ensure only whitelisted properties have conditional properties
    # @param passthru [Hash] Options passed
    # @return [Hash] Errors
    def own_errors(passthru)
      errors_hash = own_errors = JsonSchema::Validations::DrySchemaValidatable::OWN_ERRORS_PROC.call(
        validation_schema(passthru),
        self
      )

      self[:properties]&.each do |k,v|
        # check property $id
        regex = Regexp.new("\\A#/properties\/#{k}\\z")
        if v[:$id]&.match(regex).nil?
          errors_hash["$id_#{k}"] = "$id: '#{v[:$id]}' did not to match #{regex}"
        end

        if v.respond_to?(:response_set) && v.response_set.nil?
          errors_hash["response_set_#{k}"] = 'response set is not present'
        end

        if CONDITIONAL_FIELDS.include?(v.class)
        else
          if v.dependent_conditions.size > 0
            errors_hash["conditionals_#{k}"] = "only the following fields can have conditionals (#{SchemaForm::Form::CONDITIONAL_FIELDS.map{|name| name.name.demodulize}.join(', ')})"
          end
        end
      end
      
      errors_hash
    end

    ##############
    ###METHODS####
    ##############

    # Checks locale vality for the following:
    #   - properties (recursive)
    #   - response sets
    # @param locale [Symbol] locale
    # @return [Boolean] if valid
    def valid_for_locale?(locale = DEFAULT_LOCALE)

      # check response_sets
      invalid_response_set = self.response_sets.any? do |k,v|
        v.valid_for_locale?(locale) == false
      end
      return false if invalid_response_set 

      # check properties
      has_invalid_property = self.schema_form_iterator do |_, then_hash|
        invalid_prop = then_hash&.properties&.any? do |k,v|
          v.valid_for_locale?(locale) == false
        end

        break invalid_prop if invalid_prop
      end

      !has_invalid_property
    end

    ###########################
    ###COMPONENT MANAGEMENT####
    ###########################

    # Retrieves all component definitions (SharedSchemaTemplates)
    # @return [Hash] subset of definitions filtered
    def component_definitions
      self[:definitions].select do |k,v|
        !v.key?(:isResponseSet) && 
            (v.key?(:$ref) || v[:type] == 'object')
      end
    end

    ##############################
    ###RESPONSE SET MANAGEMENT####
    ##############################

    # get responseSets #ToDo this can be improved
    def response_sets
      self[:definitions].select do |k,v|
        v[:isResponseSet]
      end
    end

    def add_response_set(id, definition)
      new_definitions_hash = {}.merge(self[:definitions])
      new_definitions_hash[id] = definition
      self[:definitions] = SuperHash::DeepKeysTransform.symbolize_recursive(new_definitions_hash)
      self[:definitions][id]
    end

    ##########################
    ###PROPERTY MANAGEMENT####
    ##########################

    # get properties
    def properties
      self[:properties]
    end

    # ToDo consider else key in allOf
    # Iterates and yields each SchemaForm along with its condition.
    # If 'skip_when_false' is true and the returned value from the yield equals false,
    # then the iteration of that tree is halted

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

    # Builds a document with a key for each property on the schema form.
    #   - pass {skip_when_false: true} to include only visible properties
    def nil_document(document, **args, &block)
      #root
      obj = self[:properties].transform_values{|v| nil}

      #subschemas
      subschema_iterator(**args) do |if_hash, then_hash, parent_schema, current_level|
        key = if_hash[:properties].keys.first
        value = yield( if_hash, {"#{key}".to_sym => document[key]}, parent_schema.dig(:properties, key) )

        obj.merge!( then_hash[:properties].transform_values{|v| nil} ) if value

        value
      end

      obj
    end

    # get dynamic properties
    def dynamic_properties(**args)
      properties = {}
      subschema_iterator(**args) do |_, then_hash|
        properties.merge!(then_hash&.properties || {})
      end
      properties
    end

    # get own and dynamic properties
    def merged_properties(**args)
      (self[:properties] || {})
        .merge(self.dynamic_properties(**args))
    end

    # returns the property definition inside the properties key
    def get_property(property)
      self.dig(:properties, property.to_sym)
    end

    # returns the property definition of the first matched key in subschemas
    def get_dynamic_property(property, **args)
      property = property.to_sym
      subschema_iterator(**args) do |_, then_hash|
        props = then_hash&.properties
        break props[property] if props&.key?(property)
      end
    end

    # returns the property definition of the first match in a root or subschema property
    def get_merged_property(property, **args)
      property = property.to_sym
      if self[:properties].key?(property)
        self[:properties][property]
      else
        get_dynamic_property(property, **args)
      end
    end

    # Adds a property with a sort value of 0 and resorts all other properties
    # @param id [Symbol] name of the property
    # @param definition [Hash] the schema to add
    # @param options[:required] [Boolean] if the property should be required
    # @return [Object] Property added
    def prepend_property(*args)
      insert_property_at_index(self.min_sort, *args)
    end

    # Adds a property with a sort value 1 more than the max and resorts all other properties
    # @param id [Symbol] name of the property
    # @param definition [Hash] the schema to add
    # @param options[:required] [Boolean] if the property should be required
    # @return [Object] Property added
    def append_property(*args)
      insert_property_at_index((self.max_sort + 1), *args)
    end

    # Adds a property with a specified sort value and resorts all other properties
    # @param id [Symbol] name of the property
    # @param definition [Hash] the schema to add
    # @param options[:required] [Boolean] if the property should be required
    # @return [Object] Property added
    def insert_property_at_index(index, id, definition, options={})

      prop = add_property(id, definition, options)
      SuperHash::Utils.bury(prop, :displayProperties, :sort, (index - 0.5))
      resort!
      prop
    end

    # Moves a property to a specific sort value and resorts needed properties
    # @param target [Integer] sort value to set
    # @param id [Symbol] name of property to move
    # @return [Object] mutated self
    def move_property(target, id)
      prop = self[:properties]&.find{|k,v| v.key_name == id.to_sym}
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

    def min_sort
      self[:properties]&.map{|k,v| v&.dig(:displayProperties, :sort) }&.min || 0
    end

    def max_sort
      self[:properties]&.map{|k,v| v&.dig(:displayProperties, :sort) }&.max || 0
    end

    def get_property_by_sort(i)
      self[:properties]&.find{|k,v| v&.dig(:displayProperties, :sort) == i}
    end

    def verify_sort_order
      for i in 0...(self[:properties]&.size || 0)
        return false if get_property_by_sort(i).blank?
      end
      true
    end

    def sorted_properties
      self[:properties]&.values&.sort_by{|v| v&.dig(:displayProperties, :sort)} || []
    end

    def resort!
      sorted = self.sorted_properties
      for i in 0...self[:properties].size
        property = sorted[i]
        property[:displayProperties][:sort] = i
      end
    end

    # Retrieves a condition
    # @param dependent_on [Symbol] name of property the condition depends on
    # @param type [Symbol] type of condition to filter by
    # @param value [String,Boolean,Integer] Value that makes the condition TRUE
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
    # @param dependent_on [Symbol] name of property the condition depends on
    # @param type [Symbol] type of condition to filter by
    # @param value [String,Boolean,Integer] Value that makes the condition TRUE
    # @return condition [Hash] added or retrieved condition hash
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
    # @param property_id [Symbol] name of property to be added
    # @param definition [Hash] the property to be added
    # @param options [Hash]
    # @param dependent_on [Symbol] name of property the condition depends on
    # @param type [Symbol] type of condition
    # @param value [Symbol] value that makes the condition TRUE
    # @return [] the added property
    def insert_conditional_property_at_index(sort_value, property_id, definition, options={})
      raise ArgumentError.new("sort must be an Integer, :prepend or :append, got #{sort_value}") unless sort_value.is_a?(Integer) || [:prepend, :append].include?(sort_value)
      dependent_on = options.delete(:dependent_on)
      type = options.delete(:type)
      value = options.delete(:value)

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

    def append_conditional_property(*args, &block)
      insert_conditional_property_at_index(:append, *args, &block)
    end

    def prepend_conditional_property(*args, &block)
      insert_conditional_property_at_index(:prepend, *args, &block)
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
          when SchemaForm::Field::Select
            field.response_set[:anyOf].map do |obj|
              obj[:const]
            end
          when SchemaForm::Field::Switch
            [true, false]
          when SchemaForm::Field::NumberInput
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

    # @ return [Form] a mutated Form that is json schema compliant
    def compile!
      self.schema_form_iterator do |_, then_hash|
        then_hash[:properties]&.each do |id, definition|
          definition.compile! if definition&.respond_to?(:compile!)
        end
      end
    end

    # Allows the definition of migrations to 'upgrade' schemas when the standard changes
    # The method is only the last migration script (not versioned)
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

      #3.0.0 migrations START, remove after version
      if self[:schemaFormVersion] != '3.0.0'
        if !meta[:is_subschema]
          # prepend # to all properties $id
          self.merged_properties.each do |k,v|
            v[:$id] = "##{v[:$id]}" unless v[:$id]&.start_with?('#')
          end

          # migrate responseSets => definitions
          new_definitions = self[:responseSets].inject({}) do |acum, (id, definition)|
            anyOf = definition[:responses].map do |r|
              hash = {
                type: 'string',
                const: r[:value],
                displayProperties: r[:displayProperties]
              }
              if options[:is_inspection]
                hash.merge!({
                  enableScore: r[:enableScore],
                  score: r[:score],
                  failed: r[:failed]
                })
              end
              hash
            end
            acum[id] = {
              type: 'string',
              isResponseSet: true,
              anyOf: anyOf
            }
            acum
          end
          old_definitions = SuperHash::DeepKeysTransform.symbolize_recursive(self[:definitions].as_json)
          self.delete(:responseSets)
          self[:definitions] = old_definitions.merge(new_definitions)
        else
          self.delete(:$id)
        end
        self.delete(:additionalProperties)
      end
      #3.0.0 migrations END, remove after version

      # migrate form object
      if !meta[:is_subschema]
        self[:schemaFormVersion] = '3.0.0'
      end

      self
    end

    private

    #make this private to favor append, prepend methods
    def add_property(*args)
      super(*args)
    end

  end
end