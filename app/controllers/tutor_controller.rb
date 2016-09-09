class TutorController < ApplicationController

    DATA_DIR = Rails.root.join('tmp', 'tutor').freeze

    def index
    end

    def show
        submission = Submission.find(params[:submission_id])
        authorize submission

        file = File.join(DATA_DIR, params[:submission_id] + '-' + params[:id])
        f = File.new(file, "w")
        f.write(submission.code)
        f.write("\n")
        f.write("echo('I am Dieter')")
        f.close

        codefile = file
        @json_traceback = `node --expose-debug-as=Debug ~/jslogger.js --jsondump=true #{codefile}`
          .strip
          .gsub!('\\n', '\\\\\\n')
          .gsub!("\"", "\\\"")
          .gsub!("\'", "\\\\\'")
          .html_safe

        @json_traceback = ('"' + @json_traceback + '"').html_safe

        render layout: false
        File.delete(file)
    end
end