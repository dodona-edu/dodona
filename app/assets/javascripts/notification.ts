import { FaviconManager } from "favicon";
import { fetch } from "util.js";

/**
 * Model for a notification in the navbar. It adds three listeners to the notification view:
 *
 *  1. It listens to clicks on the read toggle button and updates the model on
 *  the server accordingly. The view is then updated based on the response of the server.
 *
 *  2. It listens to clicks on the delete button and removes the model on the
 *  server accordingly. The element is then removed from the view.
 *
 *  3. It optionally listens to a click on the element and navigates to the link
 *  of the notification.
 */
export class Notification {
    private readonly element: Element;
    private readonly url: string;
    private readonly notifiableUrl: string;
    private readonly faviconManager: FaviconManager;
    private read: boolean;

    constructor(id: number, url: string, read: boolean, notifiableUrl: string, installClickHandler: boolean, manager: FaviconManager) {
        this.element = document.querySelector(`.notification[data-id="${id}"]`);
        this.read = read;
        this.url = url;
        this.notifiableUrl = notifiableUrl;
        this.faviconManager = manager;

        this.element.querySelector(".read-toggle-button").addEventListener("click", event => {
            this.toggleRead();
            event.stopPropagation();
        });

        // Delete button isn't shown on small view in navbar
        this.element.querySelector(".delete-button")?.addEventListener("click", event => {
            this.remove();
            event.stopPropagation();
        });

        // We only want to install the click handler for the full element on the small notification view.
        if (installClickHandler) {
            this.element.addEventListener("click", event => {
                this.visit();
                event.stopPropagation();
            });
        }
    }

    async toggleRead(): Promise<void> {
        const response = await fetch(this.url, {
            method: "PATCH",
            headers: {
                "content-type": "application/json"
            },
            body: `{ "notification": { "read": ${!this.read} } }`
        });
        const body = await response.json();
        this.read = body.read;
        const indicator = this.element.querySelector(".read-indicator");
        if (!this.read) {
            indicator.setAttribute("title", I18n.t("js.mark_as_read"));
            this.element.classList.add("unread");
        } else {
            indicator.setAttribute("title", I18n.t("js.mark_as_unread"));
            this.element.classList.remove("unread");
        }
        if (document.querySelectorAll(".notification.unread").length === 0) {
            document.querySelector("#navbar-notifications .dropdown-toggle")?.classList?.remove("notification");
            this.faviconManager.releaseDot("notifications");
        } else {
            document.querySelector("#navbar-notifications .dropdown-toggle")?.classList?.add("notification");
            this.faviconManager.requestDot("notifications");
        }
    }

    async remove(): Promise<void> {
        await fetch(this.url, { method: "DELETE" });
        this.element.remove();
    }

    visit(): void {
        window.location.href = this.notifiableUrl;
    }
}

export async function checkNotifications(): Promise<void> {
    const response = await fetch("/notifications.js?per_page=5");
    eval(await response.text());
}
