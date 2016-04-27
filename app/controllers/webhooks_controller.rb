require 'set'

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update_exercises
    commits = params['commits']

    #Build set with all exercises that need to be updated
    changed = Set.new
    for commit in commits
        ['added', 'removed', 'modified'].each { |type| changed |= commit[type].map {|filename| filename.split('/')[0]}}
    end

    response = Exercise.refresh(changed)
    message = response[1]
    status = response[0] == 0 ? 200 : 500
    render plain: message, status: status
  end

  def test_page
    @title = 'webhook request'
  end
end
