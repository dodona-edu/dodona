import {showNotification} from "./notifications";

function initFavoriteButtons() {
    function init() {
        $(".favorite-button").click(toggleFavorite);
    }

    function toggleFavorite() {
        const element = $(this);
        if (element.hasClass("favorited")) {
            unfavoriteCourse(element);
        } else {
            favoriteCourse(element);
        }
    }

    function favoriteCourse(element) {
        let courseId = element.data("course_id");
        $.post(`/courses/${courseId}/favorite.js`)
            .done(() => {
                showNotification(I18n.t("js.favorite-course-succeeded"));
                element.addClass("favorited");
            })
            .fail(() => {
                showNotification(I18n.t("js.favorite-course-failed"));
            });
    }

    function unfavoriteCourse(element) {
        let courseId = element.data("course_id");
        $.post(`/courses/${courseId}/unfavorite.js`)
            .done(() => {
                showNotification(I18n.t("js.unfavorite-course-succeeded"));
                element.removeClass("favorited");
            })
            .fail(() => {
                showNotification(I18n.t("js.unfavorite-course-failed"));
            });
    }

    init();
}

export {initFavoriteButtons};
