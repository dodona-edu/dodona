/**
 * Shows a notification in the bottom left corner
 *
 * @param {string} content The string to show
 * @param {object} properties The properties
 * @param {boolean} properties.autoHide Whether to automatically hide the
 *       notification. Default is true.
 * @param {boolean} properties.loading Whether a loading indicator should be
 *       shown. Default is false.
 * @return {Notification} $notification
 */
export class Notification {
    constructor(content, properties = {}) {
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

    show() {
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

    generateNotificationHTML(content, loading) {
        const $element = $("<br><div class='notification notification-show'>" + content + "</div>");
        if (loading) {
            $element.append("<div class='spinner'></div>");
        }
        return $element;
    }
}
