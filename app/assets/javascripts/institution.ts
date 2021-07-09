import { fetch } from "./util.js";

function initInstitutionSelectionTable(institutionId: number): void {
    const institutionPanel = document.querySelector("#institution-panel");
    const confirmPanel = document.querySelector("#confirm-panel");
    const institutionCollapse = new bootstrap.Collapse(institutionPanel.querySelector(".panel-collapse"), { toggle: false });
    const confirmCollapse = new bootstrap.Collapse(confirmPanel.querySelector(".panel-collapse"), { toggle: false });

    function init(): void {
        window.dodona.institutionsLoaded = institutionsLoaded;
        window.dodona.switchPanels = switchPanels;
        institutionsLoaded();
    }

    function institutionsLoaded(): void {
        document.querySelectorAll("[data-institution_id]").forEach(i => {
            i.addEventListener("click", async function () {
                i.querySelector("input[type=\"radio\"]").checked = true;
                institutionPanel.querySelector(".answer").innerText = i.getAttribute("data-answer");
                const resp = await fetch(`/institutions/${institutionId}/merge_changes.js?other_institution_id=${i.getAttribute("data-institution_id")}`);
                eval(await resp.text());
            });
        });
        document.querySelectorAll(".nested-link").forEach(i => {
            i.addEventListener("click", e => e.stopPropagation());
        });
    }

    function switchPanels(): void {
        confirmPanel.classList.remove("hidden");
        confirmCollapse.show();
        institutionCollapse.hide();
    }

    init();
}

export { initInstitutionSelectionTable };
