import { fetch } from "util.js";

function interceptAddMultiUserClicks(): void {
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

export { interceptAddMultiUserClicks };
