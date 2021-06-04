function initSelection() {
    const $selectAll = $("#check-all");
    const $checkboxes = $(".selection-checkbox");
    const $allSubmissionsInput = $("#all_submissions");

    const $errorWrapper = $("#errors-wrapper");
    const $choosePanel = $("#choose-panel");
    const $chooseOptionsPanel = $("#choose-options-panel");

    const $form = $("#download_submissions");
    const defaultAction = $form.attr("action");

    function init() {
        initCheckboxes();
        initContinueButton();

        $choosePanel.find(".panel-collapse").on("show.bs.collapse", function () {
            $chooseOptionsPanel.find(".panel-collapse").collapse("hide");
        });
        $chooseOptionsPanel.find(".panel-collapse").on("show.bs.collapse", function () {
            $choosePanel.find(".panel-collapse").collapse("hide");
        });
    }

    function filteredCheckboxes() {
        return $checkboxes.filter((_index, cb) => cb.checked);
    }

    function initCheckboxes() {
        $(".selection-row").on("click", function () {
            const $checkbox = $(this).find("input[type=\"checkbox\"]");
            $checkbox.prop("checked", !$checkbox.prop("checked")).trigger("change");
        });

        $checkboxes.on("click", e => e.stopPropagation());

        $checkboxes.on("change", function () {
            const amountChecked = filteredCheckboxes().length;
            $selectAll.prop("indeterminate", amountChecked && amountChecked !== $checkboxes.length);
            $selectAll.prop("checked", amountChecked === $checkboxes.length);
            $allSubmissionsInput.prop("value", amountChecked === $checkboxes.length);
        });

        $selectAll.on("click", function (event) {
            const isChecked = event.target.checked;
            $checkboxes.each(function (_index, checkbox) {
                $(checkbox).prop("checked", isChecked);
            });
            $allSubmissionsInput.prop("value", isChecked);
        });
    }

    function initContinueButton() {
        $("#next_step").on("click", function () {
            let formUrl = null;
            const selectedBoxes = filteredCheckboxes();
            if (selectedBoxes.length) {
                formUrl = `${defaultAction}?selected_ids[]=${$(selectedBoxes[0]).attr("value")}`;
                for (let i = 1; i < selectedBoxes.length; i += 1) {
                    formUrl += `&selected_ids[]=${$(selectedBoxes[i]).attr("value")}`;
                }
            }
            if (formUrl) {
                $errorWrapper.addClass("hidden");
                $choosePanel.find(".panel-collapse").collapse("hide");
                $chooseOptionsPanel.removeClass("hidden");
                $chooseOptionsPanel.find(".panel-collapse").collapse("show");
                $form.attr("action", formUrl);
            } else {
                $choosePanel.find(".panel-collapse").collapse("show");
                $chooseOptionsPanel.addClass("hidden");
                $errorWrapper.removeClass("hidden");
                $("#warning-message-wrapper").html(I18n.t("js.no_selection"));
            }
        });
    }

    init();
}

export { initSelection };

