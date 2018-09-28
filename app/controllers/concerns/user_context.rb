class UserContext
  attr_reader :user, :ip

  def initialize(user, ip)
    @user = user
    @ip = ip
  end
end
