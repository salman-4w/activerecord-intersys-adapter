require "helper"

class BasicsIntegrationTest < MiniTest::Unit::TestCase
  def test_find
    ms = Person.create! MICHAEL
    assert_equal ms, Person.find(ms)
  end

  def find_by_dynamic_attribute
    ds = Person.create! DWIGHT
    assert_equal ds, Person.find_by_last_name(ds.last_name)
  end

  def test_save
    ms = Person.create! MICHAEL
    ms.first_name = "Janice"
    ms.save
    assert_equal "Janice", Person.find(ms).first_name
  end

  def test_attributes_with_select_scope
    dmi = Company.create! DMI
    new_dmi = Company.find(dmi)
    assert_equal dmi.id, new_dmi.id, "accurate id attr"
    assert_equal dmi.name, new_dmi.name, "accurate name attr"
    assert_equal dmi.street_address, new_dmi.street_address, "accurate street_name attr"
  end

  def test_update_attribute
    pam = Person.new PAM
    pam.save
    pam.update_attribute :last_name, "Beesly"
    assert_equal "Beesly", Person.where(id: pam).first.last_name
  end

  def test_update_attributes
    creed = Person.create CREED
    creed.update_attributes age: 61, weight: 199
    creed.reload
    assert_equal 61, creed.age
    assert creed.age.is_a? Integer
    assert_equal 199, creed.weight
    assert creed.weight.is_a? Float
  end

  def test_cache_instance_method_call
    creed = Person.create CREED
    assert_equal 65, creed.age_plus(5)
    assert_equal "Hello Newman", Person.new.hello("Newman")
  end

  # TODO - get class methods working
  # def test_cache_class_method_call
  #   assert_equal 45.5, Person.average_age
  # end

  def teardown
    [Job, Comment, Company, Person].each { |klass| klass.delete_all }
  end
end
