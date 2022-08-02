import { fetch } from "util.js";

export function initCheckboxes(): void {
    document.querySelectorAll(".evaluation-users-table .user-row").forEach(el => initCheckbox(el));
}

export function initCheckbox(row: HTMLTableRowElement): void {
    const checkbox = row.querySelector(".form-check-input") as HTMLInputElement;
    checkbox.addEventListener("change", async function () {
        const url = checkbox.getAttribute("data-url");
        const confirmMessage = checkbox.getAttribute("data-confirm");
        if (!confirmMessage || confirm(confirmMessage)) {
            const response = await fetch(url, { method: "POST" });
            eval(await response.text());
        } else {
            // There are no cancelable events for checkbox input, so cancel manually afterwards
            checkbox.checked = !checkbox.checked;
        }
    });
}

export function initEvaluationStepper(): void {
    const evalPanelElement = document.querySelector("#info-panel .panel-collapse");
    const evalPanel = new bootstrap.Collapse(evalPanelElement, { toggle: false });
    const userPanelElement = document.querySelector("#users-panel .panel-collapse");
    const userPanel = new bootstrap.Collapse(userPanelElement, { toggle: false });
    const choicePanelElement = document.querySelector("#choice-panel .panel-collapse");
    const choicePanel = new bootstrap.Collapse(choicePanelElement, { toggle: false });
    const scorePanelElement = document.querySelector("#items-panel .panel-collapse");
    const scorePanel = new bootstrap.Collapse(scorePanelElement, { toggle: false });

    let evaluationUrl: string = null;

    function init(): void {
        window.dodona.toUsersStep = toUsersStep;
        window.dodona.setEvaluationUrl = url => {
            evaluationUrl = url;
        };

        evalPanelElement.addEventListener("show.bs.collapse", function () {
            userPanel.hide();
            choicePanel.hide();
            scorePanel.hide();
        });
        userPanelElement.addEventListener("show.bs.collapse", function () {
            evalPanel.hide();
            choicePanel.hide();
            scorePanel.hide();
        });
        choicePanelElement.addEventListener("show.bs.collapse", function () {
            evalPanel.hide();
            userPanel.hide();
            scorePanel.hide();
        });
        scorePanelElement.addEventListener("show.bs.collapse", function () {
            evalPanel.hide();
            choicePanel.hide();
            userPanel.hide();
        });

        document.querySelector("#users-step-finish-button").addEventListener("click", function () {
            userPanel.hide();
            choicePanel.show();
            document.querySelector("#short-users-count-wrapper").classList.remove("hidden");
        });

        const yesButton = document.querySelector("#yes-grading");
        yesButton.addEventListener("click", function () {
            document.querySelector("#items-panel").classList.remove("hidden");
            choicePanel.hide();
            scorePanel.show();
            document.querySelector("#choice-panel .answer").innerText = yesButton.dataset["answer"];
        });

        document.querySelector("#no-grading").addEventListener("click", function () {
            window.location.href = evaluationUrl;
        });
    }


    function toUsersStep(): void {
        interceptAddMultiUserClicks();
        initCheckboxes();
        document.querySelector("#deadline-group .btn").classList.add("disabled");
        evalPanelElement.querySelector(".stepper-actions").remove();
        evalPanel.hide();
        userPanel.show();
        document.querySelector("#users-panel a[role=\"button\"]").setAttribute("href", "#users-step");
        document.querySelector("#users-panel a[role=\"button\"]").classList.remove("disabled");
        document.querySelector("#choice-panel a[role=\"button\"]").setAttribute("href", "#choice-step");
        document.querySelector("#choice-panel a[role=\"button\"]").classList.remove("disabled");
        document.querySelector("#items-panel a[role=\"button\"]").setAttribute("href", "#items-step");
        document.querySelector("#items-panel a[role=\"button\"]").classList.remove("disabled");
    }

    function interceptAddMultiUserClicks(): void {
        let running = false;
        document.querySelectorAll(".user-select-option a").forEach(option => {
            option.addEventListener("click", async event => {
                if (!running) {
                    running = true;
                    event.preventDefault();
                    const button = option.querySelector(".btn");
                    const loader = option.parentNode.querySelector(".loader");
                    button.classList.add("hidden");
                    loader.classList.remove("hidden");
                    const response = await fetch(option.getAttribute("href"), { method: "POST" });
                    eval(await response.text());
                    loader.classList.add("hidden");
                    button.classList.remove("hidden");
                    running = false;
                }
            });
        });
    }

    init();
}
