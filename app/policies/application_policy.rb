class ApplicationPolicy
  attr_reader :user, :ip, :record

  def initialize(user, record)
    @user = user.user
    @ip = user.ip
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(id: record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def permits_attributes?(*attrs)
    attrs.all? { |e| permitted_attributes.include?(e) }
  end

  def permits_attribute?(attr)
    permits_attributes?(attr)
  end

  class Scope
    attr_reader :user, :ip, :scope

    def initialize(user, scope)
      @user = user.user
      @ip = user.ip
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
