class PagesController < ApplicationController
  def home
    @title = 'Home'
  end

  def precourse
    @title = 'Precourse'
    @exercises = [
      ['Lecture 1', [99, 94, 127, 139, 128, 104], [114, 138, 105, 97]],
      ['Lecture 2', [151, 174, 175, 154, 191, 161], [169, 149, 168, 185, 167]],
    ]
  end
end
