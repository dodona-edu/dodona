/* globals Bloodhound */

function initInstitutionAutoSelect(institutions, links) {
    // Filter institutions without name
    const filteredInstitutions = institutions.filter(institution => institution.name !== "n/a");

    const institution = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace("name"),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        local: filteredInstitutions,
    });

    $("#scrollable-dropdown-menu .typeahead").typeahead({
        minLength: 0,
        highlight: true
    }, {
        name: "institution",
        display: institutionRepresentation,
        limit: filteredInstitutions.length,
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

    $("input").bind("input", e => {
        $(".login-button").attr("disabled", true);
    });

    $(".typeahead").bind("typeahead:select", function (ev, suggestion) {
        $("#sign-in").attr("href", links[suggestion.type]);
        $(".login-button").attr("disabled", false);
        localStorage.setItem("institution", JSON.stringify(suggestion));
    });

    // Check if there is an institution in localStorage if so set it as default selection.
    const localStorageInstitution = localStorage.getItem("institution");
    if (localStorageInstitution !== undefined) {
        const institution = JSON.parse(localStorageInstitution);
        $(".typeahead").typeahead("val", institutionRepresentation(institution));
        $("#sign-in").attr("href", links[institution.type]);
        $(".login-button").attr("disabled", false);
    }
}

export { initInstitutionAutoSelect };
