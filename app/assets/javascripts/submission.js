function initSubmissionShow() {
    function init() {
        initDiffSwitchButtons();
    }

    function initDiffSwitchButtons() {
        const buttons = $(".diff-switch-buttons .btn");
        buttons.click(e => {
            const button = $(e.target);
            const tab = button.parents(".tab-pane");
            buttons.removeClass("active");
            button.addClass("active");
            const diffs = tab.find(".diffs");
            diffs.removeClass("show-split");
            diffs.removeClass("show-unified");
            diffs.addClass(button.data("show_class"));
        });
    }

    init();
}

function loadResultEditor(programmingLanguage, annotations) {
    let editor = ace.edit("editor-result");
    editor.getSession().setMode("ace/mode/" + programmingLanguage);
    editor.setOptions({
        showPrintMargin: false,
        maxLines: Infinity,
        readOnly: true,
        highlightActiveLine: false,
        highlightGutterLine: false,
    });
    editor.renderer.$cursorLayer.element.style.opacity = 0;
    editor.commands.commmandKeyBinding = {};
    editor.getSession().setUseWrapMode(true);
    editor.$blockScrolling = Infinity; // disable warning
    $("#editor-result .ace_content").click(function () {
        editor.getSelection().selectAll();
    });
    if (annotations) {
        editor.session.setAnnotations(annotations);
    }
}

export {initSubmissionShow, loadResultEditor};
