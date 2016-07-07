require 'set'

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update_exercises
    # Build set with all exercises that need to be updated
    changed = Set.new
    if params.key?('commits')
      commits = params['commits']

      for commit in commits
        %w(added removed modified).each { |type| changed |= commit[type].map { |filename| filename.split('/').first } }
      end
    else
      changed.add('UPDATE_ALL')
    end

    response = Exercise.refresh(changed)
    message = response[1]
    status = response[0] == 0 ? 200 : 500
    render plain: message, status: status
  end

  def test_page
  end
end
