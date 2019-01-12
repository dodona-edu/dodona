import flatpickr from "flatpickr";

function initPostForm() {
    function init() {
        if (I18n.locale === "nl") {
            flatpickr.localize({
                weekdays: {
                    shorthand: ["zo", "ma", "di", "wo", "do", "vr", "za"],
                    longhand: ["zondag", "maandag", "dinsdag", "woensdag", "donderdag", "vrijdag", "zaterdag"],
                },
                months: {
                    shorthand: ["jan", "feb", "mrt", "apr", "mei", "jun", "jul", "aug", "sept", "okt", "nov", "dec"],
                    longhand: ["januari", "februari", "maart", "april", "mei", "juni", "juli", "augustus", "september", "oktober", "november", "december"],
                },
                firstDayOfWeek: 1,
                weekAbbreviation: "wk",
                rangeSeparator: " tot ",
                scrollTitle: "Scroll voor volgende / vorige",
                toggleTitle: "Klik om te wisselen",
                ordinal: function ordinal(nth) {
                    if (nth === 1 || nth === 8 || nth >= 20) return "ste";
                    return "de";
                },
            });
        }
        flatpickr($("#release-group").get(0));
    }

    init();
}

export {initPostForm};
