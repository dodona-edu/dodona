import { Toast } from "./toast";

function initFavoriteButtons() {
    function init() {
        document.querySelectorAll(".favorite-button")
            .forEach(btn => btn.addEventListener("click", toggleFavorite));
    }

    function toggleFavorite() {
        const element = this;
        if (element.classList.contains("favorited")) {
            unfavoriteCourse(element);
        } else {
            favoriteCourse(element);
        }
    }

    function favoriteCourse(element) {
        const courseId = element.dataset.course_id;
        fetch(`/courses/${courseId}/favorite.js`, {
            "method": "POST",
            "headers": {
                "x-csrf-token": document.querySelector(`meta[name="csrf-token"]`).getAttribute("content"),
            },
        }).then(response => {
            if (response.ok) {
                new Toast(I18n.t("js.favorite-course-succeeded"));
                element.classList.remove("mdi-heart-outline");
                element.classList.add("favorited", "mdi-heart");

                // update tooltip
                const tooltip = bootstrap.Tooltip.getInstance(element);
                tooltip.setContent({ ".tooltip-inner": I18n.t("js.unfavorite-course-do") });
                tooltip.hide();

                // search the card
                let parent = element.parentNode;
                while (!(parent.classList.contains("course") && parent.classList.contains("card"))) {
                    parent = parent.parentNode;
                }
                const card = parent.parentNode;
                const favoritesRow = document.querySelector(".favorites-row");
                if (favoritesRow.children.length === 0) {
                    document.querySelector(".page-subtitle.first").classList.remove("hidden");
                }
                // create clone of card to place up top on the favorites row
                const clone = card.cloneNode(true);
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

    function unfavoriteCourse(element) {
        const courseId = element.dataset.course_id;
        fetch(`/courses/${courseId}/unfavorite.js`, {
            "method": "POST",
            "headers": {
                "x-csrf-token": document.querySelector(`meta[name="csrf-token"]`).getAttribute("content"),
            },
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
                let parent = course.parentNode;
                while (!(parent.classList.contains("course") && parent.classList.contains("card"))) {
                    parent = parent.parentNode;
                }
                const card = parent.parentNode;
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
