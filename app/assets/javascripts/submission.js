function loadResultEditor(programmingLanguage, annotations) {
    var editor = ace.edit("editor-result");
    editor.getSession().setMode("ace/mode/" + programmingLanguage);
    editor.setOptions({
        showPrintMargin: false,
        maxLines: Infinity,
        readOnly: true,
        highlightActiveLine: false,
        highlightGutterLine: false
    });
    editor.renderer.$cursorLayer.element.style.opacity=0;
    editor.commands.commmandKeyBinding={};
    editor.getSession().setUseWrapMode(true);
    editor.$blockScrolling = Infinity; // disable warning
    $("#editor-result .ace_content").click(function () {
        editor.getSelection().selectAll();
    });
    if (annotations) {
        editor.session.setAnnotations(annotations);
    }
}

function initTutor(code) {
  $(".tutorlink").each(function() {
    $(this).click(function() {
      var stdin = $(this).attr('data-stdin').slice(0, -1);
      var statements = $(this).attr('data-statements')
      loadTutor(code, statements, JSON.stringify(stdin.split('\n')))
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

      //var codeTrace = JSON.parse(<%= @json_traceback %>);

      var createTutor = function(codeTrace) {
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
      }
}
