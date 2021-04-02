module SchemaForm

  DEFAULT_LOCALE = :es
  AVAILABLE_LOCALES = [:es, :en]

  class Form < ::SuperHash::Hasher

    include JsonSchema::SchemaMethods::Schemable
    include JsonSchema::Validations::Validatable
    include JsonSchema::SchemaMethods::Buildable
    include JsonSchema::StrictTypes::Object
    # include SuperHash::Helpers

    CONDITIONAL_FIELDS = [
      SchemaForm::Field::Select,
      SchemaForm::Field::Switch,
      SchemaForm::Field::NumberInput,
      # SchemaForm::Field::TextInput
    ].freeze

    SCORABLE_FIELDS = [
      SchemaForm::Field::Checkbox,
      SchemaForm::Field::Slider,
      SchemaForm::Field::Switch,
      SchemaForm::Field::Select
    ].freeze

    # Proc used to redefine an instance builder
    # This is required because JsonSchema::Schema has its own builder
    SUBSCHEMA_PROC = Proc.new do |inst|
      inst.define_singleton_method(:builder) do |*args|
        SchemaForm::Form::BUILDER.call(*args)
      end
    end
    
    #defined in a Proc so it can be reused by SUBSCHEMA_PROC
    BUILDER = ->(attribute, obj, meta, options) {
      
      if attribute == :responseSets #temporary for compatibility on v3.0.0 migrations
        return Hash.new(obj)
      end

      if attribute == :definitions
        if obj[:isResponseSet]
          return SchemaForm::ResponseSet.new(obj, meta, options)
        else
          if obj[:type] == 'object'
            return SchemaForm::Form.new(obj, meta, options)
          end
          # if obj.key?(:'$ref')
          #   return SchemaForm::ComponentRef.new(obj, meta, options)
          # end
        end
      end

      #ToDo be more specific
      if [:allOf, :if, :not, :additionalProperties, :items, :definitions].include?(attribute)
        return JsonSchema::Schema.new(obj, meta, options.merge(preinit_proc: SUBSCHEMA_PROC))
      end

      if attribute == :properties && obj.key?(:$ref)
        if obj.dig(:displayProperties, :isSelect)
          return SchemaForm::Field::Select.new(obj, meta, options)
        else
          return ::SchemaForm::Field::Component.new(obj, meta, options)
        end
      end

      klass = case obj[:type]
      # when 'object', :object
      #   SchemaForm::Form
      when 'string', :string
        if obj[:format] == 'date-time'
          SchemaForm::Field::DateInput
        elsif !obj[:responseSetId].nil? #deprecated, only for compatibility before v3.0.0
          SchemaForm::Field::Select
        else
          SchemaForm::Field::TextInput
        end
      when 'number', :number, 'integer', :integer
        if obj&.dig(:displayProperties, :useSlider)
          SchemaForm::Field::Slider
        else
          SchemaForm::Field::NumberInput
        end
      when 'boolean', :boolean
        SchemaForm::Field::Switch
      when 'array', :array
        SchemaForm::Field::Checkbox
      when 'null', :null
        if obj&.dig(:displayProperties, :useHeader)
          SchemaForm::Field::Header
        elsif obj&.dig(:displayProperties, :useInfo)
          SchemaForm::Field::Info
        elsif obj[:static]
          SchemaForm::Field::Static
        end
      else
        #detect by other ways than 'type' property
        if obj.has_key?(:properties)
          SchemaForm::Form
        end
      end

      return klass.new(obj, meta, options) if klass

      #ToDo be more specific
      if obj.has_key?(:const) || obj.has_key?(:not) || obj.has_key?(:enum)
        return JsonSchema::Schema.new(obj, meta, options.merge(preinit_proc: SUBSCHEMA_PROC ))
      end

      raise StandardError.new("builder conditions not met: (attribute: #{attribute}, obj: #{obj}, meta: #{meta})")
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
    attribute? :availableLocales, default: ->(instance) { instance.meta[:is_subschema] ? nil : [].freeze }
    update_attribute :properties, default: ->(instance) { {}.freeze }
    update_attribute :required, default: ->(instance) { [].freeze }
    update_attribute :allOf, default: ->(instance) { [].freeze }

    #override builder
    def builder(*args)
      SchemaForm::Form::BUILDER.call(*args)
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
        regex = Regexp.new("\\A\/properties\/#{k}\\z")
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

    # Checks if the whole form is valid for a specified locale
    # @param locale [Symbol] locale
    # @return [Boolean] if valid
    def valid_for_locale?(locale = DEFAULT_LOCALE)
      all_properties_are_valid = self.merged_properties.find do |k,v|
        v.valid_for_locale?(locale) == false
      end.nil?
      all_response_sets_are_valid = self.response_sets.find do |k,v|
        v.valid_for_locale?(locale) == false
      end.nil?
      all_properties_are_valid && all_response_sets_are_valid
    end

    # Retrieves all properties that are missing a response set
    # @param
    # @return
    # def merged_properties_missing_response_set(levels=nil)
    #   merged_properties(levels)&.each_with_object([]) |(k,v) array| do
    #     array.push(v) if v.respond_to?(:response_set) && v.response_set.nil?
    #   end
    # end

    ###########################
    ###COMPONENT MANAGEMENT####
    ###########################

    # Retrieves all component definitions (SharedSchemaTemplates)
    # @return [Hash] subset of definitions filtered
    def component_definitions
      self[:definitions].select do |k,v|
        !v.key?(:isResponseSet) && (v.key?(:$ref) || v[:type] == 'object')
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

    # returns the response set definition with specified id
    # def get_response_set(id)
    #   return nil if id.nil?
    #   path = id&.sub('#/', '')&.split('/')&.map(&:to_sym)
    #   self.dig(*path)
    # end

    def add_response_set(id, definition)
      new_definitions_hash = {}.merge(self[:definitions])
      new_definitions_hash[id] = definition
      self[:definitions] = SuperHash::DeepKeysTransform.symbolize_recursive(new_definitions_hash)
    end

    ##########################
    ###PROPERTY MANAGEMENT####
    ##########################

    # get properties
    def properties
      self[:properties]
    end

    # get dynamic properties
    def dynamic_properties(levels=nil)
      get_all_of_subschemas(levels).reduce({}) do |acum, subschema|
        acum.merge(subschema.properties || {})
      end
    end

    # get own and dynamic properties
    def merged_properties(levels=nil)
      (self[:properties] || {})
        .merge(self.dynamic_properties(levels))
    end

    # returns the property JSON definition inside the properties key
    def get_property(property)
      self.dig(:properties, property.to_sym)
    end

    def get_dynamic_property(property, levels=nil)
      dynamic_properties(levels)&.[](property.to_sym)
    end

    def get_merged_property(property, levels=nil)
      merged_properties(levels)&.[](property.to_sym)
    end

    # Adds a property with a sort value of 0 and resorts all other properties
    # @param id [Symbol] name of the property
    # @param definition [Hash] the schema to add
    # @param options[:required] [Boolean] if the property should be required
    # @return [Object] Property added
    def prepend_property(id, definition, options={})
      new_definition = {}.merge(definition)
      SuperHash::Utils.bury(new_definition, :displayProperties, :sort, -1)
      add_property(id, new_definition, options)
      resort!
    end

    # Adds a property with a sort value 1 more than the max and resorts all other properties
    # @param id [Symbol] name of the property
    # @param definition [Hash] the schema to add
    # @param options[:required] [Boolean] if the property should be required
    # @return [Object] Property added
    def append_property(id, definition, options={})
      new_definition = {}.merge(definition)
      SuperHash::Utils.bury(new_definition, :displayProperties, :sort, (self.max_sort + 1))
      add_property(id, new_definition, options)
      resort!
    end

    # Adds a property with a specified sort value and resorts all other properties
    # @param id [Symbol] name of the property
    # @param definition [Hash] the schema to add
    # @param options[:required] [Boolean] if the property should be required
    # @return [Object] Property added
    def insert_property_at_index(index, id, definition, options={})
      new_definition = {}.merge(definition)
      SuperHash::Utils.bury(new_definition, :displayProperties, :sort, (index - 0.5))
      add_property(id, new_definition, options)
      resort!
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
    def add_conditional_property(property_id, definition, options={}, position:, dependent_on:, type:, value:)
      condition = add_or_get_condition(dependent_on, type, value)
      added_property = case position
      when :append
        condition[:then].append_property(property_id, definition, options)
      when :prepend
        condition[:then].prepend_property(property_id, definition, options)
      when Integer
        condition[:then].insert_property_at_index(position, property_id, definition, options)
      end
      yield(condition[:then]) if block_given?
      added_property
    end

    # Retrieves all subforms for a specified number of recursion levels
    # @param levels [Integer] number of recursion to apply
    # @return [Array] array of subschemas retrieved
    #ToDo consider else key in allOf
    def get_all_of_subschemas(levels=nil, level=0)
      return [] if levels && level >= levels
      schemas_array=[]
      self[:allOf]&.each do |condition_subschema|
        subschema = condition_subschema[:then]
        if subschema
          schemas_array.push(subschema)
          schemas_array.concat(subschema.get_all_of_subschemas(levels, level + 1))
        end
      end
      schemas_array
    end

    # Calculates the maximum attainable score considering all possible branches
    # @return [Nil|Float]
    def max_score(&block)
      self[:properties].inject(nil) do |acum, (name, field_def)|
        [
          acum,
          max_score_for_branch(name, field_def, &block)
        ].compact.inject(&:+)
      end
    end

    # Calculates the maximum attainable score for a specific branch
    # @return [Nil|Float]
    def max_score_for_branch(name, field, &block)

      # Field may have conditional fields so we go recursive trying all possible
      # values to calculate the max score
      if CONDITIONAL_FIELDS.include? field.class
        
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
    end

    # @ return [Form] a mutated Form that is json schema compliant
    def compile!
      #compile root level properties
      self[:properties]&.each do |id, definition|
        definition.compile! if definition&.respond_to?(:compile!)
      end

      #compile dynamic properties
      self.get_all_of_subschemas.each{|form| form.compile!}

      self
    end

    # Allows the definition of migrations to 'upgrade' schemas when the standard changes
    # The method is only the last migration script (not versioned)
    # @return [Form] a mutated instance of the Form
    def migrate!(options={})
      # migrate properties
      self[:properties]&.each do |id, definition|
        if definition&.respond_to?(:migrate!)
          puts 'migrating ' + definition.class.to_s.demodulize
          definition.migrate!
        end
      end
      
      #migrate dynamic forms
      self.get_all_of_subschemas.each{|form| form.migrate!}

      # migrate response sets
      self[:definitions]&.each do |id, definition|
        if definition&.respond_to?(:migrate!)
          puts 'migrating response set'
          definition.migrate!
        end
      end

      #3.0.0 migrations
      if self[:schemaFormVersion] != '3.0.0'
        if !meta[:is_subschema]
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

      # migrate form object
      if !meta[:is_subschema]
        self[:schemaFormVersion] = '3.0.0'
      end
      self
    end

    private

    #make this private so to favor append, prepend methods
    def add_property(*args)
      super(*args)
    end

  end
end