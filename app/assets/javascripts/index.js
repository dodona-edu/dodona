/* globals Bloodhound */
import { Toast } from "./toast";
import {
    delay,
    getArrayURLParameter,
    getURLParameter,
    updateArrayURLParameter,
    updateURLParameter,
    fetch
} from "./util.js";
import { InactiveTimeout } from "./auto_reload";

const FILTER_PARAM = "filter";
const TOKENS_FILTER_ID = "#filter-query";
const QUERY_FILTER_ID = "#filter-query-tokenfield";

/* constants for element-keys that are used when filtering */
const FILTER_ICONS_CLASS = ".filter-icon";
const FILTER_DATA = "filter";

const LABEL_UNIQUE_ATTR = "label-id";
const RELOAD_SECONDS = 2;

window.dodona.index = {};
window.dodona.index.baseUrl = window.location.href;
window.dodona.index.periodicReload = null;
window.dodona.index.doSearch = () => { };

function setBaseUrl(_baseUrl) {
    window.dodona.index.baseUrl = _baseUrl;
    window.dodona.index.doSearch();
}

function initFilterIndex(_baseUrl, eager, actions, doInitFilter, filterCollections, refreshElement = null) {
    const updateAddressBar = !_baseUrl;

    function init() {
        initTokens();

        if (doInitFilter) {
            initFilter(updateAddressBar, _baseUrl, eager, filterCollections);
        }

        if (actions) {
            initActions();
        }

        initRefresh();
    }

    function addParametersToUrl(baseUrl, _query, _filterCollections, _extraParams) {
        const filterCollections = _filterCollections || {};
        const query = _query || $(QUERY_FILTER_ID).val();
        const extraParams = _extraParams || {};

        let url = updateURLParameter(baseUrl || window.location.href, FILTER_PARAM, query);

        const tokens = $(TOKENS_FILTER_ID).tokenfield("getTokens");
        Object.entries(filterCollections).forEach(([type, value]) => {
            if (value.multi) {
                url = updateArrayURLParameter(
                    url,
                    value.param,
                    tokens.filter(el => el.type === type).map(e => value.paramVal(e))
                );
            } else {
                const elem = tokens.filter(e => e.type === type)[0];
                url = updateURLParameter(url, value.param, elem ? value.paramVal(elem) : "");
            }
        });
        Object.entries(extraParams).forEach(([key, value]) => {
            url = updateURLParameter(url, key, value);
        });

        return url;
    }

    let searchIndex = 0;
    let appliedIndex = 0;

    function search(updateAddressBar, baseUrl, _query, _filterCollections, extraParams) {
        let url = addParametersToUrl(baseUrl, _query, _filterCollections, extraParams);
        url = updateURLParameter(url, "page", 1);

        const localIndex = ++searchIndex;

        if (updateAddressBar) {
            window.history.replaceState(null, "Dodona", url);
        }
        $("#progress-filter").css("visibility", "visible");
        fetch(updateURLParameter(url, "format", "js"), {
            headers: {
                "accept": "text/javascript"
            },
            credentials: "same-origin",
        })
            .then(resp => resp.text())
            .then(data => {
                if (appliedIndex < localIndex) {
                    appliedIndex = localIndex;
                    eval(data);
                }
                $("#progress-filter").css("visibility", "hidden");
            });
    }

    function initFilter(updateAddressBar, _baseUrl, eager, _filterCollections) {
        window.dodona.index.baseUrl = _baseUrl || window.location.href;
        const filterCollections = _filterCollections || {};
        const $queryFilter = $(QUERY_FILTER_ID);
        window.dodona.index.doSearch = () =>
            search(
                updateAddressBar,
                window.dodona.index.baseUrl,
                $queryFilter.typeahead("val"),
                filterCollections
            );
        $queryFilter.keyup(() => delay(window.dodona.index.doSearch, 300));
        const param = getURLParameter(FILTER_PARAM);
        if (param !== "") {
            $queryFilter.typeahead("val", param);
        }

        if (eager) {
            window.dodona.index.doSearch();
        }
    }

    function performAction(action) {
        if (action.confirm === undefined || window.confirm(action.confirm)) {
            const url = addParametersToUrl(
                action.action,
                $(QUERY_FILTER_ID).val(),
                filterCollections
            );
            $.post(
                url,
                { format: "json" },
                function (data) {
                    new Toast(data.message);
                    if (data.js) {
                        eval(data.js);
                    } else {
                        search(updateAddressBar, window.dodona.index.baseUrl);
                    }
                }
            );
        }
    }

    function urlContainsSearchOpt(searchOption) {
        const url = window.dodona.index.baseUrl || window.location.href;
        // If the parameters were already contained, the length shouldn't change.
        // Note that we can't just compare the urls, since the position of the parameters might change.
        return (
            addParametersToUrl(url, undefined, undefined, searchOption.search).length === url.length
        );
    }

    function initActions() {
        const $actions = $(".table-toolbar-tools .actions");
        const searchOptions = actions.filter(action => action.search);
        const searchActions = actions.filter(action => action.url || action.action || action.js);

        function performSearch() {
            const extraParams = {};
            searchOptions.forEach((opt, id) => {
                if (
                    $(`a.action[data-search_opt_id="${id}"]`)
                        .find("i")
                        .hasClass("mdi-checkbox-marked-outline")
                ) {
                    Object.entries(opt.search).forEach(([key, value]) => {
                        extraParams[key] = value;
                    });
                } else {
                    Object.keys(opt.search).forEach(key => {
                        extraParams[key] = null;
                    });
                }
            });
            // Update the search function with the new params.
            window.dodona.index.doSearch = () => {
                search(
                    updateAddressBar,
                    window.dodona.index.baseUrl,
                    $(QUERY_FILTER_ID).val(),
                    filterCollections,
                    extraParams
                );
            };
            window.dodona.index.doSearch();
        }

        $actions.removeClass("hidden");
        if (searchOptions.length > 0) {
            $actions
                .find("ul")
                .append("<li class='dropdown-header'>" + I18n.t("js.options") + "</li>");
            searchOptions.forEach(function (action, id) {
                const $link = $(
                    `<a class="action" href='#' ${
                        action.type ? "data-type=" + action.type : ""
                    } data-search_opt_id="${id}">${
                        action.text
                    }<i class='mdi mdi-checkbox-blank-outline mdi-18 mdi-box'></i></a>`
                );
                $link.appendTo($actions.find("ul"));
                $link.wrap("<li></li>");
                if (urlContainsSearchOpt(action)) {
                    $link.find("i")
                        .removeClass("mdi-checkbox-blank-outline")
                        .addClass("mdi-checkbox-marked-outline");
                }
                $link.click(() => {
                    const child = $link.find("i");
                    if (child.hasClass("mdi-checkbox-blank-outline")) {
                        child.removeClass("mdi-checkbox-blank-outline")
                            .addClass("mdi-checkbox-marked-outline");
                    } else {
                        child.removeClass("mdi-checkbox-marked-outline")
                            .addClass("mdi-checkbox-blank-outline");
                    }
                    if (action.click) {
                        eval(action.click);
                    }
                    performSearch();
                    return false;
                });
            });
        }
        if (searchActions.length > 0) {
            $actions
                .find("ul")
                .append("<li class='dropdown-header'>" + I18n.t("js.actions") + "</li>");
            searchActions.forEach(function (action) {
                const $link = $(
                    `<a class="action" href='${
                        action.url ? action.url : "#"
                    }' ${
                        action.type ? "data-type=" + action.type : ""
                    }><i class='mdi mdi-${action.icon} mdi-18'></i>${action.text}</a>`
                );
                $link.appendTo($actions.find("ul"));
                $link.wrap("<li></li>");
                if (action.action) {
                    $link.click(() => {
                        performAction(action);
                        return false;
                    });
                } else if (action.js) {
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

        let doSearch = function () {
            search(updateAddressBar, window.dodona.index.baseUrl, "", filterCollections);
        };

        function validateLabel(e) {
            const collection = filterCollections[e.attrs.type];
            if (!collection) {
                return false;
            }
            // check whether we have a label for the input
            let valid = collection.data.map(el => el.name).includes(e.attrs.name);
            if (valid && collection.multi) {
                // if multi, we can have multiple labels but we do not want duplication
                // therefore we use an id to distinguish labels and prevent the same label from appearing twice
                const newElementId = e.attrs.id.toString(); // ensure comparison is String-based
                // The labels have the token html class so we obtain all labels via this query
                valid = $(".token").filter(function (_index, el) {
                    // check if a label with this id is not yet present
                    return newElementId === $(el).attr(LABEL_UNIQUE_ATTR);
                }).length === 0;
            }
            return valid;
        }

        function disableLabel() {
            // We need to delay, otherwise tokenfield hasn't finished setting all the right values
            delay(doSearch, 100);
        }

        function enableLabel(e) {
            const collection = filterCollections[e.attrs.type];
            $(e.relatedTarget).addClass(`accent-${collection.color(e.attrs)}`)
            // add an attribute to identify duplicate labels in the suggestions @see validateLabel
                .attr(LABEL_UNIQUE_ATTR, e.attrs.id);
            if (!collection.multi) {
                const tokens = $field.tokenfield("getTokens");
                const newTokens = tokens
                    .filter(el => el.type !== e.attrs.type || el.name === e.attrs.name)
                    .filter(
                        (el, i, arr) =>
                            i === arr.map(el2 => `${el2.type}${el2.id}`).indexOf(`${el.type}${el.id}`)
                    );
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

        const typeAheadOpts = [
            {
                highlight: true,
                minLength: 0,
            },
        ];

        Object.entries(filterCollections).forEach(([type, value]) => {
            for (const elem of value.data) {
                elem.type = type;
                elem.value = elem.name;
            }

            const engine = new Bloodhound({
                local: value.data,
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
        });

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

        // Temporarily disable automatic searching when adding new labels
        const temp = doSearch;
        doSearch = () => { };
        const allTokens = [];
        Object.values(filterCollections).forEach(value => {
            if (value.multi) {
                const enabledElements = getArrayURLParameter(value.param);
                const mapped = value.data.filter(el =>
                    enabledElements.includes(`${value.paramVal(el)}`)
                );
                allTokens.push(...mapped);
            } else {
                const enabledElement = getURLParameter(value.param);
                if (enabledElement) {
                    const mapped = value.data.filter(
                        el => `${value.paramVal(el)}` === enabledElement
                    )[0];
                    allTokens.push(mapped);
                }
            }
        });
        $field.tokenfield("setTokens", allTokens);
        doSearch = temp;
    }

    function initRefresh() {
        if (refreshElement) {
            window.dodona.index.periodicReload = new InactiveTimeout(
                document.querySelector(refreshElement),
                RELOAD_SECONDS * 1000,
                () => {
                    // Don't pass the function directly, since that doesn't update.
                    window.dodona.index.doSearch();
                }
            );
            if (getURLParameter("refresh") === "true") {
                window.dodona.index.periodicReload.start();
            }
        }
    }

    init();
}

function initFilterButtons() {
    function init() {
        const $filterButtons = $(FILTER_ICONS_CLASS);
        $filterButtons.click(filter);
        $filterButtons.tooltip(); // initialize the tooltips of the buttons
    }

    function filter() {
        const $element = $(this);
        const $searchbar = $(QUERY_FILTER_ID);
        $searchbar.typeahead("val", $element.data(FILTER_DATA)); // search for value requested by user
        $(".tooltip").tooltip("hide"); // prevent tooltip from displaying when table is re-rendered
        window.dodona.index.doSearch();
    }

    init();
}


function toggleIndexReload() {
    const loader = window.dodona.index.periodicReload;
    if (loader !== null) {
        if (loader.isStarted()) {
            loader.end();
        } else {
            loader.start();
        }
    }
}

export { initFilterButtons, initFilterIndex, setBaseUrl, toggleIndexReload };
