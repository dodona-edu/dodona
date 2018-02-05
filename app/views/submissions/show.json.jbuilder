json.partial! 'submission_basic', submission: @submission
json.extract! @submission, :code, :result
