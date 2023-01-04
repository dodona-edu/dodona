import { fetch } from "./util.js";
import { Toast } from "./toast";

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

        fetch(`/repositories/${repositoryId}/add_admin.js`, {
            method: "POST",
            body: JSON.stringify({ user_id: userId }),
            headers: { "Content-type": "application/json" },
        })
            .then( response => {
                if (response.ok) {
                    adminAdded(button, oldRow);
                } else {
                    // todo: toast?
                }
            });
    }

    function onRemoveClick(e: Event): void {
        const button = e.currentTarget as HTMLButtonElement;
        const cell = button.parentElement.closest("td.repository-admin-button-cell") as HTMLTableCellElement;
        const userId = cell.dataset.user_id;
        const repositoryId = cell.dataset.repository_id;

        fetch(`/repositories/${repositoryId}/remove_admin.js`, {
            method: "POST",
            body: JSON.stringify({ user_id: userId }),
            headers: { "Content-type": "application/json" },
        })
            .then( response => {
                if (response.ok) {
                    adminRemoved(userId);
                } else {
                    // todo: toast?
                }
            });
    }


    function adminAdded(button: HTMLButtonElement, oldRow: HTMLTableRowElement): void {
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
        deleteButton.classList.add("bg-danger");
        deleteButton.addEventListener("click", onRemoveClick);
        document.querySelector("#admin-table-wrapper table tbody").append(newRow);
        button.classList.add("hidden");
    }

    function adminRemoved(userId: string): void {
        document.querySelector(`#admin-table-wrapper td.repository-admin-button-cell[data-user_id="${userId}"]`).closest("tr").remove();
        const addButton = document.querySelector(`td[data-user_id="${userId}"]`).querySelector(".btn.add-admin");
        addButton.classList.remove("hidden");
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

        fetch(`/repositories/${repositoryId}/add_course.js`, {
            method: "POST",
            body: JSON.stringify({ course_id: courseId }),
            headers: { "Content-type": "application/json" },
        })
            .then( response => {
                if (response.ok) {
                    courseAdded(button, oldRow);
                } else {
                    // todo: toast?
                }
            });
    }

    function onRemoveClick(e: Event): void {
        const button = e.currentTarget as HTMLButtonElement;
        const cell = button.parentElement.closest("td.repository-course-button-cell") as HTMLTableCellElement;
        const courseId = cell.dataset.course_id;
        const repositoryId = cell.dataset.repository_id;

        fetch(`/repositories/${repositoryId}/remove_course.js`, {
            method: "POST",
            body: JSON.stringify({ course_id: courseId }),
            headers: { "Content-type": "application/json" },
        })
            .then( response => {
                if (response.ok) {
                    courseRemoved(courseId);
                } else {
                    // todo: toast?
                }
            });
    }

    function courseAdded(button: HTMLButtonElement, oldRow: HTMLTableRowElement): void {
        const newRow = oldRow.cloneNode(true) as HTMLTableRowElement;
        const deleteButton = newRow.querySelector(".btn.add-course");
        deleteButton.classList.remove("add-course");
        deleteButton.innerHTML = "<i class='mdi mdi-delete'></i>";
        deleteButton.classList.add("remove-course");
        deleteButton.classList.add("btn-icon-filled");
        deleteButton.classList.add("bg-danger");
        deleteButton.addEventListener("click", onRemoveClick);
        document.querySelector("#allowed-courses-table-wrapper table tbody").append(newRow);
        button.classList.add("hidden");
    }

    function courseRemoved(courseId: string): void {
        document.querySelector(`#allowed-courses-table-wrapper td.repository-course-button-cell[data-course_id="${courseId}"]`).closest("tr").remove();
        const addButton = document.querySelector(`td[data-course_id="${courseId}"]`).querySelector(".btn.add-course");
        addButton.classList.remove("hidden");
    }

    init();
}

export { initAdminsEdit, initCoursesEdit };
