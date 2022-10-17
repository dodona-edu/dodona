/* globals Bloodhound */
function initCourseMemberLabelsEdit(labels) {
    const engine = new Bloodhound({
        local: labels,
        identify: d => d.id,
        datumTokenizer: d => {
            const result = Bloodhound.tokenizers.whitespace(d.name);
            document.querySelectorAll().forEach(result, (_i, val) => {
                for (let i = 1; i < val.length; i++) {
                    result.push(val.substr(i, val.length));
                }
            });
            return result;
        }, queryTokenizer: Bloodhound.tokenizers.whitespace,
    });

    const field = document.querySelector("#course_membership_course_labels");

    field.addEventListener("tokenfield:createdtoken", e => {
        document.querySelector(e.relatedTarget).classList.add("accent-orange");
    });

    field.tokenfield({
        beautify: false,
        createTokensOnBlur: true,
        typeahead: [{
            highlight: true,
        }, {
            source: engine,
            display: d => d.name,
        }],
    });
}

export { initCourseMemberLabelsEdit };
