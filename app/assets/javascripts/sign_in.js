/* globals Bloodhound */

function initInstitutionAutoSelect(institutions, links) {
    // Textual, user-facing representation of the institution.
    function institutionRepresentation(institution) {
        return institution.name + " – " + links[institution.type].name;
    }

    const institutionSuggestions = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace("name"),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        local: institutions,
    });

    const typeAhead = $("#scrollable-dropdown-menu .typeahead");
    const loginButton = $("#sign-in");

    typeAhead.typeahead({
        minLength: 0,
        highlight: true
    }, {
        name: "institution",
        display: institutionRepresentation,
        source: (query, sync) => {
            if (query === "") {
                // Needed to get 'ALL' items as the default suggestions.
                sync(institutionSuggestions.all());
            } else {
                institutionSuggestions.search(query, sync);
            }
        }
    });

    // Select an institution.
    function selectInstitution(institution) {
        loginButton.attr("href", links[institution.type].link);
        loginButton.attr("disabled", false);
        localStorage.setItem("institution", JSON.stringify(institution));
    }

    // Clear the selection.
    function clearInstitutionSelection() {
        loginButton.attr("href", "");
        loginButton.attr("disabled", true);
        localStorage.removeItem("institution");
    }

    // When users select something in the dropdown.
    typeAhead.on("typeahead:select", (e, i) => selectInstitution(i));
    // When the field is autocompleted, e.g. with the tab key.
    typeAhead.on("typeahead:autocomplete", (e, i) => selectInstitution(i));
    // When the user types the full name on their own.
    typeAhead.on("input", e => {
        const val = e.target.value;
        const institution = institutions.find(i => val === institutionRepresentation(i));
        if (institution) {
            selectInstitution(institution);
        } else {
            clearInstitutionSelection();
        }
    });

    // Check if there is an institution in localStorage if so set it as default selection.
    const localStorageInstitution = localStorage.getItem("institution");
    if (localStorageInstitution !== null) {
        const institution = JSON.parse(localStorageInstitution);
        typeAhead.typeahead("val", institutionRepresentation(institution));
        selectInstitution(institution);
    }
}

export { initInstitutionAutoSelect };
