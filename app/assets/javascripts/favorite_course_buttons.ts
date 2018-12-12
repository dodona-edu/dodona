import {showNotification} from "./notifications";

function initFavoriteButtons() {
    function init() {
        $(".favorite-button").on("click", toggleFavorite);
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
                element.html("favorite");
                const card = element.parents(".course.card").parent();
                const favoritesRow = $(".favorites-row");
                if (favoritesRow.children().length === 0) {
                    $(".page-subtitle.first").removeClass("hidden");
                }
                card.clone(true).appendTo(favoritesRow);
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
                const elements = $(`[data-course_id="${courseId}"]`);
                elements.removeClass("favorited");
                elements.html("favorite_outline");
                $(`.favorites-row [data-course_id="${courseId}"]`).parents(".course.card").parent().remove();
                if ($(".favorites-row").children().length === 0) {
                    $(".page-subtitle.first").addClass("hidden");
                }
            })
            .fail(() => {
                showNotification(I18n.t("js.unfavorite-course-failed"));
            });
    }

    init();
}

export {initFavoriteButtons};
