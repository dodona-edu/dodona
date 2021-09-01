# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint           not null, primary key
#  user_id      :bigint
#  token_digest :string(255)
#  description  :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'test_helper'

class ApiTokenTest < ActiveSupport::TestCase
  setup do
    @api_token = create :api_token
    @token = @api_token.token
  end

  test 'api token creation' do
    assert_not_nil @api_token
    assert @api_token.token.length > 30
    assert_not_nil @api_token.token_digest
    assert_equal ApiToken.digest(@token), @api_token.token_digest
  end

  test 'api token find_token should find' do
    found = ApiToken.find_token(@token)
    assert_equal @api_token, found
  end

  test 'new token should not find anything' do
    new_token = SecureRandom.urlsafe_base64(32)
    assert_nil ApiToken.find_token(new_token)
  end

  test 'empty token should not find anything' do
    assert_nil ApiToken.find_token('')
    assert_nil ApiToken.find_token(nil)
  end

  test 'token from database should only have digest' do
    found = ApiToken.find_token(@token)
    assert_nil found.token
    assert_not_nil found.token_digest
  end
end
