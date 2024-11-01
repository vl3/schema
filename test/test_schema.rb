# frozen_string_literal: true

require "test_helper"
require "minitest/autorun"

class TestSchema < Minitest::Test
  def setup
    @schema = Schema::Schema.new({
      name: { type: "String", required: true, min_length: 2, max_length: 50 },
      age: { type: "Integer", required: true, min: 0, max: 120 },
      email: { type: "String", required: true },
      address: {
        type: "Hash",
        required: true,
        nested: {
          street: { type: "String", required: true },
          city: { type: "String", required: true },
          zip: { type: "String", required: true, min_length: 5, max_length: 10 }
        }
      },
      hobbies: {
        type: "Array",
        array: {
          type: "String",
          min_length: 2
        }
      }
    })

    @valid_data = {
      name: "John Doe",
      age: 30,
      email: "john@example.com",
      address: {
        street: "123 Main St",
        city: "Anytown",
        zip: "12345"
      },
      hobbies: %w[reading cycling photography]
    }

    @invalid_data = {
      name: "J",
      age: 150,
      email: nil,
      address: {
        street: "456 Elm St",
        city: "Somewhere"
      },
      hobbies: ["reading", "x"]
    }
  end

  def test_valid_data
    errors = @schema.validate(@valid_data)
    assert_empty errors, "Expected no errors for valid data"
  end

  def test_invalid_data
    errors = @schema.validate(@invalid_data)
    assert_equal 7, errors.size, "Expected 7 errors for invalid data"

    assert_includes errors, "name must be at least 2 characters long"
    assert_includes errors, "age must be at most 120"
    assert_includes errors, "email is required"
    assert_includes errors, "address.zip is required"
    assert_includes errors, "address.zip must be a String"
    assert_includes errors, "hobbies.1.item must be at least 2 characters long"
  end

  def test_nested_object_validation
    data = @valid_data.dup
    data[:address][:zip] = "1234"
    errors = @schema.validate(data)
    assert_equal 1, errors.size
    assert_includes errors, "address.zip must be at least 5 characters long"
  end

  def test_array_validation
    data = @valid_data.dup
    data[:hobbies] = ["a", "reading", ""]
    errors = @schema.validate(data)
    assert_equal 2, errors.size
    assert_includes errors, "hobbies.0.item must be at least 2 characters long"
    assert_includes errors, "hobbies.2.item must be at least 2 characters long"
  end

  def test_missing_required_nested_field
    data = @valid_data.dup
    data[:address].delete(:city)
    errors = @schema.validate(data)
    assert_equal 2, errors.size
    assert_includes errors, "address.city is required"
    assert_includes errors, "address.city must be a String"
  end

  def test_invalid_type
    data = @valid_data.dup
    data[:age] = "thirty"
    errors = @schema.validate(data)
    assert_equal 1, errors.size
    assert_includes errors, "age must be a Integer"
  end
end

