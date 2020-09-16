/* globals Bloodhound */

function initInstitutionAutoSelect(institutions, links) {
    const institution = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace("name"),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        local: institutions,
    });

    const typeaheadRef = $("#scrollable-dropdown-menu .typeahead").typeahead({
        minLength: 0,
        highlight: true
    }, {
        name: "institution",
        display: institutionRepresentation,
        limit: institutions.length,
        source: institutionsWithDefaults
    });

    function institutionRepresentation(institution) {
        return institution.name + " – " + institution.type.replace("Provider::", "");
    }

    function institutionsWithDefaults(q, sync) {
        if (q === "") {
            sync(institution.all()); // This is the only change needed to get 'ALL' items as the defaults
        } else {
            institution.search(q, sync);
        }
    }

    const institutionRepresentations = institutions.map(i => institutionRepresentation(i));

    $("input").bind("input", e => {
        const val = e.target.value;

        $(".login-button").attr("disabled", !institutionRepresentations.includes(val));
    });

    $(".typeahead").bind("typeahead:select", function (ev, suggestion) {
        $("#sign-in").attr("href", links[suggestion.type]);
        $(".login-button").attr("disabled", false);
        localStorage.setItem("institution", JSON.stringify(suggestion));
    });

    // Check if there is an institution in localStorage if so set it as default selection.
    const localStorageInstitution = localStorage.getItem("institution");
    if (localStorageInstitution !== null) {
        const institution = JSON.parse(localStorageInstitution);
        $(".typeahead").typeahead("val", institutionRepresentation(institution));
        $("#sign-in").attr("href", links[institution.type]);
        $(".login-button").attr("disabled", false);
    }
    typeaheadRef.focus();
}

export { initInstitutionAutoSelect };
