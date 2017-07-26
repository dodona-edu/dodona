module CRUDHelper

  def self.model_name
    model.to_s.downcase
  end

  def model
    self.class.model
  end

  def model_name
    model.to_s.downcase
  end

  def model_sym
    model_name.to_sym
  end

  def model_params(attrs)
    {
      params: {
        model_sym => attrs
      }
    }
  end

  # generates attributes from the model factory, then checks whether
  # given block produces an object that has these attributes set.
  def assert_produces_object_with_attributes
    attrs = attributes_for(model_sym).slice(*allowed_attrs)
    obj = yield attrs
    check_attrs(attrs, obj)
  end

  def check_attrs(attrs, obj)
    attrs.each do |attr, value|
      assert_equal value, obj.send(attr)
    end
  end
end


module CRUDTest
  def crud_tests(model)
    model_name = model.to_s.downcase

    include(CRUDHelper)

    test 'should get index' do
      get polymorphic_url(model)
      assert_response :success
    end

    test 'should get new' do
      get new_polymorphic_url(model)
      assert_response :success
    end

    test "should show #{model_name}" do
      get polymorphic_url(@instance)
      assert_response :success
    end

    test "should get edit #{model_name}" do
      get edit_polymorphic_url(@instance)
      assert_response :success
    end

    test "should create #{model_name}" do
      assert_produces_object_with_attributes do |attrs|
        assert_difference(-> { model.count }, +1) do
          post polymorphic_url(model), model_params(attrs)
        end
        model.last
      end
    end

    test "should update #{model_name}" do
      assert_produces_object_with_attributes do |attrs|
        patch polymorphic_url(@instance), model_params(attrs)
        assert_redirected_to polymorphic_url(@instance)
        @instance.reload
      end
    end

    test "should destroy #{model_name}" do
      assert_difference(-> { model.count }, -1) do
        delete polymorphic_url(@instance)
      end

      assert_redirected_to polymorphic_url(model)
    end
  end
end
