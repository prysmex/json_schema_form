#
# Some of the methods added by JSF::Forms::Field::Methods::Base may be overriden on a field class,
# for example, `valid_for_locale?`. If that is the case, those methods should also be overriden on the
# specific field specs file
#
module BaseMethodsTests

  include FieldExampleHelpers

  ##################
  ###VALIDATIONS####
  ##################

  # valid_for_locale?

  # overriden in Static, Switch, Slider
  def test_valid_for_locale
    example = self.tested_klass_example
    instance = tested_klass.new(example)

    instance.set_label_for_locale('opciones')
    assert_equal true, instance.valid_for_locale?

    instance.set_label_for_locale('')
    assert_equal false, instance.valid_for_locale?

    instance.set_label_for_locale(nil)
    assert_equal false, instance.valid_for_locale?

    assert_equal false, instance.valid_for_locale?(:random)
  end

  # validation_schema

  def test_no_unknown_keys_allowed
    refute_nil tested_klass.new({some_key: []}).errors[:some_key]
  end

  ##############
  ###METHODS####
  ##############

  # hidden? and hidden=

  def test_hidden
    example = self.tested_klass_example
    instance = tested_klass.new(example)

    assert_equal false, instance.hidden?
    instance['displayProperties']['hidden'] = true
    assert_equal true, instance.hidden?
    instance.hidden = false
    assert_equal false, instance.hidden?
  end

  # hideOnCreate? and hiddenOnCreate=

  def test_hidden_on_create
    example = self.tested_klass_example
    instance = tested_klass.new(example)

    assert_equal false, instance.hideOnCreate?
    instance['displayProperties']['hideOnCreate'] = true
    assert_equal true, instance.hideOnCreate?
    instance.hiddenOnCreate = false
    assert_equal false, instance.hideOnCreate?
  end

  # i18n_label and set_label_for_locale
  
  def test_i18n_label
    example = self.tested_klass_example
    instance = tested_klass.new(example)
    instance.set_label_for_locale('__some_label__')

    assert_equal '__some_label__', instance.i18n_label
  end

  # document_path
  # @Todo

  # compile!
  # @Todo

  # errors

  def test_errors_dont_raise_error
    tested_klass.new().errors
  end

end