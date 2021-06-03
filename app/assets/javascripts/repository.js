function initAdminsEdit() {
    function init() {
        initAddButtons();
        initRemoveButtons();
        dodona.repositoryAdminsUsersLoaded = init;
    }

    function initAddButtons() {
        const $buttons = $(".btn.add-admin");
        $buttons.off("click");
        $buttons.on("click", onAddClick);
    }

    function initRemoveButtons() {
        const $buttons = $(".btn.remove-admin");
        $buttons.off("click");
        $buttons.on("click", onRemoveClick);
    }

    function onAddClick() {
        const $button = $(this);
        const $cell = $button.parents("td.repository-admin-button-cell").eq(0);
        const userId = $cell.data("user_id");
        const repositoryId = $cell.data("repository_id");
        const $oldRow = $cell.parents("tr").eq(0);

        $.post(`/repositories/${repositoryId}/add_admin.js`, {
            user_id: userId,
        })
            .done(() => adminAdded($button, $oldRow))
            .fail(() => {
            });
    }

    function onRemoveClick() {
        const $button = $(this);
        const $cell = $button.parents("td.repository-admin-button-cell").eq(0);
        const userId = $cell.data("user_id");
        const repositoryId = $cell.data("repository_id");

        $.post(`/repositories/${repositoryId}/remove_admin.js`, {
            user_id: userId,
        })
            .done(() => adminRemoved(userId))
            .fail(() => {
            });
    }


    function adminAdded($button, $oldRow) {
        $(".table-placeholder").remove();
        $button.html("<i class='mdi mdi-delete mdi-18'></i>");
        $button.removeClass("add-admin");
        $button.addClass("remove-admin");
        $button.addClass("btn-danger");
        $button.off("click");
        $button.on("click", onRemoveClick);
        $("#admin-table-wrapper table tbody").append($oldRow.clone(true));
        $button.remove();
    }

    function adminRemoved(userId) {
        $(`#admin-table-wrapper td.repository-admin-button-cell[data-user_id="${userId}"]`).parents("tr").eq(0).remove();
        const $cell = $(`td[data-user_id="${userId}"]`);
        if ($cell) {
            $cell.html("<button type='button' class='btn btn-sm add-admin'><i class='mdi mdi-account-plus mdi-18'></i></button>");
            const $button = $cell.find(".add-admin");
            $button.off("click");
            $button.on("click", onAddClick);
        }
    }

    init();
}

function initCoursesEdit() {
    function init() {
        initAddButtons();
        initRemoveButtons();
        dodona.repositoryCoursesLoaded = init;
    }

    function initAddButtons() {
        const $buttons = $(".btn.add-course");
        $buttons.off("click");
        $buttons.on("click", onAddClick);
    }

    function initRemoveButtons() {
        const $buttons = $(".btn.remove-course");
        $buttons.off("click");
        $buttons.on("click", onRemoveClick);
    }

    function onAddClick() {
        const $button = $(this);
        const $cell = $button.parents("td.repository-course-button-cell").eq(0);
        const courseId = $cell.data("course_id");
        const repositoryId = $cell.data("repository_id");
        const $oldRow = $cell.parents("tr").eq(0);

        $.post(`/repositories/${repositoryId}/add_course.js`, {
            course_id: courseId,
        })
            .done(() => courseAdded($button, $oldRow))
            .fail(() => {
            });
    }

    function onRemoveClick() {
        const $button = $(this);
        const $cell = $button.parents("td.repository-course-button-cell").eq(0);
        const courseId = $cell.data("course_id");
        const repositoryId = $cell.data("repository_id");

        $.post(`/repositories/${repositoryId}/remove_course.js`, {
            course_id: courseId,
        })
            .done(() => courseRemoved(courseId))
            .fail(() => {
            });
    }

    function courseAdded($button, $oldRow) {
        $button.html("<i class='mdi mdi-delete mdi-18'></i>");
        $button.removeClass("add-course");
        $button.addClass("remove-course");
        $button.addClass("btn-danger");
        $button.off("click");
        $button.on("click", onRemoveClick);
        $("#allowed-courses-table-wrapper table tbody").append($oldRow.clone(true));
        $button.remove();
    }

    function courseRemoved(courseId) {
        $(`#allowed-courses-table-wrapper td.repository-course-button-cell[data-course_id="${courseId}"]`).parents("tr").eq(0).remove();
        const $cell = $(`td[data-course_id="${courseId}"]`);
        if ($cell) {
            $cell.html("<button type='button' class='btn btn-sm add-course'><i class='mdi mdi-plus mdi-18'></i> </button>");
            const $button = $cell.find(".add-course");
            $button.off("click");
            $button.on("click", onAddClick);
        }
    }

    init();
}

export { initAdminsEdit, initCoursesEdit };
