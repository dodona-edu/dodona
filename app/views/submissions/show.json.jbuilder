json.partial! 'submission_basic', submission: @submission
json.extract! @submission, :code
json.result @submission.safe_result(current_user)
