class TutorController < ApplicationController

    def index
    end

    def show
        @submission = Submission.new
    end
end