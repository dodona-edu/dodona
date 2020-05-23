import { fetch, updateURLParameter } from "util.js";

async function markAndGo(url: string, element: HTMLAnchorElement): Promise<void> {
    let goto = element.href;
    if ((document.getElementById("auto-mark") as HTMLInputElement).checked) {
        await fetch(url, {
            method: "PATCH",
            headers: { accept: "application/json" }
        });
        goto = updateURLParameter(goto, "auto_mark", true);
    }
    window.location.href = goto;
}

function interceptNavClicks(url: string): void {
    (document.querySelectorAll(".feedback-nav-link") as NodeListOf<HTMLAnchorElement>).forEach(el => {
        el.addEventListener("click", event => {
            event.preventDefault();
            markAndGo(url, el);
        });
    });
}

export { interceptNavClicks };
