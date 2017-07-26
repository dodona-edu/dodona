module CRUDHelper
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

  def generate_attrs
    build(model_sym).attributes.symbolize_keys!.slice(*allowed_attrs)
  end

  # generates attributes from the model factory, then checks whether
  # given block produces an object that has these attributes set.
  def assert_produces_object_with_attributes
    attrs = generate_attrs
    obj = yield attrs
    check_attrs(attrs, obj)
  end

  def check_attrs(attrs, obj)
    attrs.each do |attr, value|
      assert_equal value, obj.send(attr)
    end
  end

  def should_get_index
    get polymorphic_url(model)
    assert_response :success
  end

  def should_get_new
    get new_polymorphic_url(model)
    assert_response :success
  end

  def should_create
    assert_difference(-> { model.count }, +1) do
      post polymorphic_url(model), model_params(generate_attrs)
    end
  end

  def should_set_attributes_on_create
    # TODO
  end

  def should_show
    get polymorphic_url(@instance)
    assert_response :success
  end

  def should_get_edit
    get edit_polymorphic_url(@instance)
    assert_response :success
  end

  def should_update
    assert_produces_object_with_attributes do |attr_hash|
      patch polymorphic_url(@instance), model_params(attr_hash)
      assert_redirected_to polymorphic_url(@instance)
      @instance.reload
    end
  end

  def should_destroy
    assert_difference(-> { model.count }, -1) do
      delete polymorphic_url(@instance)
    end

    assert_redirected_to polymorphic_url(model)
  end
end

module CRUDTest
  def test_crud_actions(model, options = {})
    model_name = model.to_s.downcase

    attrs = options[:attrs] || {}

    actions = options[:only] || %i[index show create edit destroy]
    except = options[:except] || []
    actions -= except

    include(CRUDHelper)

    define_method(:model) do
      model
    end

    define_method(:allowed_attrs) do
      attrs
    end

    # define appropriate tests
    actions.each do |action|
      case action
      when :index
        test('should get index') { should_get_index }
      when :new
        test('should get new') { should_get_new }
      when :create
        test("should create #{model_name}") { should_create }
      when :show
        test("should show #{model_name}") { should_show }
      when :edit
        test("should get edit #{model_name}") { should_get_edit }
      when :update
        test("should update #{model_name}") { should_update }
      when :destroy
        test("should destroy #{model_name}") { should_destroy }
      end
    end
  end
end
