class PagesController < ApplicationController
  def home
    @title = 'Home'
  end

  def precourse
    @title = 'Precourse'
    @exercises = [
      ['Lecture 1', [99, 94, 127, 139, 128, 104], [114, 138, 105, 97]],
      ['Lecture 2', [151, 174, 175, 155, 191, 161], [169, 149, 168, 185, 167]],
      ['Lecture 3', [197, 248, 247, 207, 198, 224], [220, 243, 249, 215]]
    ]
  end
end
