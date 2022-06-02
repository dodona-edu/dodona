import { Dutch } from "flatpickr/dist/l10n/nl";
import flatpickr from "flatpickr";
import { Instance } from "flatpickr/dist/types/instance";
import { Options } from "flatpickr/dist/types/options";

/**
 * Initiates a datepicker using flatpicker
 * @param {string} selector - The selector of div containing the input field and buttons
 * @param {Options} options - optional, Options object as should be provided to the flatpicker creation method
 * @return {Instance} the created flatpicker
 */
function initDatePicker(selector, options: Options = {}): Instance {
    function init(): Instance {
        if (I18n.locale === "nl") {
            options.locale = Dutch;
        }
        return flatpickr(selector, options);
    }

    return init();
}

export { initDatePicker };
