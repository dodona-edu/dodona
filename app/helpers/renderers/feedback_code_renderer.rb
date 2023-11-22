class FeedbackCodeRenderer
  require 'json'
  include Rails.application.routes.url_helpers

  @instances = 0

  class << self
    attr_accessor :instances
  end

  def initialize(code, programming_language)
    @code = code
    @programming_language = programming_language
    @builder = Builder::XmlMarkup.new
    self.class.instances += 1
    @instance = self.class.instances
  end

  def add_code
    @builder.div(class: 'code-listing-container') do
      parse
      # Only display copy button when the submission is not empty
      if @code.present?
        # Not possible to use clipboard_button_for here since the behaviour is different.
        @builder.button(class: 'btn btn-icon copy-btn', id: "copy-to-clipboard-#{@instance}", title: I18n.t('js.code.copy-to-clipboard'), 'data-bs-toggle': 'tooltip', 'data-bs-placement': 'top') do
          @builder.i(class: 'mdi mdi-clipboard-outline') {}
        end
      end
      @builder.script(type: 'application/javascript') do
        @builder << <<~HEREDOC
          window.dodona.ready.then(() => {
            window.dodona.attachClipboard("#copy-to-clipboard-#{@instance}", #{@code.to_json});
          });
        HEREDOC
      end
    end
    self
  end

  def parse
    line_formatter = Rouge::Formatters::HTML.new
    table_formatter = Rouge::Formatters::HTMLLineTable.new line_formatter, table_class: 'code-listing highlighter-rouge'

    lexer = (Rouge::Lexer.find(@programming_language) || Rouge::Lexers::PlainText).new
    lexed_c = lexer.lex(@code.encode(universal_newline: true))
    @builder << table_formatter.format(lexed_c)
    self
  end

  def add_messages(submission, messages, user)
    user_is_student = !user.course_admin?(submission.course)
    user_perm = if user_is_student
                  QuestionPolicy.new(user, Question.new(submission: submission, user: user)).create?
                else
                  AnnotationPolicy.new(user, Annotation.new(submission: submission, user: user)).create?
                end
    user_is_owner = submission.user == user

    @builder.tag!('d-annotation-options') {}

    @builder.script(type: 'application/javascript') do
      @builder << <<~HEREDOC
        window.dodona.ready.then(() => {
          window.dodona.codeListing.initAnnotations(#{submission.id}, #{submission.course_id.to_json}, #{submission.exercise_id}, #{user.id}, #{@code.to_json}, #{user_is_student}, #{user_is_owner});
          window.dodona.codeListing.addMachineAnnotations(#{messages.to_json});
          #{'window.dodona.codeListing.initAnnotateButtons();' if user_perm}
          #{'window.dodona.codeListing.loadUserAnnotations();' if submission.annotated? || (!user_is_student && submission.annotations.any?)}
        });
      HEREDOC
    end
    self
  end

  def html
    @builder.html_safe
  end
end
