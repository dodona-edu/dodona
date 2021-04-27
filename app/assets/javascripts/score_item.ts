import { fetch } from "util.js";

export function initInlineEditButton(tableElement: HTMLElement): void {
    tableElement.querySelectorAll(".edit-button").forEach(item => {
        item.addEventListener("click", e => {
            e.preventDefault();
            const clicked = (e.target as HTMLElement).closest("a") as HTMLAnchorElement;
            const scoreItemId = clicked.dataset.scoreItem;
            const row = document.getElementById(`form-row-${scoreItemId}`);
            if (row.classList.contains("hidden")) {
                row.classList.remove("hidden");
                clicked.innerHTML = "<i class='mdi mdi-close mdi-18' aria-hidden='true'></i>";
            } else {
                row.classList.add("hidden");
                clicked.innerHTML = "<i class='mdi mdi-pencil mdi-18' aria-hidden='true'></i>";
            }
        });
    });
}

function commonCheckboxInit(
    element: HTMLElement,
    selector: string,
    dataProvider: (checked: boolean) => Record<string, unknown>): void {
    element.querySelectorAll(selector).forEach(checkbox => {
        checkbox.addEventListener("change", async event => {
            event.preventDefault();
            const checkbox = event.target as HTMLInputElement;
            checkbox.disabled = true;
            const form = checkbox.closest("form") as HTMLFormElement;
            fetch(form.action, {
                method: "PATCH",
                headers: {
                    "Accept": "application/javascript",
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(dataProvider(checkbox.checked))
            }).then(async response => {
                if (response.ok) {
                    eval(await response.text());
                } else {
                    // Someone already deleted this score item.
                    new dodona.Toast(I18n.t("js.score_item.error"));
                    checkbox.disabled = false;
                    checkbox.checked = !checkbox.checked;
                }
            });
        });
    });
}

function initTotalVisibilityCheckboxes(element: HTMLElement): void {
    commonCheckboxInit(element, ".total-visibility-checkbox", checked => {
        return {
            // eslint-disable-next-line camelcase
            evaluation_exercise: {
                // eslint-disable-next-line camelcase
                visible_score: checked
            }
        };
    });
}

function initItemVisibilityCheckboxes(element: HTMLElement): void {
    commonCheckboxInit(element, ".visibility-checkbox", checked => {
        return {
            // eslint-disable-next-line camelcase
            score_item: {
                visible: checked
            }
        };
    });
}

export function initScoreItemPanels(): void {
    const $choicePanel = $("#choice-panel");
    const $itemPanel = $("#items-panel");

    function init(): void {
        initPanelLogic();
        // // Bootstrap's automatic collapsing of other elements in the parent breaks
        // // when doing manual shows and hides, so we have to do this.
        $choicePanel.find(".panel-collapse").on("show.bs.collapse", function () {
            $itemPanel.find(".panel-collapse").collapse("hide");
        });
        $itemPanel.find(".panel-collapse").on("show.bs.collapse", function () {
            $choicePanel.find(".panel-collapse").collapse("hide");
        });
    }

    function initPanelLogic(): void {
        $("#yes-grading").click(function () {
            $itemPanel.find(".step-circle").html("2");
            $(this)
                .closest(".panel")
                .find(".answer")
                .html($(this).data("answer"));
            $itemPanel.removeClass("hidden");
            $itemPanel.find(".panel-collapse").collapse("show");
            window.scrollTo(0, 0);
        });
    }

    init();
}

export function initVisibilityCheckboxes(element: HTMLElement): void {
    initTotalVisibilityCheckboxes(element);
    initItemVisibilityCheckboxes(element);
}
