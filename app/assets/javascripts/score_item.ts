import { fetch } from "utilities";
import { i18n } from "i18n/i18n";
import { ScoreItemInputTable } from "components/input_table";

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
                    new dodona.Toast(i18n.t("js.score_item.error"));
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

            evaluation_exercise: {

                visible_score: checked
            }
        };
    });
}

function initItemVisibilityCheckboxes(element: HTMLElement): void {
    commonCheckboxInit(element, ".visibility-checkbox", checked => {
        return {

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

export function initEditButton(element: HTMLElement): void {
    const editBtn = element.querySelector(".edit-btn") as HTMLAnchorElement;
    const table = element.querySelector(".score-items-table") as HTMLTableElement;
    const form = element.querySelector("d-score-item-input-table") as ScoreItemInputTable;

    editBtn.addEventListener("click", event => {
        event.preventDefault();
        table.classList.add("d-none");
        editBtn.classList.add("d-none");
        form.classList.remove("d-none");
    });

    form.addEventListener("cancel", () => {
        table.classList.remove("d-none");
        editBtn.classList.remove("d-none");
        form.classList.add("d-none");
    });
}
