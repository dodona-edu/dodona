/* globals ace */
function init_submission_show() {
    function init() {
        initCodeLinks();
    }

    function initCodeLinks() {
        $("span.source-link").click(function () {
            $(".feedback-table .nav-tabs > li a").filter(function () {
                return $(this).attr("href").indexOf("#code") == 0;
            }).tab('show');
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
