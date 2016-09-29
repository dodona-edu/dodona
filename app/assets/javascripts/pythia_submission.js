function init_pythia_submission_show(submissionCode) {
    var vars;

    function init() {  
      $('.tutorlink').click(function() {
        var $element = $(this).parents(".group");
        var stdin = $element.data('stdin').slice(0, -1);
        var statements = $element.data('statements');
        loadTutor(submissionCode, statements, JSON.stringify(stdin.split('\n')));
        return false;
      })
    };

    function loadTutor(studentCode, statements, stdin) {
        var lines = studentCode.split('\n');
        //find and remove main
        var i = 0;
        var remove = false;
        var source_array = [];
        while ( i < lines.length) {
          if (remove && !(lines[i].match(/\s+.*/g))) {
            remove = false;
          }

          if (lines[i].match(/if\s+__name__\s*==\s*(['"])__main__\s*\1:\s*/g)) {
            remove = true;
          }
          if (!remove) {
            source_array.push(lines[i]);
          }
          i += 1;
        }

        source_array.push(statements);

        var source_code = source_array.join('\n');

        $.ajax({
              type: 'POST',
              url: 'http://localhost:8080/cgi-bin/build_trace.py',
              dataType: 'json',
              data: {code: source_code, input: stdin},
              success: function(data) {
                  createTutor(data);
              },
              error: function(data) {
                  $('<div style="display:none" class="alert alert-danger alert-dismissible"> <button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>' + I18n.t("js.tutor-failed") + '</div>').insertBefore(".feedback-table").show("fast");
              }
          });

          var createTutor = function(codeTrace) {
            showInfoModal("Python Tutor", '<iframe id="tutorviz" height="600px" width="100%" frameBorder="0" src="/tutorviz/tutorviz.html"></iframe>');

            $("#tutor #info-modal").on("shown.bs.modal", function(e) {
              $("#tutorviz").get(0).contentWindow.load(codeTrace);
            });
          }
    }

    init();
}
