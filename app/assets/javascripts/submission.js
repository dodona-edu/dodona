/* globals ace */
import { logToGoogle } from "util.js";

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
            const button = $(e.currentTarget);
            const tab = button.parents(".tab-pane");
            const tabButtons = tab.find(".diff-switch-buttons .btn");
            tabButtons.removeClass("active");
            button.addClass("active");
            const diffs = tab.find(".diffs");
            diffs.removeClass("show-split");
            diffs.removeClass("show-unified");
            diffs.addClass(button.data("show_class"));
            logToGoogle("feedback", "diff", button.data("show_class"));
        });
    }

    function initHideCorrect() {
        const buttons = $(".correct-switch-buttons .btn");
        buttons.click(e => {
            const button = $(e.currentTarget);
            const tab = button.parents(".tab-pane");
            const tabButtons = tab.find(".correct-switch-buttons .btn");
            tabButtons.removeClass("active");
            button.addClass("active");
            if (button.data("show")) {
                tab.find(".group.correct").show();
            } else {
                tab.find(".group.correct").hide();
            }
            logToGoogle("feedback", "correct", `${button.data("show")}`);
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
                currentMarkerId = editor.getSession().addMarker(new Range(line - 1, 0, line, 0), "ace_active-line tab-link-marker", "line", false);
            }
            return false;
        });
    }

    init();
}

function loadResultEditor(programmingLanguage, annotations) {
    const editor = ace.edit("editor-result");
    if (window.dodona.darkMode) {
        editor.setTheme("ace/theme/twilight");
    }
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
    if (annotations) {
        editor.session.setAnnotations(annotations);
    }
}

export { initSubmissionShow, loadResultEditor };
