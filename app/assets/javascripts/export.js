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
    }

    function filteredCheckboxes() {
        return $checkboxes.filter((_index, cb) => cb.checked);
    }

    function initCheckboxes() {
        $checkboxes.each(function (_index, checkbox) {
            $(checkbox).click(function (_event) {
                const amountChecked = filteredCheckboxes().length;
                $selectAll.prop("indeterminate", amountChecked && amountChecked !== $checkboxes.length);
                $selectAll.prop("checked", amountChecked === $checkboxes.length);
                $allSubmissionsInput.prop("value", amountChecked === $checkboxes.length);
            });
        });

        $selectAll.click(function (event) {
            const isChecked = event.target.checked;
            $checkboxes.each(function (_index, checkbox) {
                $(checkbox).prop("checked", isChecked);
            });
            $allSubmissionsInput.prop("value", isChecked);
        });
    }

    function initContinueButton() {
        $("#next_step").click(function () {
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
                $form.attr("action", formUrl);
            } else {
                $choosePanel.find(".panel-collapse").addClass("in");
                $chooseOptionsPanel.addClass("hidden");
                $errorWrapper.removeClass("hidden");
                $("#warning-message-wrapper").html(I18n.t("js.no_selection"));
            }
        });
    }

    init();
}

export { initSelection };
