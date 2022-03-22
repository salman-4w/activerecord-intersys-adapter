require "helper"

class AdapterTest < MiniTest::Unit::TestCase
  def setup
    @connection = ActiveRecord::Base.connection
  end

  def test_namespace
    assert_equal "TEST", @connection.namespace
  end

  def test_package
    assert_equal "Test", @connection.package
  end

  def test_packaged_table
    assert_equal "Test.Account", @connection.packaged_table("Account")
    assert_equal "Test.Account", @connection.packaged_table("Test.Account")
  end

  def test_unpackaged_table
    assert_equal "Account", @connection.unpackaged_table("Test.Account")
    assert_equal "Account", @connection.unpackaged_table("Account")
    assert_equal "Account", @connection.unpackaged_table("Test.Name.Account")
  end

  def test_tables
    tables = @connection.tables
    assert tables.include?("Person"), "must have Person table"
    assert tables.include?("Comment"), "must have Comment table"
  end

  def test_columns
    columns = @connection.columns("Person")
    first_name = columns.find { |c| c.name == "first_name" }
    assert_equal :string, first_name.type

    active = columns.find { |c| c.name == "active" }
    assert_equal :boolean, active.type
    assert_equal true, active.default

    age = columns.find { |c| c.name == "age" }
    assert_equal :integer, age.type

    weight = columns.find { |c| c.name == "weight" }
    assert_equal :float, weight.type
  end

  def test_serial_columns
    assert_equal 1, @connection.serial_columns("Person").count
  end

  def test_stream_columns
    columns = @connection.stream_columns("Person")

    notes = columns.find { |c| c.name == "notes" }
    assert_equal :string, notes.type
  end

  def test_stream_column_attribute_class
    attribute = Person.new.notes
    assert attribute.is_a?(Intersys::Reflection::GlobalCharacterStream)
  end

  def test_exec_query_columns
    result = @connection.exec_query("select FirstName, Age, Active from test.person")
    %w(first_name age active).each { |i| assert result.columns.include? i }
  end
end
