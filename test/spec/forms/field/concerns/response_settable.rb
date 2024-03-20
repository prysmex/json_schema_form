# frozen_string_literal: true

require_relative 'field_example_helpers'

module ResponseSettableTests

  include FieldExampleHelpers

  # response_set_id and response_set_id=

  def test_response_set_id
    example = tested_klass_example
    instance = tested_klass.new(example)

    refute_equal '#/$defs/h12jb3k', instance.response_set_id
    instance.response_set_id = 'h12jb3k'

    assert_equal '#/$defs/h12jb3k', instance.response_set_id
  end

  # response_set

  def test_returns_nil_when_no_response_set
    example = tested_klass_example
    instance = tested_klass.new(example)

    assert_nil instance.response_set
  end

  def test_response_set
    klass_example = tested_klass_example
    prop = nil
    JSF::Forms::FormBuilder.build do
      add_response_set(:sdfuio, example('response_set'))
      prop = append_property(:testprop, klass_example).tap do |field|
        field.response_set_id = :sdfuio
      end
    end

    refute_nil prop.response_set
  end

  # i18n_value

  def test_i18n_value
    klass_example = tested_klass_example
    prop = nil

    JSF::Forms::FormBuilder.build do
      add_response_set(:jsdflkj3, example('response_set')).tap do |response_set|
        response_set.add_response(example('response')).tap do |r|
          r[:const] = 'test'
          r[:displayProperties] = { i18n: { es: 'score_1_es' } }
        end
      end

      prop = append_property(:testprop, klass_example).tap do |field|
        field.response_set_id = :jsdflkj3
      end
    end

    assert_equal 'score_1_es', prop.i18n_value('test', :es)
  end

  def test_scored?
    klass_example = tested_klass_example
    prop = nil
    response = nil

    JSF::Forms::FormBuilder.build do
      add_response_set(:jsdflkj3, example('response_set')).tap do |response_set|
        response_set.add_response(example('response')).tap do |r|
          response = r
          r[:const] = 'test'
          r[:displayProperties] = { i18n: { es: 'score_1_es' } }
        end
      end

      prop = append_property(:testprop, klass_example).tap do |field|
        field.response_set_id = :jsdflkj3
      end
    end

    assert_equal false, prop.scored?
    response[:score] = 1

    assert_equal true, prop.scored?
  end

end