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

export function initVisibilityCheckboxes(element: HTMLElement): void {
    initTotalVisibilityCheckboxes(element);
    initItemVisibilityCheckboxes(element);
}
