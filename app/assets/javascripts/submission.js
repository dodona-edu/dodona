/* globals ace */
function init_submission_show() {
    function init() {
        initTabLinks();
    }

    function initTabLinks() {
        $("a.tab-link").click(function () {
            var tab = $(this).data("tab") || "code";
            var element = $(this).data("element");
            var line = $(this).data("line");

            $(".tab-link-marker").removeClass("tab-link-marker");
            $(".feedback-table .nav-tabs > li a").filter(function () {
                return $(this).attr("href").indexOf("#" + tab) === 0;
            }).tab('show');
            if (element !== undefined) {
                $("#element").addClass("tab-link-marker");
            }
            if (line !== undefined) {
                var Range = ace.require('ace/range').Range;
                var editor = ace.edit("editor-result");
                editor.getSession().addMarker(new Range(line - 1, 0, line, 0), "ace_active-line tab-link-marker", "line");
            }
            return false;
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
