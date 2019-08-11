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
    $notification: JQuery<HTMLElement>;

    constructor(content: string, properties: NotificationProperties = { autoHide: true, loading: false }) {
        this.content = content;

        this.autoHide = properties.autoHide === undefined ? true : properties.autoHide;
        this.loading = properties.loading === undefined ? false : properties.loading;

        this.$notification = this.generateNotificationHTML(this.content, this.loading);

        this.show();

        if (this.autoHide) {
            setTimeout(() => {
                this.hide();
            }, 3000);
        }
    }

    private show() {
        $(".notifications").prepend(this.$notification);
        window.requestAnimationFrame(() => {
            this.$notification.removeClass("notification-show");
        });
    }

    hide() {
        this.$notification.addClass("notification-hide");
        setTimeout(() => {
            this.$notification.remove();
        }, 1000);
    }

    private generateNotificationHTML(content: string, loading: boolean) {
        const $element = $("<br><div class='notification notification-show'>" + content + "</div>");
        if (loading) {
            $element.append("<div class='spinner'></div>");
        }
        return $element;
    }
}
