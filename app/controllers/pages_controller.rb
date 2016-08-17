class PagesController < ApplicationController
  def home
    @title = 'Home'
  end

  def precourse
    @title = 'Precourse'
    @exercises = {
      'Lecture 1': [[53, 46, 52, 43, 25, 57], [45, 40, 37, 39]]
    }
  end
end
