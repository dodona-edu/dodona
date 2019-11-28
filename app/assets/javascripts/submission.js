import { logToGoogle } from "util.js";
import { contextualizeMediaPaths } from "exercise.js";

function initSubmissionShow(parentClass, mediaPath, token) {
    function init() {
        initDiffSwitchButtons();
        initTabLinks();
        initHideCorrect();
        contextualizeMediaPaths(parentClass, mediaPath, token);
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
                dodona.codeListing.clearHighlights();
                dodona.codeListing.highlightLine(line);
            }
            return false;
        });
    }

    init();
}

export { initSubmissionShow };
