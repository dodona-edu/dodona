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
            showInfoModal("Python Tutor", '<div id="tutorelement"></div>', undefined)

            $("#tutor #info-modal").on("shown.bs.modal", function(e) {
              var visualizer = new ExecutionVisualizer('tutorelement', codeTrace,
                                                            {embeddedMode: false,
                                                             heightChangeCallback: redrawAllVisualizerArrows,
                                                             editCodeBaseURL: ''});

              function redrawAllVisualizerArrows() {
                  if (visualizer) visualizer.redrawConnectors();
              }
              // Call redrawConnectors() on all visualizers whenever the window is resized,
              // since HTML elements might have moved during a resize. The SVG arrows rendered
              // by jsPlumb don't automatically get re-drawn in their new positions unless
              // redrawConnectors() is called.
              $(window).resize(redrawAllVisualizerArrows);
              $('#tutorelement').scroll(redrawAllVisualizerArrows);
            });
          }
    }

    init();
}
