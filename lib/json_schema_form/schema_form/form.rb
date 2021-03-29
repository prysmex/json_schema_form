module SchemaForm
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

    SUBSCHEMA_PROC = Proc.new do |inst|
      inst.define_singleton_method(:builder) do |*args|
        SchemaForm::Form::BUILDER.call(*args)
      end
    end

    def builder(*args)
      SchemaForm::Form::BUILDER.call(*args)
    end
    
    #defined in a Proc so it can be reused by SUBSCHEMA_PROC
    BUILDER = ->(attribute, obj, meta, options) {
      
      if attribute == :responseSets #temporary for compatibility on v3.0.0 migrations
        return Hash.new(obj)
      end

      if attribute == :definitions
        # if obj.key?(:properties)
        #   return SchemaForm::Form.new(obj, meta, options)
        # end
        # if obj.key?(:'$ref')
        #   return SchemaForm::ComponentRef.new(obj, meta, options)
        # end
        if obj[:type] == 'string'
          return SchemaForm::ResponseSet.new(obj, meta, options)
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

    update_attribute :definitions, default: ->(instance) { instance.meta[:is_subschema] ? nil : {}.freeze }
    attribute? :availableLocales, default: ->(instance) { instance.meta[:is_subschema] ? nil : [].freeze }
    update_attribute :properties, default: ->(instance) { {}.freeze }
    update_attribute :required, default: ->(instance) { [].freeze }
    update_attribute :allOf, default: ->(instance) { [].freeze }

    ##################
    ###VALIDATIONS####
    ##################

    def validation_schema(passthru)
      is_subschema = meta[:is_subschema]
      is_inspection = passthru[:is_inspection]
      Dry::Schema.JSON do
        config.validate_keys = true

        before(:key_validator) do |result|
          JsonSchema::Validations::DrySchemaValidatable::BEFORE_KEY_VALIDATOR_PROC.call(result.to_h)
        end

        optional(:'$id').filled(:string)
        required(:properties).value(:hash)
        required(:required).value(:array?).array(:str?)
        required(:allOf).array(:hash)
        if !is_subschema
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

    def own_errors(passthru)
      errors_hash = own_errors = JsonSchema::Validations::DrySchemaValidatable::OWN_ERRORS_PROC.call(
        validation_schema(passthru),
        self
      )

      if meta[:is_subschema]
        if self.has_key?('$id')
          errors_hash['_$id'] = 'id should only be present in root schemas'
        end
      end

      self[:properties]&.each do |k,v|
        # check property $id
        regex = Regexp.new("\A\/properties\/\w+#{k}\z")
        if v[:$id]&.match(regex).nil?
          errors_hash["$id.#{k}"] = "$id in property #{k} needs to match #{regex}"
        end

        if CONDITIONAL_FIELDS.include?(v.class)
          if v.response_set.nil?
            errors_hash["response_set.#{k}"] = 'response set is not present'
          end
        else
          if v.dependent_conditions.size > 0
            errors_hash["conditionals.#{k}"] = "only the following fields can have conditionals (#{SchemaForm::Form::CONDITIONAL_FIELDS.map{|name| name.name.demodulize}.join(', ')})"
          end
        end
      end

      
      errors_hash
    end

    ##############
    ###METHODS####
    ##############

    def add_conditional_property(property_id, on_property, definition, type, value, &block)
      self[:allOf] ||= []

      cond_path = case type
      when :const
        [:const]
      when :not_const
        [:not, :const]
      when :enum
        [:enum]
      when :not_enum
        [:not, :enum]
      end

      condition = self[:allOf].find do |condition|
        condition.dig(:if, on_property, *cond_path) == value
      end

      if condition
        condition[:then].append_property(property_id, definition)
        yield(condition[:then]) if block_given?
      else
        condition = {
          if: {
            :"#{on_property}" => SuperHash::Utils.bury({}, *cond_path, value)
          },
          then: {
            properties: {
              :"#{property_id}" => definition
            }
          }
        }
        self[:allOf] = (self[:allOf] || []).push(condition)
        yield(self[:allOf].last[:then]) if block_given?
      end

    end

    def compile!
      #compile root level properties
      self[:properties]&.each do |id, definition|
        definition.compile! if definition&.respond_to?(:compile!)
      end

      #compile dynamic properties
      self.get_all_of_subschemas.each{|form| form.compile!}

      self
    end

    # ToDo check if is_inspection 
    def max_score(&block)
      self[:properties].inject(nil) do |acum, (name, field_def)|
        max_score_for_path = max_score_for_path(name, field_def, &block)
        if max_score_for_path.nil?
          acum
        else
          acum.to_f + max_score_for_path
        end
      end
    end

    def max_score_for_path(name, field, &block)

      if CONDITIONAL_FIELDS.include? field.class
    
        possible_values = case field
        when SchemaForm::Field::Select
          field.response_set[:anyOf].map do |obj|
            {value: obj[:const], score: obj[:score]}
          end
        when SchemaForm::Field::Switch
          [{value: true, score: 1}, {value: false, score: 0}]
        when SchemaForm::Field::NumberInput
          values = []
          field.dependent_conditions.each do |condition|
            condition_value = condition[:if][:properties].values[0]

            value = if !condition_value[:not].nil?
               'BP8;x&/dTF2Qn[RG' #some very random text
              else
                condition_value[:const]
              end
        
            values.push({value: value, score: nil})            
          end
          values
        end
    
        possible_values&.map do |possible_value|
          dependent_conditions = field.dependent_conditions_for_value({"#{name}" => possible_value[:value]}, &block)
          sub_schemas_max_score = dependent_conditions.inject(nil) do |acum, condition|
            max_score = condition[:then]&.max_score(&block)
            if max_score.nil?
              acum
            else
              acum.to_f + max_score
            end
          end
          if sub_schemas_max_score.nil?
            possible_value[:score]
          else
            possible_value[:score].to_f + sub_schemas_max_score
          end
        end&.compact&.max
    
      elsif SCORABLE_FIELDS.include? field.class
        field.max_score
      else
        nil
      end
    end

    def valid_for_locale?(locale = :es)
      all_properties_are_valid = self.merged_properties.find do |k,v|
        !v.is_a?(SchemaForm::Field::Component) && (v.valid_for_locale?(locale) == false)
      end.nil?
      all_response_sets_are_valid = self.response_sets.find do |k,v|
        v.valid_for_locale?(locale) == false
      end.nil?
      all_properties_are_valid && all_response_sets_are_valid
    end

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

    ###########################
    ###COMPONENT MANAGEMENT####
    ###########################

    def component_definitions
      self[:definitions].select do |k,v|
        !v.key?(:type)
      end
    end

    ##############################
    ###RESPONSE SET MANAGEMENT####
    ##############################

    # get responseSets #ToDo this can be improved
    def response_sets
      self[:definitions].select do |k,v|
        v[:type] == 'string' #v.key?('anyOf')
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

    def prepend_property(id, definition)
      new_definition = {}.merge(definition)
      new_definition[:displayProperties][:sort] = -1
      add_property(id, new_definition)
      resort!
    end

    def append_property(id, definition)
      new_definition = {}.merge(definition)
      new_definition[:displayProperties][:sort] = max_sort + 1
      add_property(id, new_definition)
      resort!
    end

    def insert_property_at_index(index, id, definition)
      new_definition = {}.merge(definition)
      new_definition[:displayProperties][:sort] = index - 0.5
      add_property(id, new_definition)
      resort!
    end

    def move_property(target, id)
      prop = self[:properties].find{|k,v| v.key_name == id.to_sym}
      if !prop.nil?
        current = prop[1][:displayProperties][:sort]
        r = Range.new(*[current, target].sort)
        selected = sorted_properties.select{|k| r.include?(k[:displayProperties][:sort]) }
        if target > current
          selected.each{|k| k[:displayProperties][:sort] -= 1 }
        else
          selected.each{|k| k[:displayProperties][:sort] += 1 }
        end
        prop[1][:displayProperties][:sort] = target
        resort!
      end
    end

    ###sorting###

    def min_sort
      self[:properties].map{|k,v| v&.dig(:displayProperties, :sort) }&.min || 0
    end

    def max_sort
      self[:properties].map{|k,v| v&.dig(:displayProperties, :sort) }&.max || 0
    end

    def property_at_sort(i)
      self[:properties].find{|k,v| v&.dig(:displayProperties, :sort) == i}
    end

    def verify_sort_order
      for i in 0...self[:properties].size
        return false if property_at_sort(i).blank?
      end
      true
    end

    def sorted_properties
      self[:properties].values.sort_by{|v| v&.dig(:displayProperties, :sort)}
    end

    def resort!
      # sorted = sorted_properties
      # for i in 0...self[:properties].size
      #   sort = [min_sort, i].max
      #   property = sorted[i]
      #   property[:displayProperties][:sort] = i
      # end
    end

  end
end