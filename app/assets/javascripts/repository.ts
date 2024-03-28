import { fetch } from "utilities";
import { Toast } from "./toast";
import { i18n } from "i18n/i18n";

function initAdminsEdit(): void {
    function init(): void {
        initAddButtons();
        initRemoveButtons();
        dodona.repositoryAdminsUsersLoaded = init;
    }

    function initAddButtons(): void {
        const buttons = document.querySelectorAll(".btn.add-admin");
        buttons.forEach(b => b.removeEventListener("click", onAddClick));
        buttons.forEach(b => b.addEventListener("click", onAddClick));
    }

    function initRemoveButtons(): void {
        const buttons = document.querySelectorAll(".btn.remove-admin");
        buttons.forEach(b => b.removeEventListener("click", onRemoveClick));
        buttons.forEach(b => b.addEventListener("click", onRemoveClick));
    }

    function onAddClick(e: Event): void {
        const button = e.currentTarget as HTMLButtonElement;
        const cell = button.closest("td.repository-admin-button-cell") as HTMLTableCellElement;
        const userId = cell.dataset.user_id;
        const repositoryId = cell.dataset.repository_id;
        const oldRow = cell.parentElement.closest("tr");

        fetch(`/repositories/${repositoryId}/add_admin`, {
            method: "POST",
            body: JSON.stringify({ user_id: userId }),
            headers: { "Content-type": "application/json" },
        })
            .then( response => {
                if (response.ok) {
                    adminAdded(button, oldRow);
                } else {
                    new Toast(i18n.t("js.admin-added-failed"));
                }
            });
    }

    function onRemoveClick(e: Event): void {
        const button = e.currentTarget as HTMLButtonElement;
        const cell = button.parentElement.closest("td.repository-admin-button-cell") as HTMLTableCellElement;
        const userId = cell.dataset.user_id;
        const repositoryId = cell.dataset.repository_id;

        fetch(`/repositories/${repositoryId}/remove_admin`, {
            method: "POST",
            body: JSON.stringify({ user_id: userId }),
            headers: { "Content-type": "application/json" },
        })
            .then( response => {
                if (response.ok) {
                    adminRemoved(userId);
                } else {
                    new Toast(i18n.t("js.admin-removed-failed"));
                }
            });
    }

    function adminAdded(addButton: HTMLButtonElement, oldRow: HTMLTableRowElement): void {
        new Toast(i18n.t("js.admin-added-success"));
        const tablePlaceholder = document.querySelector(".table-placeholder");
        if (tablePlaceholder) {
            tablePlaceholder.remove();
        }

        const newRow = oldRow.cloneNode(true) as HTMLTableRowElement;
        const deleteButton = newRow.querySelector(".btn.add-admin");
        deleteButton.classList.remove("add-admin");
        deleteButton.innerHTML = "<i class='mdi mdi-delete'></i>";
        deleteButton.classList.add("remove-admin");
        deleteButton.classList.add("btn-icon-filled");
        deleteButton.classList.add("d-btn-danger");
        deleteButton.addEventListener("click", onRemoveClick);
        document.querySelector("#admin-table-wrapper table tbody").append(newRow);
        addButton.classList.add("invisible");
    }

    function adminRemoved(userId: string): void {
        new Toast(i18n.t("js.admin-removed-success"));
        document.querySelector(`#admin-table-wrapper td.repository-admin-button-cell[data-user_id="${userId}"]`).closest("tr").remove();
        const addButton = document.querySelector(`td[data-user_id="${userId}"]`).querySelector(".btn.add-admin");
        addButton.classList.remove("invisible");
    }

    init();
}

function initCoursesEdit(): void {
    function init(): void {
        initAddButtons();
        initRemoveButtons();
        dodona.repositoryCoursesLoaded = init;
    }

    function initAddButtons(): void {
        const buttons = document.querySelectorAll(".btn.add-course");
        buttons.forEach(b => b.removeEventListener("click", onAddClick));
        buttons.forEach(b => b.addEventListener("click", onAddClick));
    }

    function initRemoveButtons(): void {
        const buttons = document.querySelectorAll(".btn.remove-course");
        buttons.forEach(b => b.removeEventListener("click", onRemoveClick));
        buttons.forEach(b => b.addEventListener("click", onRemoveClick));
    }

    function onAddClick(e: Event): void {
        const button = e.currentTarget as HTMLButtonElement;
        const cell = button.closest("td.repository-course-button-cell") as HTMLTableCellElement;
        const courseId = cell.dataset.course_id;
        const repositoryId = cell.dataset.repository_id;
        const oldRow = cell.parentElement.closest("tr");

        fetch(`/repositories/${repositoryId}/add_course`, {
            method: "POST",
            body: JSON.stringify({ course_id: courseId }),
            headers: { "Content-type": "application/json" },
        })
            .then( response => {
                if (response.ok) {
                    courseAdded(button, oldRow);
                } else {
                    new Toast(i18n.t("js.course-added-failed"));
                }
            });
    }

    function onRemoveClick(e: Event): void {
        const button = e.currentTarget as HTMLButtonElement;
        const cell = button.parentElement.closest("td.repository-course-button-cell") as HTMLTableCellElement;
        const courseId = cell.dataset.course_id;
        const repositoryId = cell.dataset.repository_id;

        fetch(`/repositories/${repositoryId}/remove_course`, {
            method: "POST",
            body: JSON.stringify({ course_id: courseId }),
            headers: { "Content-type": "application/json" },
        })
            .then( response => {
                if (response.ok) {
                    courseRemoved(courseId);
                } else {
                    new Toast(i18n.t("js.course-removed-failed"));
                }
            });
    }

    function courseAdded(addButton: HTMLButtonElement, oldRow: HTMLTableRowElement): void {
        new Toast(i18n.t("js.course-added-success"));
        const newRow = oldRow.cloneNode(true) as HTMLTableRowElement;
        const deleteButton = newRow.querySelector(".btn.add-course");
        deleteButton.classList.remove("add-course");
        deleteButton.innerHTML = "<i class='mdi mdi-delete'></i>";
        deleteButton.classList.add("remove-course");
        deleteButton.classList.add("btn-icon-filled");
        deleteButton.classList.add("d-btn-danger");
        deleteButton.addEventListener("click", onRemoveClick);
        document.querySelector("#allowed-courses-table-wrapper table tbody").append(newRow);
        addButton.classList.add("invisible");
    }

    function courseRemoved(courseId: string): void {
        new Toast(i18n.t("js.course-removed-success"));
        document.querySelector(`#allowed-courses-table-wrapper td.repository-course-button-cell[data-course_id="${courseId}"]`).closest("tr").remove();
        const addButton = document.querySelector(`td[data-course_id="${courseId}"]`).querySelector(".btn.add-course");
        addButton.classList.remove("invisible");
    }

    init();
}

export { initAdminsEdit, initCoursesEdit };
