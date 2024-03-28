import { i18n } from "i18n/i18n";
import { Collapse } from "bootstrap";

function initSelection(): void {
    const selectAll = document.querySelector("#check-all") as HTMLInputElement;
    const checkboxes = document.querySelectorAll(".selection-checkbox");
    const allSubmissionsInput = document.querySelector("#all_submissions") as HTMLInputElement;

    const errorWrapper = document.querySelector("#errors-wrapper");
    const choosePanel = document.querySelector("#choose-panel");
    const chooseCollapse = new Collapse(choosePanel.querySelector(".panel-collapse"), { toggle: false });
    const chooseOptionsPanel = document.querySelector("#choose-options-panel");
    const chooseOptionsElement = chooseOptionsPanel.querySelector(".panel-collapse");
    const chooseOptionsCollapse = new Collapse(chooseOptionsElement, { toggle: false });

    const form = document.querySelector("#download_submissions") as HTMLFormElement;
    const defaultAction = form.action;

    const startDownload = document.getElementById("start-download") as HTMLButtonElement;
    const downloadingPanel = document.getElementById("downloading-panel") as HTMLDivElement;
    const downloadingCollapse = new Collapse(downloadingPanel.querySelector(".panel-collapse"), { toggle: false });

    function init(): void {
        initCheckboxes();
        initContinueButton();
        initDownloadButton();

        choosePanel.querySelector(".panel-collapse").addEventListener("show.bs.collapse", () => {
            chooseOptionsCollapse.hide();
            downloadingCollapse.hide();
        });
        chooseOptionsPanel.querySelector(".panel-collapse").addEventListener("show.bs.collapse", () => {
            chooseCollapse.hide();
            downloadingCollapse.hide();
        });
        downloadingPanel.querySelector(".panel-collapse").addEventListener("show.bs.collapse", () => {
            chooseCollapse.hide();
            chooseOptionsCollapse.hide();
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
                chooseOptionsPanel.classList.remove("hidden"); // this panel is initially hidden
                chooseOptionsCollapse.show();
                form.action = formUrl;
            } else {
                chooseCollapse.show();
                errorWrapper.classList.remove("hidden");
                document.querySelector("#warning-message-wrapper").innerHTML = i18n.t("js.no_selection");
            }
        }));
    }

    function initDownloadButton(): void {
        startDownload.addEventListener("click", async () => {
            const data = new FormData(form);
            downloadingPanel.classList.remove("hidden");
            downloadingCollapse.show();

            // disable the collapse steppers
            document.querySelectorAll(".panel-heading a").forEach(a => {
                a.classList.add("disabled");
                a.attributes.removeNamedItem("data-bs-toggle");
            });

            const exportDataUrl = await prepareExport(form.action, data);
            const downloadUrl = await exportLocation(exportDataUrl);

            // Update the stepper content
            downloadingPanel.querySelector(".stepper-part").innerHTML = i18n.t("js.export.ready_html", { url: downloadUrl });

            window.location.href = downloadUrl;
        });
    }

    init();
}

/**
 * Prepare the download of a file by sending a POST request to the server.
 * Returns the URL of the metadata for the file to download.
 * @param url The URL of the export endpoint
 * @param data The export settings to send to the server
 */
async function prepareExport(url: string, data: FormData): Promise<string> {
    const response = await fetch(url, {
        method: "POST",
        body: data,
        headers: {
            "Accept": "application/json"
        }
    });
    const json = await response.json();
    return json.url;
}

/**
 * Returns the url of the blob to download when the download is ready.
 * @param url The URL of the download endpoint
 */
async function exportLocation(url: string): Promise<string> {
    const response = await fetch(url);
    const data = await response.json();
    if (!data.ready) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        return await exportLocation(url);
    }
    return data.url;
}

export { initSelection, prepareExport, exportLocation };
