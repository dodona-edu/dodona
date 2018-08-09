import {showNotification} from "./notifications";

function initFavoriteButtons() {
    function init() {
        $(".glyphicon-star-empty").click(toggleFavorite);
        $(".glyphicon-star").click(toggleFavorite);
    }

    function toggleFavorite() {
        const element = $(this);
        if (element.hasClass("glyphicon-star-empty")) {
            favoriteCourse(element);
        } else {
            unfavoriteCourse(element);
        }
    }

    function favoriteCourse(element) {
        let courseId = element.data("course_id");
        $.post(`/courses/${courseId}/favorite`)
            .done(() => {
                showNotification(I18n.t("js.favorite-course-succeeded"));
                element.removeClass("glyphicon-star-empty");
                element.addClass("glyphicon-star");
            })
            .fail(() => {
                showNotification(I18n.t("js.favorite-course-failed"));
            });
    }

    function unfavoriteCourse(element) {
        let courseId = element.data("course_id");
        $.post(`/courses/${courseId}/unfavorite`)
            .done(() => {
                showNotification(I18n.t("js.unfavorite-course-succeeded"));
                element.removeClass("glyphicon-star");
                element.addClass("glyphicon-star-empty");
            })
            .fail(() => {
                showNotification(I18n.t("js.unfavorite-course-failed"));
            });
    }

    init();
}

export {initFavoriteButtons};
