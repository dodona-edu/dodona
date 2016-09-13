class TutorController < ApplicationController

    def index
        submission = Submission.find(params[:submission_id])
        authorize submission

        #"def f():\n    return 2\n\ndef g():\n    return 3\n\nd = dict()\nd['a'] = ['1', '2', '3']\n"
        @tutor_code = submission.code.strip
                          .gsub("\n", '\\n')
                          .gsub("\"", "\\\"")
                          .gsub("\'", "\\\\\'")
                          .html_safe

        @tutor_code = '"' + @tutor_code + '"'
        @tutor_code = @tutor_code.html_safe

        #Get test case code
        @tutor_input = '["1", "2"]'.strip()
                          .gsub("\"", "\\\"")
                          .gsub("\'", "\\\\\'").html_safe
        @tutor_input = '"' + @tutor_input + '"'
        @tutor_input = @tutor_input.html_safe
    end
end