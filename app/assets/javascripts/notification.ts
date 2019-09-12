/**
 * Shows a notification in the bottom left corner. By default, hides it after 3 seconds.
 */
export class Notification {
    static readonly hideDelay = 3000;
    static readonly removeDelay = 1000;
    static readonly notificationsContainer = ".notifications";

    readonly notification: Element;

    constructor(readonly content: string, readonly autoHide = true, readonly loading = false) {
        this.notification = this.generateNotificationHTML(this.content, this.loading);
        this.show();

        if (this.autoHide) {
            setTimeout(() => {
                this.hide();
            }, Notification.hideDelay);
        }
    }

    private show(): void {
        document.querySelector(Notification.notificationsContainer).prepend(this.notification);
        window.requestAnimationFrame(() => {
            this.notification.classList.remove("notification-show");
        });
    }

    hide(): void {
        this.notification.classList.add("notification-hide");
        setTimeout(() => {
            this.notification.remove();
        }, Notification.removeDelay);
    }

    private generateNotificationHTML(content: string, loading: boolean): Element {
        const element = this.htmlToElement(
            `<div class='notification notification-show'>${content}</div>`
        );
        if (loading) {
            element.appendChild(this.htmlToElement("<div class='spinner'></div>"));
        }
        return element;
    }

    private htmlToElement(html: string): Element {
        const template = document.createElement("template");
        template.innerHTML = html.trim();
        return template.content.firstChild as Element;
    }
}
