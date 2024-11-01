# frozen_string_literal: true

require_relative "schema/version"

module Schema
  class Error < StandardError; end

  class Schema
    def initialize(schema)
      @schema = schema
    end

    def validate(data, path = [])
      errors = []
      @schema.each do |key, rules|
        value = data[key]
        current_path = path + [key]

        rules.each do |rule, rule_value|
          case rule
          when :type
            errors << "#{current_path.join(".")} must be a #{rule_value}" unless value.is_a?(Object.const_get(rule_value))
          when :required
            errors << "#{current_path.join(".")} is required" if rule_value && value.nil?
          when :min
            errors << "#{current_path.join(".")} must be at least #{rule_value}" if value.is_a?(Numeric) && value < rule_value
          when :max
            errors << "#{current_path.join(".")} must be at most #{rule_value}" if value.is_a?(Numeric) && value > rule_value
          when :min_length
            errors << "#{current_path.join(".")} must be at least #{rule_value} characters long" if value.is_a?(String) && value.length < rule_value
          when :max_length
            errors << "#{current_path.join(".")} must be at most #{rule_value} characters long" if value.is_a?(String) && value.length > rule_value
          when :nested
            if value.is_a?(Hash)
              nested_schema = Schema.new(rule_value)
              errors.concat(nested_schema.validate(value, current_path))
            else
              errors << "#{current_path.join(".")} must be a Hash for nested validation"
            end
          when :array
            if value.is_a?(Array)
              item_schema = Schema.new({ item: rule_value })
              value.each_with_index do |item, index|
                errors.concat(item_schema.validate({ item: item }, current_path + [index]))
              end
            else
              errors << "#{current_path.join(".")} must be an Array"
            end
          end
        end
      end
      errors
    end
  end
end

