/* globals ace */
function init_submission_show() {
    function init() {
        initCodeLinks();
    }

    function initCodeLinks() {
        $("span.source-link").click(function () {
            var line = $(this).data("line");
            var Range = ace.require('ace/range').Range
            $(".feedback-table .nav-tabs > li a").filter(function () {
                return $(this).attr("href").indexOf("#code") == 0;
            }).tab('show');
            var editor = ace.edit("editor-result");
            editor.getSession().addMarker(new Range(line - 1, 0, line, 0), "ace_active-line line-marker", "line");
        });
    }

    init();
}

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
