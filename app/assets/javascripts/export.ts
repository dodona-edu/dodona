function initSelection(): void {
    const selectAll = document.querySelector("#check-all") as HTMLInputElement;
    const checkboxes = document.querySelectorAll(".selection-checkbox");
    const allSubmissionsInput = document.querySelector("#all_submissions") as HTMLInputElement;

    const errorWrapper = document.querySelector("#errors-wrapper");
    const choosePanel = document.querySelector("#choose-panel");
    const chooseOptionsPanel = document.querySelector("#choose-options-panel");

    const form = document.querySelector("#download_submissions") as HTMLFormElement;
    const defaultAction = form.action;

    function init(): void {
        initCheckboxes();
        initContinueButton();

        choosePanel.querySelector(".panel-collapse").addEventListener("show.bs.collapse", () => {
            chooseOptionsPanel.querySelector(".panel-collapse").classList.remove("show");
        });
        chooseOptionsPanel.querySelector(".panel-collapse").addEventListener("show.bs.collapse", () => {
            choosePanel.querySelector(".panel-collapse").classList.remove("show");
        });
    }

    function filteredCheckboxes(): HTMLInputElement[] {
        return (Array.from(checkboxes) as HTMLInputElement[]).filter(cb => cb.checked);
    }

    function initCheckboxes(): void {
        document.querySelectorAll(".selection-row").forEach(r => r.addEventListener("click", e => {
            const checkbox = e.currentTarget.querySelector("input[type=\"checkbox\"]");
            checkbox.checked = !checkbox.checked;
            checkbox.dispatchEvent(new Event("change"));
        }));

        checkboxes.forEach(cb => cb.addEventListener("click", e => e.stopPropagation()));

        checkboxes.forEach(cb => cb.addEventListener("change", () => {
            const amountChecked = filteredCheckboxes().length;
            selectAll.indeterminate = amountChecked && amountChecked !== checkboxes.length;
            selectAll.checked = amountChecked === checkboxes.length;
            allSubmissionsInput.value = (amountChecked === checkboxes.length).toString();
        }));

        selectAll.addEventListener("click", event => {
            const isChecked = (event.target as HTMLInputElement).checked;
            checkboxes.forEach( (checkbox: HTMLInputElement) => {
                checkbox.checked = isChecked;
            });
            allSubmissionsInput.value = isChecked.toString();
        });
    }

    function initContinueButton(): void {
        document.querySelectorAll("#next_step").forEach(b => b.addEventListener("click", () => {
            let formUrl = null;
            const selectedBoxes = filteredCheckboxes();
            if (selectedBoxes.length) {
                formUrl = `${defaultAction}?selected_ids[]=${selectedBoxes[0].value}`;
                for (let i = 1; i < selectedBoxes.length; i += 1) {
                    formUrl += `&selected_ids[]=${selectedBoxes[i].value}`;
                }
            }
            if (formUrl) {
                errorWrapper.classList.add("hidden");
                choosePanel.querySelector(".panel-collapse").classList.remove("show");
                chooseOptionsPanel.classList.remove("hidden");
                chooseOptionsPanel.querySelector(".panel-collapse").classList.add("show");
                form.action = formUrl;
            } else {
                choosePanel.querySelector(".panel-collapse").classList.add("show");
                chooseOptionsPanel.classList.add("hidden");
                errorWrapper.classList.remove("hidden");
                document.querySelector("#warning-message-wrapper").innerHTML = I18n.t("js.no_selection");
            }
        }));
    }

    init();
}

export { initSelection };

