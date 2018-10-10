/* globals I18n,Bloodhound */
import {showNotification} from "./notifications.js";
import {delay, updateURLParameter, updateArrayURLParameter, getURLParameter, getArrayURLParameter} from "./util.js";

const FILTER_PARAM = "filter";
const LABELS_PARAM = "labels";
const PROGRAMMING_LANGUAGE_PARAM = "programming_language";
const REPOSITORY_PARAM = "repository_id";
const LABELS_FILTER_ID = "#filter-query";
const QUERY_FILTER_ID = "#filter-query-tokenfield";

function search(baseUrl, _query) {
    let getUrl = () => baseUrl || window.location.href;
    let query = _query || $(QUERY_FILTER_ID).val();
    let url = updateURLParameter(getUrl(), FILTER_PARAM, query);
    url = updateURLParameter(url, "page", 1);
    url = updateArrayURLParameter(url, LABELS_PARAM, $(LABELS_FILTER_ID).tokenfield("getTokens").filter(e => e.type === "label").map(e => e.name));
    let programmingLanguage = $(LABELS_FILTER_ID).tokenfield("getTokens").filter(e => e.type === "programmingLanguage")[0];
    url = updateURLParameter(url, PROGRAMMING_LANGUAGE_PARAM, programmingLanguage ? programmingLanguage.name : "");
    let repository = $(LABELS_FILTER_ID).tokenfield("getTokens").filter(e => e.type === "repository")[0];
    url = updateURLParameter(url, REPOSITORY_PARAM, repository ? repository.id : "");
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

function initFilter(baseUrl, eager, _labels, _programmingLanguages, _repositories) {
    const labels = _labels || [];
    const programmingLanguages = _programmingLanguages || [];
    const repositories = _repositories || [];
    let $queryFilter = $(QUERY_FILTER_ID);
    let $labelsFilter = $(LABELS_FILTER_ID);
    let doSearch = () => search(baseUrl, $queryFilter.typeahead("val"));
    $queryFilter.keyup(() => delay(doSearch, 300));
    let param = getURLParameter(FILTER_PARAM);
    let enabledLabels = getArrayURLParameter(LABELS_PARAM);
    let enabledProgrammingLanguage = getURLParameter(PROGRAMMING_LANGUAGE_PARAM);
    let enabledRepository = getURLParameter(REPOSITORY_PARAM);
    let allTokens = [];
    for (let enabledLabel of enabledLabels) {
        let label = labels.filter(l => l.name === enabledLabel)[0];
        if (label) {
            allTokens.push(label);
        }
    }
    let programmingLanguage = programmingLanguages.filter(p => p.name === enabledProgrammingLanguage)[0];
    if (programmingLanguage) {
        allTokens.push(programmingLanguage);
    }
    let repository = repositories.filter(r => `${r.id}` === enabledRepository)[0];
    if (repository) {
        allTokens.push(repository);
    }
    $labelsFilter.tokenfield("setTokens", allTokens);
    if (param !== "") {
        $queryFilter.typeahead("val", param);
    }
    if (eager) {
        doSearch();
    }
}

function initFilterIndex(baseUrl, eager, actions, doInitFilter, labels, programmingLanguages, repositories) {
    function init() {
        initLabels();

        if (doInitFilter) {
            initFilter(baseUrl, eager, labels, programmingLanguages, repositories);
        }

        if (actions) {
            initActions();
        }
    }

    function performAction(action, $filter) {
        if (action.confirm === undefined || window.confirm(action.confirm)) {
            let val = $filter.val();
            let url = updateURLParameter(action.action, FILTER_PARAM, val);
            $.post(url, {
                format: "json",
            }, function (data) {
                showNotification(data.message);
                if (data.js) {
                    eval(data.js);
                } else {
                    search(baseUrl, $filter.val());
                }
            });
        }
    }

    function performSearch(action, $filter) {
        let url = baseUrl;
        let searchParams = Object.entries(action.search);
        for (let i = 0; i < searchParams.length; i++) {
            let key = searchParams[i][0];
            let value = searchParams[i][1];
            url = updateURLParameter(url, key.toString(), value.toString());
        }
        search(url, "");
    }

    function initActions() {
        let $actions = $(".table-toolbar-tools .actions");
        let $filter = $(QUERY_FILTER_ID);
        let searchOptions = actions.filter(action => action.search);
        let searchActions = actions.filter(action => action.action);
        $actions.removeClass("hidden");
        if (searchOptions.length > 0) {
            $actions.find("ul").append("<li class='dropdown-header'>" + I18n.t("js.filter-options") + "</li>");
            searchOptions.forEach(function (action) {
                let $link = $(`<a class="action" href='#'><i class='material-icons md-18'>${action.icon}</i>${action.text}</a>`);
                $link.appendTo($actions.find("ul"));
                $link.wrap("<li></li>");
                $link.click(() => {
                    performSearch(action, $filter);
                    return false;
                });
            });
        }
        if (searchActions.length > 0) {
            $actions.find("ul").append("<li class='dropdown-header'>" + I18n.t("js.actions") + "</li>");
            searchActions.forEach(function (action) {
                let $link = $(`<a class="action" href='#'><i class='material-icons md-18'>${action.icon}</i>${action.text}</a>`);
                $link.appendTo($actions.find("ul"));
                $link.wrap("<li></li>");
                $link.click(() => {
                    performAction(action, $filter);
                    return false;
                });
            });
        }
    }


    function initLabels() {
        const $field = $(LABELS_FILTER_ID);

        const colorMap = {};
        for (let label of labels) {
            colorMap[label.name] = label.color;
            label.value = label.name;
            label.type = "label";
        }

        for (let programmingLanguage of programmingLanguages) {
            programmingLanguage.value = programmingLanguage.name;
            programmingLanguage.type = "programmingLanguage";
        }

        for (let repository of repositories) {
            repository.value = repository.name;
            repository.type = "repository";
        }

        function doSearch() {
            search(baseUrl);
        }

        function validateLabel(e) {
            if (e.attrs.type === "label") {
                return labels.map(l => l.name).includes(e.attrs.value);
            } else if (e.attrs.type === "programmingLanguage") {
                return programmingLanguages.map(p => p.name).includes(e.attrs.value);
            } else if (e.attrs.type === "repository") {
                return repositories.map(r => r.name).includes(e.attrs.value)
            } else {
                return false;
            }
        }

        function disableLabel() {
            // We need to delay, otherwise tokenfield hasn't finished setting all the right values
            delay(doSearch, 100);
        }

        function enableLabel(e) {
            if (e.attrs.type === "label") {
                $(e.relatedTarget).addClass(`accent-${colorMap[e.attrs.value]}`);
            } else if (e.attrs.type === "programmingLanguage") {
                $(e.relatedTarget).addClass("accent-teal");
                const newTokens = $field.tokenfield("getTokens")
                    .filter(el => el.type !== "programmingLanguage" || el.name === e.attrs.value)
                    .filter((el, i, arr) => arr.map(el => `${el.type}${el.id}`).indexOf(`${el.type}${el.id}`) === i);
                if (newTokens.length !== $field.tokenfield("getTokens").length) {
                    $field.tokenfield("setTokens", newTokens);
                }
            } else if (e.attrs.type === "repository") {
                $(e.relatedTarget).addClass("accent-blue-grey");
                const newTokens = $field.tokenfield("getTokens")
                    .filter(el => el.type !== "repository" || el.name === e.attrs.value)
                    .filter((el, i, arr) => arr.map(el => `${el.type}${el.id}`).indexOf(`${el.type}${el.id}`) === i);
                if (newTokens.length !== $field.tokenfield("getTokens").length) {
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

        const labelEngine = new Bloodhound({
            local: labels,
            identify: d => d.id,
            datumTokenizer: d => customWhitespaceTokenizer(d.name),
            queryTokenizer: Bloodhound.tokenizers.whitespace,
        });

        const programmingLanguageEngine = new Bloodhound({
            local: programmingLanguages,
            identify: d => d.id,
            datumTokenizer: d => customWhitespaceTokenizer(d.name),
            queryTokenizer: Bloodhound.tokenizers.whitespace,
        });

        const repositoryEngine = new Bloodhound({
            local: repositories,
            identify: d => d.id,
            datumTokenizer: d => customWhitespaceTokenizer(d.name),
            queryTokenizer: Bloodhound.tokenizers.whitespace,
        });

        $field.on("tokenfield:createtoken", validateLabel);
        $field.on("tokenfield:createdtoken", enableLabel);
        $field.on("tokenfield:removedtoken", disableLabel);
        $field.tokenfield({
            beautify: false,
            typeahead: [{
                highlight: true,
                minLength: 0,
            }, {
                source: labelEngine,
                display: d => d.name,
                templates: {
                    header: `<strong class="tt-header">${I18n.t("js.labels")}</strong>`,
                },
            }, {
                source: programmingLanguageEngine,
                display: d => d.name,
                templates: {
                    header: `<strong class="tt-header">${I18n.t("js.programming-languages")}</strong>`,
                },
            }, {
                source: repositoryEngine,
                display: d => d.name,
                templates: {
                    header: `<strong class="tt-header">${I18n.t("js.repositories")}</strong>`,
                },
            }],
        });
    }

    init();
}

export {initFilterIndex, initFilter, search};
