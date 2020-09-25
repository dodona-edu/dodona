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
        @builder.button(class: 'btn btn-default copy-btn', id: "copy-to-clipboard-#{@instance}", title: I18n.t('js.code.copy-to-clipboard'), 'data-toggle': 'tooltip', 'data-placement': 'top') do
          @builder.i(class: 'mdi mdi-clipboard-text mdi-18') {}
        end
      end
      @builder.script(type: 'application/javascript') do
        @builder << <<~HEREDOC
          $(() => {
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

    @builder.div(id: 'feedback-table-options', class: 'feedback-table-options') do
      if user_perm
        @builder.button(class: 'btn-text', id: 'add_global_annotation') do
          if user_is_student
            @builder.text!(I18n.t('submissions.show.questions.add_global'))
          else
            @builder.text!(I18n.t('submissions.show.annotations.add_global'))
          end
        end
      end

      @builder.span(class: 'flex-spacer') {}
      @builder.span(class: 'diff-switch-buttons switch-buttons hide', id: 'annotations_toggles') do
        @builder.span(id: 'diff-switch-prefix') do
          @builder.text!(I18n.t('submissions.show.annotations.title'))
        end
        @builder.div(class: 'btn-group btn-toggle', role: 'group', 'aria-label': I18n.t('submissions.show.annotations.title'), 'data-toggle': 'buttons') do
          @builder.button(class: 'btn btn-secondary annotation-toggle active', id: 'show_all_annotations', title: I18n.t('submissions.show.annotations.show_all'), 'data-toggle': 'tooltip', 'data-placement': 'top') do
            @builder.i(class: 'mdi mdi-18 mdi-comment-multiple-outline') {}
          end
          @builder.button(class: 'btn btn-secondary annotation-toggle', id: 'show_only_errors', title: I18n.t('submissions.show.annotations.show_errors'), 'data-toggle': 'tooltip', 'data-placement': 'top') do
            @builder.i(class: 'mdi mdi-18 mdi-comment-alert-outline') {}
          end
          @builder.button(class: 'btn btn-secondary annotation-toggle', id: 'hide_all_annotations', title: I18n.t('submissions.show.annotations.hide_all'), 'data-toggle': 'tooltip', 'data-placement': 'top') do
            @builder.i(class: 'mdi mdi-18 mdi-comment-remove-outline') {}
          end
        end
      end
    end

    @builder.div(id: 'feedback-table-global-annotations') do
      @builder.div(id: 'feedback-table-global-annotations-list') {}
    end

    @builder.script(type: 'application/javascript') do
      @builder << <<~HEREDOC
        window.dodona.afterInitialMathJaxTypeset.push(() => {
          window.dodona.codeListing = new window.dodona.codeListingClass(#{submission.id}, #{@code.to_json}, #{@code.lines.length}, #{user_is_student});
          window.dodona.codeListing.addMachineAnnotations(#{messages.map { |o| Hash[o.each_pair.to_a] }.to_json});
          #{'window.dodona.codeListing.initAnnotateButtons();' if user_perm}
          window.dodona.codeListing.loadUserAnnotations();
          window.dodona.codeListing.showAnnotations();
        });
      HEREDOC
    end
    self
  end

  def html
    @builder.html_safe
  end
end
