import {showNotification} from "./notifications.js";

function initAdminsEdit() {
    function init() {
        initAddButtons();
        initRemoveButtons();
        dodona.repositoryAdminsUsersLoaded = init;
    }

    function initAddButtons() {
        let $buttons = $(".btn.add-admin");
        $buttons.off("click");
        $buttons.click(onAddClick);
    }

    function initRemoveButtons() {
        let $buttons = $(".btn.remove-admin");
        $buttons.off("click");
        $buttons.click(onRemoveClick);
    }

    function onAddClick() {
        let button = $(this);
        let userId = button.data("user_id");
        let repositoryId = button.data("repository_id");
        let oldRow = button.parents("tr").eq(0);

        $.post(`/repositories/${repositoryId}/add_admin.js`, {
            user_id: userId,
        })
            .done(() => adminAdded(button, oldRow, userId))
            .fail(() => {});
    }

    function onRemoveClick() {
        let button = $(this);
        let userId = button.data("user_id");
        let repositoryId = button.data("repository_id");
        $.post(`/repositories/${repositoryId}/remove_admin.js`, {
            user_id: userId,
        })
            .done(() => adminRemoved(userId))
            .fail(() => {});
    }


    function adminAdded(button, oldRow, userId) {
        button.html("<i class='material-icons md-12'>close</i>");
        button.removeClass("add-admin");
        button.removeClass("btn-success");
        button.addClass("remove-admin");
        button.addClass("btn-danger");
        button.off("click");
        button.click(onRemoveClick);
        $("#admin-table-wrapper table tbody").append(oldRow.clone(true));
    }

    function adminRemoved(userId) {
        $(`#admin-table-wrapper .btn[data-user_id="${userId}"]`).parents("tr").eq(0).remove();
        let button = $(`.btn[data-user_id="${userId}"]`);
        if (button) {
            button.html("<i class='material-icons md-12'>add</i>");
            button.removeClass("remove-admin");
            button.removeClass("btn-danger");
            button.addClass("add-admin");
            button.addClass("btn-success");
            button.off("click");
            button.click(onAddClick);
        }
    }

    init();
}

export {initAdminsEdit};
