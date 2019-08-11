interface NotificationProperties {
    autoHide: boolean;
    loading: boolean;
}

/**
 * Shows a notification in the bottom left corner
 */
export class Notification {

    content: string;
    autoHide: boolean;
    loading: boolean;
    notification: Element;

    constructor(content: string, properties: NotificationProperties = { autoHide: true, loading: false }) {
        this.content = content;

        this.autoHide = properties.autoHide === undefined ? true : properties.autoHide;
        this.loading = properties.loading === undefined ? false : properties.loading;

        this.notification = this.generateNotificationHTML(this.content, this.loading);

        this.show();

        if (this.autoHide) {
            setTimeout(() => {
                this.hide();
            }, 3000);
        }
    }

    private show() {
        document.querySelector(".notifications").prepend(this.notification);
        window.requestAnimationFrame(() => {
            this.notification.classList.remove("notification-show");
        });
    }

    hide() {
        this.notification.classList.add("notification-hide");
        setTimeout(() => {
            this.notification.remove();
        }, 1000);
    }

    private generateNotificationHTML(content: string, loading: boolean): Element {
        const element = this.htmlToElement(`<div class='notification notification-show'>${content}</div>`);
        if (loading) {
            element.appendChild(this.htmlToElement("<div class='spinner'></div>"));
        }
        return element;
    }

    private htmlToElement(html: string): Element {
        const template = document.createElement('template');
        template.innerHTML = html.trim();
        return <Element>template.content.firstChild;
    }
}
