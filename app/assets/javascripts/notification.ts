/**
 * Model for a notification in the navbar.
 */
export class Notification {
    readonly element: Element;
    read: boolean;

    constructor(readonly id: number, readonly url: string, readonly _read: boolean) {
        this.element = document.querySelector(`.notification[data-id="${id}"]`);
        this.read = _read;

        this.element.querySelector(".notification-link").addEventListener("click", event => {
            const goto = (event.target as HTMLLinkElement).href;
            fetch(url, {
                method: "PATCH",
                headers: {
                    "x-csrf-token": (document.querySelector("meta[name=\"csrf-token\"]") as HTMLMetaElement).content,
                    "x-requested-with": "XMLHttpRequest",
                    "content-type": "application/json"
                },
                body: "{ \"notification\": { \"read\": true } }"
            }).then(() => {
                window.location.href = goto;
            });
            return false;
        });

        this.element.querySelector(".read-indicator").addEventListener("click", event => {
            const indicator = event.target as Element;
            fetch(url, {
                method: "PATCH",
                headers: {
                    "x-csrf-token": (document.querySelector("meta[name=\"csrf-token\"]") as HTMLMetaElement).content,
                    "x-requested-with": "XMLHttpRequest",
                    "content-type": "application/json"
                },
                body: `{ "notification": { "read": ${!this.read} } }`
            }).then(resp => {
                return Promise.all([resp.ok, resp.json()]);
            }).then(([ok, body]) => {
                if (!ok) {
                    return Promise.reject(body);
                }
                this.read = body.read;
                if (!this.read) {
                    indicator.classList.remove("mdi-circle-medium");
                    indicator.classList.add("mdi-check");
                } else {
                    indicator.classList.remove("mdi-check");
                    indicator.classList.add("mdi-circle-medium");
                }
            });
            event.stopPropagation();
        });
    }
}
