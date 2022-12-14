import { Toast } from "./toast";
import { fetch, getParentByClassName } from "util.js";

function initFavoriteButtons(doc: Document | HTMLElement = document): void {
    function init(): void {
        doc.querySelectorAll(".favorite-button")
            .forEach(btn => btn.addEventListener("click", toggleFavorite));
    }

    function toggleFavorite(): void {
        if (this.classList.contains("favorited")) {
            unfavoriteCourse(this);
        } else {
            favoriteCourse(this);
        }
    }

    function favoriteCourse(element: HTMLElement): void {
        const courseId = element.dataset.course_id;
        fetch(`/courses/${courseId}/favorite.js`, {
            "method": "POST"
        }).then(response => {
            if (response.ok) {
                new Toast(I18n.t("js.favorite-course-succeeded"));
                element.classList.remove("mdi-heart-outline");
                element.classList.add("favorited", "mdi-heart");

                // update tooltip
                const tooltip = bootstrap.Tooltip.getInstance(element);
                tooltip.setContent({ ".tooltip-inner": I18n.t("js.unfavorite-course-do") });
                tooltip.hide();

                const card = getParentByClassName(element, "course card").parentElement;
                const favoritesRow = document.querySelector(".favorites-row");
                if (favoritesRow.children.length === 0) {
                    document.querySelector(".page-subtitle.first").classList.remove("hidden");
                }
                // create clone of card to place up top on the favorites row
                const clone = card.cloneNode(true) as HTMLElement;
                favoritesRow.appendChild(clone);
                // activate button in new card in the favoritesRow
                const cloneFavButton = clone.querySelector<HTMLButtonElement>(".favorite-button");
                cloneFavButton.setAttribute("title", I18n.t("js.unfavorite-course-do"));
                new bootstrap.Tooltip(cloneFavButton); // is enabled by default
                cloneFavButton.addEventListener("click", toggleFavorite);
            } else {
                new Toast(I18n.t("js.favorite-course-failed"));
            }
        }).catch(() => new Toast(I18n.t("js.favorite-course-failed")));
    }

    function unfavoriteCourse(element: HTMLElement): void {
        const courseId = element.dataset.course_id;
        fetch(`/courses/${courseId}/unfavorite.js`, {
            "method": "POST"
        }).then(response => {
            if (response.ok) {
                new Toast(I18n.t("js.unfavorite-course-succeeded"));
                // update all the heart button and tooltip in the card that is in the favoritesRow and the card later on the page
                const elements = document.querySelectorAll<HTMLElement>(`[data-course_id="${courseId}"]`);
                elements.forEach(el => {
                    el.classList.remove("favorited", "mdi-heart");
                    el.classList.add("mdi-heart-outline");
                    const tooltip = bootstrap.Tooltip.getInstance(el);
                    tooltip.setContent({ ".tooltip-inner": I18n.t("js.favorite-course-do") }); // update tooltip
                    tooltip.hide();
                });
                // search the card in the favorites row and remove it
                const course = document.querySelector(`.favorites-row [data-course_id="${courseId}"]`);
                const card = getParentByClassName(course, "course card").parentElement;
                card.remove();
                const favoritesRow = document.querySelector(".favorites-row");
                if (favoritesRow.children.length === 0) {
                    document.querySelector(".page-subtitle.first").classList.add("hidden");
                }
            } else {
                new Toast(I18n.t("js.unfavorite-course-failed"));
            }
        }).catch(() => new Toast(I18n.t("js.unfavorite-course-failed")));
    }

    init();
}

export { initFavoriteButtons };
