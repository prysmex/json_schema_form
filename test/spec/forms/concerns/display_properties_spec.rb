require 'test_helper'

class DisplayPropertiesTest < Minitest::Test

  include TestHelper::SampleClassHooks

  # hidden? and hidden=

  def test_hidden
    SampleSchema.include(JSF::Forms::Concerns::DisplayProperties)
    instance = SampleSchema.new

    instance.hidden = false
    assert_equal false, instance.hidden?
    instance['displayProperties']['hidden'] = true
    assert_equal true, instance.hidden?
    instance.hidden = false
    assert_equal false, instance.hidden?
  end

  # hideOnCreate? and hideOnCreate=

  def test_hidden_on_create
    SampleSchema.include(JSF::Forms::Concerns::DisplayProperties)
    instance = SampleSchema.new

    instance.hideOnCreate = false
    assert_equal false, instance.hideOnCreate?
    instance['displayProperties']['hideOnCreate'] = true
    assert_equal true, instance.hideOnCreate?
    instance.hideOnCreate = false
    assert_equal false, instance.hideOnCreate?
  end

  # @Todo sort
  # def test_sort
  # end

  # i18n_label and set_label_for_locale
  
  def test_i18n_label
    SampleSchema.include(JSF::Forms::Concerns::DisplayProperties)
    instance = SampleSchema.new

    instance.set_label_for_locale('__some_label__')
    assert_equal '__some_label__', instance.i18n_label
  end

  def test_component
    SampleSchema.include(JSF::Forms::Concerns::DisplayProperties)
    instance = SampleSchema.new

    SuperHash::Utils.bury(instance, :displayProperties, :component, 'test')
    assert_equal 'test', instance.component
  end

end