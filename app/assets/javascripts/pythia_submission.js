function init_pythia_submission_show(submissionCode) {
    var vars;

    function init() {
      $(".tutorlink").each(function() {
        $(this).click(function() {
          var element = $(this).parents(".group")
          var stdin = element.attr('data-stdin').slice(0, -1);
          var statements = element.attr('data-statements')
          loadTutor(submissionCode, statements, JSON.stringify(stdin.split('\n')));
          return false;
        })
      })
    };

    function loadTutor(studentCode, statements, stdin) {
        var lines = studentCode.split('\n')
        //find and remove main
        var i = 0;
        remove = false
        source_code = ""
        while ( i < lines.length) {
          if (remove && !(lines[i].match(/\s+.*/g))) {
            remove = false
          }

          if (lines[i].match(/if\s+__name__\s*==\s*(['"])__main__\s*\1:\s*/g)) {
            remove = true
          }
          if (!remove) {
            source_code += lines[i] + '\n'
          }
          i += 1
        }

        source_code += "\n" + statements

        $.ajax({
              type: 'POST',
              url: 'http://localhost:8080/cgi-bin/build_trace.py',
              dataType: 'json',
              data: {code: source_code, input: stdin},
              success: function(data) {
                  createTutor(data)
              },
              error: function(data) {
                  console.log("An error occured building tutor traceback")
              }
          })

          var createTutor = function(codeTrace) {
            showInfoModal("Python Tutor", '<iframe id="tutorviz" height="600px" width="100%" frameBorder="0" src="/tutorviz/tutorviz.html"></iframe>')
            //showInfoModal("Python Tutor", '<div id="tutorelement"></div>', undefined)

            $("#tutor #info-modal").on("shown.bs.modal", function(e) {
              $("#tutorviz")[0].contentWindow.load(codeTrace);
            });
          }
    }

    init();
}
