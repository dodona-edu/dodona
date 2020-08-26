import { Toast } from "./toast";
import { Masonry } from "./masonry";

function initHomePageCards() {
    const masonry = new Masonry();
    function init() {
        $(".favorite-button").click(toggleFavorite);
    }

    function toggleFavorite() {
        const $element = $(this);
        if ($element.hasClass("favorited")) {
            unfavoriteCourse($element);
        } else {
            favoriteCourse($element);
        }
    }

    function favoriteCourse(element) {
        const courseId = element.data("course_id");
        $.post(`/courses/${courseId}/favorite.js`)
            .done(() => {
                new Toast(I18n.t("js.favorite-course-succeeded"));
                element.removeClass("mdi-heart-outline").addClass("favorited mdi-heart");
                element.attr("data-original-title", I18n.t("js.unfavorite-course-do"));
                element.tooltip("hide");
                const card = element.parents(".course.card").parent();
                const favoritesRow = $(".favorites-row");
                if (favoritesRow.children().length === 0) {
                    $(".page-subtitle.first").removeClass("hidden");
                }
                const clone = card.clone();
                clone.appendTo(favoritesRow);
                const cloneFavButton = clone.find(".favorite-button");
                cloneFavButton.attr("title", I18n.t("js.unfavorite-course-do"));
                cloneFavButton.tooltip();
                cloneFavButton.click(toggleFavorite);
                masonry.onLoad();
            })
            .fail(() => {
                new Toast(I18n.t("js.favorite-course-failed"));
            });
    }

    function unfavoriteCourse(element) {
        const courseId = element.data("course_id");
        $.post(`/courses/${courseId}/unfavorite.js`)
            .done(() => {
                new Toast(I18n.t("js.unfavorite-course-succeeded"));
                const $elements = $(`[data-course_id="${courseId}"]`);
                $elements.removeClass("favorited mdi-heart").addClass("mdi-heart-outline");
                $elements.attr("data-original-title", I18n.t("js.favorite-course-do"));
                $elements.tooltip("hide");
                $(`.favorites-row [data-course_id="${courseId}"]`)
                    .parents(".course.card")
                    .parent()
                    .remove();
                if ($(".favorites-row").children().length === 0) {
                    $(".page-subtitle.first").addClass("hidden");
                }
                masonry.onLoad();
            })
            .fail(() => {
                new Toast(I18n.t("js.unfavorite-course-failed"));
            });
    }

    init();
}

export { initHomePageCards };