/* globals I18n,Bloodhound,dodona */
import {showNotification} from "./notifications.ts";
import {delay, getArrayURLParameter, getURLParameter, updateArrayURLParameter, updateURLParameter} from "./util.ts";

const FILTER_PARAM = "filter";
const TOKENS_FILTER_ID = "#filter-query";
const QUERY_FILTER_ID = "#filter-query-tokenfield";

function addParametersToUrl(baseUrl, _query, _filterCollections, _extraParams) {
    const filterCollections = _filterCollections || {};
    const query = _query || $(QUERY_FILTER_ID).val();
    const extraParams = _extraParams || {};

    let url = updateURLParameter(baseUrl || window.location.href, FILTER_PARAM, query);

    const tokens = $(TOKENS_FILTER_ID).tokenfield("getTokens");
    for (let type in filterCollections) {
        if (filterCollections.hasOwnProperty(type)) {
            if (filterCollections[type].multi) {
                url = updateArrayURLParameter(url, filterCollections[type].param, tokens
                    .filter(el => el.type === type)
                    .map(e => filterCollections[type].paramVal(e))
                );
            } else {
                const elem = tokens.filter(e => e.type === type)[0];
                url = updateURLParameter(url, filterCollections[type].param, elem ? filterCollections[type].paramVal(elem) : "");
            }
        }
    }

    for (let key in extraParams) {
        if (extraParams.hasOwnProperty(key)) {
            url = updateURLParameter(url, key, extraParams[key]);
        }
    }

    return url;
}

function search(baseUrl, _query, _filterCollections, extraParams) {
    let url = addParametersToUrl(baseUrl, _query, _filterCollections, extraParams);
    url = updateURLParameter(url, "page", 1);

    if (!baseUrl) {
        window.history.replaceState(null, "Dodona", url);
    }
    $("#progress-filter").css("visibility", "visible");
    $.get(url, {
        format: "js",
    }, function (data) {
        eval(data);
        $("#progress-filter").css("visibility", "hidden");
    });
}

function initFilter(baseUrl, eager, _filterCollections) {
    const filterCollections = _filterCollections || {};
    let $queryFilter = $(QUERY_FILTER_ID);
    let $tokensFilter = $(TOKENS_FILTER_ID);
    let doSearch = () => search(baseUrl, $queryFilter.typeahead("val"), filterCollections);
    $queryFilter.keyup(() => delay(doSearch, 300));
    let param = getURLParameter(FILTER_PARAM);
    if (param !== "") {
        $queryFilter.typeahead("val", param);
    }

    const allTokens = [];
    for (let type in filterCollections) {
        if (filterCollections.hasOwnProperty(type)) {
            if (filterCollections[type].multi) {
                const enabledElements = getArrayURLParameter(filterCollections[type].param);
                const mapped = filterCollections[type].data.filter(el => enabledElements.includes(`${filterCollections[type].paramVal(el)}`));
                allTokens.push(...mapped);
            } else {
                const enabledElement = getURLParameter(filterCollections[type].param);
                if (enabledElement) {
                    const mapped = filterCollections[type].data.filter(el => `${filterCollections[type].paramVal(el)}` === enabledElement)[0];
                    allTokens.push(mapped);
                }
            }
        }
    }
    $tokensFilter.tokenfield("setTokens", allTokens);

    if (eager) {
        doSearch();
    }
}

function initFilterIndex(baseUrl, eager, actions, doInitFilter, filterCollections) {
    function init() {
        initTokens();

        if (doInitFilter) {
            initFilter(baseUrl, eager, filterCollections);
        }

        if (actions) {
            initActions();
        }
    }

    function performAction(action) {
        if (action.confirm === undefined || window.confirm(action.confirm)) {
            let url = addParametersToUrl(action.action, $(QUERY_FILTER_ID).val(), filterCollections);
            $.post(url, {
                format: "json",
            }, function (data) {
                showNotification(data.message);
                if (data.js) {
                    eval(data.js);
                } else {
                    search(baseUrl);
                }
            });
        }
    }

    function performSearch(action) {
        search(baseUrl, $(QUERY_FILTER_ID).val(), filterCollections, action.search);
    }

    function initActions() {
        let $actions = $(".table-toolbar-tools .actions");
        let searchOptions = actions.filter(action => action.search);
        let searchActions = actions.filter(action => action.action || action.js);
        $actions.removeClass("hidden");
        if (searchOptions.length > 0) {
            $actions.find("ul").append("<li class='dropdown-header'>" + I18n.t("js.filter-options") + "</li>");
            searchOptions.forEach(function (action) {
                let $link = $(`<a class="action" href='#' ${action.type ? "data-type=" + action.type : ""}><i class='material-icons md-18'>${action.icon}</i>${action.text}</a>`);
                $link.appendTo($actions.find("ul"));
                $link.wrap("<li></li>");
                $link.click(() => {
                    performSearch(action);
                    return false;
                });
            });
        }
        if (searchActions.length > 0) {
            $actions.find("ul").append("<li class='dropdown-header'>" + I18n.t("js.actions") + "</li>");
            searchActions.forEach(function (action) {
                let $link = $(`<a class="action" href='#' ${action.type ? "data-type=" + action.type : ""}><i class='material-icons md-18'>${action.icon}</i>${action.text}</a>`);
                $link.appendTo($actions.find("ul"));
                $link.wrap("<li></li>");
                if (action.action) {
                    $link.click(() => {
                        performAction(action);
                        return false;
                    });
                } else {
                    $link.click(() => {
                        eval(action.js);
                        return false;
                    });
                }
            });
        }
    }


    function initTokens() {
        const $field = $(TOKENS_FILTER_ID);

        function doSearch() {
            search(baseUrl, "", filterCollections);
        }

        function validateLabel(e) {
            const collection = filterCollections[e.attrs.type];
            if (!collection) {
                return false;
            }
            return collection.data.map(el => el.name).includes(e.attrs.name);
        }

        function disableLabel() {
            // We need to delay, otherwise tokenfield hasn't finished setting all the right values
            delay(doSearch, 100);
        }

        function enableLabel(e) {
            const collection = filterCollections[e.attrs.type];

            $(e.relatedTarget).addClass(`accent-${collection.color(e.attrs)}`);
            if (!collection.multi) {
                const tokens = $field.tokenfield("getTokens");
                const newTokens = tokens
                    .filter(el => el.type !== e.attrs.type || el.name === e.attrs.name)
                    .filter((el, i, arr) => arr.map(el2 => `${el2.type}${el2.id}`).indexOf(`${el.type}${el.id}`) === i);
                if (newTokens.length !== tokens.length) {
                    $field.tokenfield("setTokens", newTokens);
                }
            }
            // We need to delay, otherwise tokenfield hasn't finished setting all the right values
            delay(doSearch, 100);
        }

        function customWhitespaceTokenizer(datum) {
            const result = Bloodhound.tokenizers.whitespace(datum);
            $.each(result, (i, val) => {
                for (let i = 1; i < val.length; i++) {
                    result.push(val.substr(i, val.length));
                }
            });
            return result;
        }

        const typeAheadOpts = [{
            highlight: true,
            minLength: 0,
        }];

        for (let type in filterCollections) {
            if (filterCollections.hasOwnProperty(type)) {
                for (let elem of filterCollections[type].data) {
                    elem.type = type;
                    elem.value = elem.name;
                }

                const engine = new Bloodhound({
                    local: filterCollections[type].data,
                    identify: d => d.id,
                    datumTokenizer: d => customWhitespaceTokenizer(d.name),
                    queryTokenizer: Bloodhound.tokenizers.whitespace,
                });

                typeAheadOpts.push({
                    source: engine,
                    display: d => d.name,
                    templates: {
                        header: `<strong class="tt-header">${I18n.t(`js.${type}`)}</strong>`,
                    },
                });
            }
        }

        $field.on("tokenfield:createtoken", validateLabel);
        $field.on("tokenfield:createdtoken", enableLabel);
        $field.on("tokenfield:removedtoken", disableLabel);
        $field.tokenfield({
            beautify: false,
            typeahead: typeAheadOpts,
        });

        function addTokenToSearch(type, name) {
            const collection = filterCollections[type];
            if (!collection) {
                return false;
            }

            const element = collection.data.filter(el => el.name === name)[0];
            if (!element) {
                return false;
            }

            $field.tokenfield("createToken", element);
        }

        dodona.addTokenToSearch = addTokenToSearch;
    }

    init();
}

export {initFilterIndex, initFilter, search};
