module ResponseSettableTests

  include FieldHelpers

  # response_set_id and response_set_id=

  def test_response_set_id
    example = self.example_for_current_field_klass
    instance = field_klass.new(example)

    refute_equal '#/definitions/h12jb3k', instance.response_set_id
    instance.response_set_id = 'h12jb3k'
    assert_equal '#/definitions/h12jb3k', instance.response_set_id
  end

  # response_set
  
  def test_response_set
    name = self.underscored_klass_name
    prop = nil
    JSF::Forms::FormBuilder.build() do
      add_response_set(:sdfuio, example('response_set'))
      prop = append_property(:testprop, example(name)).tap do |field|
        field.response_set_id = :sdfuio
      end
    end

    refute_nil prop.response_set
  end

  # i18n_value

  def test_i18n_value
    klass_name = self.underscored_klass_name
    prop = nil

    JSF::Forms::FormBuilder.build() do
      add_response_set(:jsdflkj3, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :default)).tap do |r|
          r[:const] = 'test'
          r[:displayProperties] = { i18n: { es: "score_1_es" } }
        end
      end

      prop = append_property(:testprop, example(klass_name)).tap do |field|
        field.response_set_id = :jsdflkj3
      end
    end

    assert_equal 'score_1_es', prop.i18n_value('test', :es)
  end

end