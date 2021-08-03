import { fetch } from "util.js";

export function interceptAddMultiUserClicks(): void {
    let running = false;
    document.querySelectorAll(".user-select-option a").forEach(option => {
        option.addEventListener("click", async event => {
            if (!running) {
                running = true;
                event.preventDefault();
                const button = option.querySelector(".button");
                const loader = option.querySelector(".loader");
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

export function initCheckboxes(): void {
    document.querySelectorAll(".evaluation-users-table .user-row").forEach(el => initCheckbox(el));
}

export function initCheckbox(row: HTMLTableRowElement): void {
    const checkbox = row.querySelector(".form-check-input") as HTMLInputElement;
    checkbox.addEventListener("input", async function () {
        const url = checkbox.getAttribute("data-url");
        const confirmMessage = checkbox.getAttribute("data-confirm");
        if (!confirmMessage || confirm(confirmMessage)) {
            const response = await fetch(url, { method: "POST" });
            eval(await response.text());
        }
    });
}
