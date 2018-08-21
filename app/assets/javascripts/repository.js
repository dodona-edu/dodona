function initAdminsEdit() {
    function init() {
        initAddButtons();
        initRemoveButtons();
        dodona.repositoryAdminsUsersLoaded = init;
    }

    function initAddButtons() {
        const $buttons = $(".btn.add-admin");
        $buttons.off("click");
        $buttons.click(onAddClick);
    }

    function initRemoveButtons() {
        const $buttons = $(".btn.remove-admin");
        $buttons.off("click");
        $buttons.click(onRemoveClick);
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
            .done(() => adminAdded($button, $oldRow, userId))
            .fail(() => {});
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
            .fail(() => {});
    }


    function adminAdded($button, $oldRow) {
        $button.html("<i class='material-icons md-12'>delete</i>");
        $button.removeClass("add-admin");
        $button.addClass("remove-admin");
        $button.addClass("btn-danger");
        $button.off("click");
        $button.click(onRemoveClick);
        $("#admin-table-wrapper table tbody").append($oldRow.clone(true));
        $button.remove();
    }

    function adminRemoved(userId) {
        $(`#admin-table-wrapper td.repository-admin-button-cell[data-user_id="${userId}"]`).parents("tr").eq(0).remove();
        const $cell = $(`td[data-user_id="${userId}"]`);
        if ($cell) {
            $cell.html("<button type='button' class='btn btn-sm add-admin'><i class='material-icons md-12'>person_add</i></button>")
            const $button = $cell.find(".add-admin");
            $button.off("click");
            $button.click(onAddClick);
        }
    }

    init();
}

export {initAdminsEdit};
