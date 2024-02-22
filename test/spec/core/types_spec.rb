require 'test_helper'

class TypesTest < Minitest::Test
  ###########
  #arrayable#
  ###########

  # no tests needed

  #############
  #booleanable#
  #############

  # no tests needed

  ##########
  #nullable#
  ##########

  # no tests needed

  ############
  #numberable#
  ############

  # no tests needed

  ############
  #objectable#
  ############

  # add_property
  def test_add_property
    instance = JSF::Schema.new()
    instance.add_property('prop1', {type: 'string'})
    assert_instance_of JSF::Schema, instance.dig(:properties, :prop1)
  end

  def test_add_required_property
    instance = JSF::Schema.new()
    instance.add_property('prop1', {type: 'string'}, {required: true})
    assert_instance_of JSF::Schema, instance.dig(:properties, :prop1)
  end

  # remove_property
  def test_remove_property
    instance = JSF::Schema.new({properties: {prop1: {}}})
    instance.remove_property('prop1')
    assert_equal 0, instance[:properties].size
  end

  # add_def
  def test_add_def
    instance = JSF::Schema.new()
    instance.add_def('prop1', {type: 'string'})
    assert_instance_of JSF::Schema, instance.dig(:$defs, :prop1)
  end

  # remove_def
  def test_remove_def
    instance = JSF::Schema.new({:$defs => {prop1: {}}})
    instance.remove_def('prop1')
    assert_equal 0, instance[:$defs].size
  end

  # add_required
  def test_add_required
    instance = JSF::Schema.new()
    instance.add_required(:prop1)
    assert_equal 'prop1', instance[:required].first
  end

  # remove_required
  def test_remove_required
    instance = JSF::Schema.new()
    assert_nil instance[:required]
    instance.add_required(:prop1)
    instance.remove_required(:prop1)
    assert_nil instance[:required].first
  end

  ############
  #stringable#
  ############

  # no tests needed
end