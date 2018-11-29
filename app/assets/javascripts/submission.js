function initSubmissionShow() {
    let currentMarkerId;

    function init() {
        initDiffSwitchButtons();
        initTabLinks();
        initHideCorrect();
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

    function initHideCorrect() {
        const checkbox = $("#hideCorrect");
        checkbox.change(e => {
            if (e.target.checked) {
                $(".group.correct").hide();
            } else {
                $(".group.correct").show();
            }
        });
    }

    function initTabLinks() {
        $("a.tab-link").click(function () {
            const tab = $(this).data("tab") || "code";
            const element = $(this).data("element");
            const line = $(this).data("line");

            $(".tab-link-marker").removeClass("tab-link-marker");
            $(".feedback-table .nav-tabs > li a").filter(function () {
                return $(this).attr("href").indexOf("#" + tab) === 0;
            }).tab("show");
            if (element !== undefined) {
                $("#element").addClass("tab-link-marker");
            }
            if (line !== undefined) {
                const Range = ace.require("ace/range").Range;
                const editor = ace.edit("editor-result");
                if (typeof currentMarkerId !== "undefined") {
                    editor.getSession().removeMarker(currentMarkerId);
                }
                currentMarkerId = editor.getSession().addMarker(new Range(line - 1, 0, line, 0), "ace_active-line tab-link-marker", "line");
            }
            return false;
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
