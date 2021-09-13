import { logToGoogle } from "util.js";

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
            const tab = button.parents(".feedback-tab-pane");
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
        $("a.tab-link").on("click", function () {
            const tab = $(this).data("tab") || "code";
            const element = $(this).data("element");
            const line = $(this).data("line");

            $(".tab-link-marker").removeClass("tab-link-marker");
            $(".feedback-table .nav-tabs > li a").filter(function () {
                return $(this).attr("href").startsWith(`#tab-${tab}`);
            }).tab("show");
            if (element !== undefined) {
                $("#element").addClass("tab-link-marker");
            }
            if (line !== undefined) {
                dodona.codeListing.clearHighlights();
                dodona.codeListing.highlightLine(line, true);
            }
            return false;
        });
    }

    init();
}

function contextualizeMediaPaths(parentClass, exercisePath, token) {
    const tokenPart = token ? `?token=${token}` : "";
    const query = "a[href^='media'],a[href^='./media']";
    Array.from(document.getElementsByClassName(parentClass)).forEach(parent => {
        parent.querySelectorAll(query).forEach(element => {
            Array.from(element.attributes).forEach(attribute => {
                if (attribute.name == "href") {
                    const value = attribute.value;
                    if (value.startsWith("./media/")) {
                        attribute.value = exercisePath + "/media/" +
                            value.substr(8) + tokenPart;
                    } else if (value.startsWith("media/")) {
                        attribute.value = exercisePath + "/media/" +
                            value.substr(6) + tokenPart;
                    }
                }
            });
        });
    });
}

export { initSubmissionShow };
