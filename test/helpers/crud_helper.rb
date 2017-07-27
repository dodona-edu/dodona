module CRUDHelper
  def model_name
    model.to_s.downcase
  end

  def model_sym
    model_name.to_sym
  end

  def model_params(attrs)
    {
      model_sym => attrs
    }
  end

  # Generates a hash which maps attribute names on valid
  # attribute values using the model's factory.
  def generate_attrs
    build(model_sym).attributes.symbolize_keys.slice(*allowed_attrs)
  end

  # Generates attributes from the model factory, then checks whether
  # given block produces an object that has these attributes set.
  def assert_produces_object_with_attributes
    attrs = generate_attrs
    obj = yield attrs
    check_attrs(attrs, obj)
  end

  # Checks wether the attributes of the given object are equal
  # to the values of the given attr_hash
  def check_attrs(attr_hash, obj)
    attr_hash.each do |attr_name, value|
      assert_equal value, obj.send(attr_name)
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

  def post_create(attrs: nil)
    attrs ||= generate_attrs
    post polymorphic_url(model), params: model_params(attrs)
  end

  def should_create
    assert_difference("#{model}.count", +1) do
      post_create
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
      patch polymorphic_url(@instance), params: model_params(attr_hash)
      @instance.reload
    end
  end

  def should_destroy
    assert_difference("#{model}.count", -1) do
      delete polymorphic_url(@instance)
    end
  end
end

module CRUDTest
  def test_crud_actions(model, options = {})
    model_name = model.to_s.downcase

    attrs = options[:attrs] || {}

    actions = options[:only] || %i[index new create show edit update destroy]
    except = options[:except] || []
    actions -= except

    include(CRUDHelper)

    define_method(:model) do
      model
    end

    define_method(:allowed_attrs) do
      attrs
    end
     p actions

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
