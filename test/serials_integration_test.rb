require "helper"

class SerialsIntegrationTest < MiniTest::Unit::TestCase
  def test_serial_object
    object = Person.new.ts
    assert_equal TimeStamp, object.class
    assert_equal Intersys::Serial::Object, object.class.superclass
  end

  def test_serial_attributes
    dwight = Person.create! DWIGHT
    date = Time.now
    revision = 3
    user = "Jim"
    # set em up
    dwight.ts.create_date = date
    dwight.ts.create_revision = revision
    dwight.ts.create_user = user
    assert dwight.save
    # knock em down
    new_dwight = Person.find(dwight)
    assert_equal Time, new_dwight.ts.create_date.class
    assert_equal date.to_s, new_dwight.ts.create_date.to_s
    assert_equal Fixnum, new_dwight.ts.create_revision.class
    assert_equal revision, new_dwight.ts.create_revision
    assert_equal String, new_dwight.ts.create_user.class
    assert_equal user, new_dwight.ts.create_user
  end

  def teardown
    Person.delete_all
  end
end
