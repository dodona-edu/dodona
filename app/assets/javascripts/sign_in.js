function initInstitutionAutoSelect(institutions, links) {
    let institution = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        local: institutions,
    });

    $('#scrollable-dropdown-menu .typeahead').typeahead({
            minLength: 0,
            highlight: true
        }, {
            name: 'institution',
            display: 'name',
            limit: institutions.length,
            source: institutionsWithDefaults
        }); 

    function institutionsWithDefaults(q, sync) {
        if (q === '') {
            sync(institution.all()); // This is the only change needed to get 'ALL' items as the defaults
        } else {
            institution.search(q, sync);
        }
    }

    $('.typeahead').bind('typeahead:select', function(ev, suggestion) {
        $('#sign-in').attr("href", links[suggestion.type]);
    });
}

export { initInstitutionAutoSelect };