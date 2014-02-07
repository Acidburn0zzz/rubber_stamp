FactoryGirl.define do
  factory :parent_resource do
    r_boolean true
    r_date Date.today
    r_datetime DateTime.now
    r_decimal 3.14
    r_float 3.14
    r_integer 3
    r_string "my string"
    r_text "my text"
    r_time Time.now

    factory :parent_with_children do
        ignore do
            children_count 3
        end

        before(:create) do |parent, evaluator|
            create_list(:child_resource, evaluator.children_count, parent_resource: parent)
        end
    end

    factory :parent_with_grand_children do
        ignore do
            children_count 3
        end

        before(:create) do |parent, evaluator|
            create_list(:child_with_grand_children, evaluator.children_count,
                parent_resource: parent)
        end
    end

    initialize_with { ParentResource.create_with_version(attribute_lists) }

  end
end
