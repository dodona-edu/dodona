/* globals requestAnimFrame */
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
function showNotification(content, properties = {}) {
    const autoHide = properties.autoHide === undefined ? true : properties.autoHide;
    const loading = properties.loading === undefined ? false : properties.loading;

    const $notification = getNotificationHTML(content);
    $(".notifications").prepend($notification);

    if (autoHide) {
        setTimeout(hide, 3000);
    }
    if (loading) {
        $notification.append("<div class='spinner'></div>");
    }

    requestAnimFrame(function () {
        $notification.removeClass("notification-show");
    });

    return {
        hide: hide,
    };

    function hide(delayed) {
        $notification.addClass("notification-hide");
        setTimeout(function () {
            $notification.remove();
        }, 1000);
    }

    function getNotificationHTML(content) {
        return $("<br><div class='notification notification-show'>" + content + "</div>");
    }
}

export { showNotification };
