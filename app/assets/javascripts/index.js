/* globals I18n,Bloodhound */
import {showNotification} from "./notifications.js";
import {delay, updateURLParameter, updateArrayURLParameter, getURLParameter, getArrayURLParameter} from "./util.js";

let PARAM = "filter";
let LABELS_FILTER_ID = "#filter-query";
let QUERY_FILTER_ID = "#filter-query-tokenfield";

function search(baseUrl, _query) {
    let getUrl = () => baseUrl || window.location.href;
    let query = _query || $(QUERY_FILTER_ID).val();
    let url = updateURLParameter(getUrl(), PARAM, query);
    url = updateURLParameter(url, "page", 1);
    if ($(LABELS_FILTER_ID).val() !== "") {
        url = updateArrayURLParameter(url, "labels", $(LABELS_FILTER_ID).val().split(","));
    }
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

function initFilter(baseUrl, eager) {
    let $queryFilter = $(QUERY_FILTER_ID);
    let $labelsFilter = $(LABELS_FILTER_ID);
    let doSearch = () => search(baseUrl, $queryFilter.typeahead("val"));
    $queryFilter.keyup(() => delay(doSearch, 300));
    let param = getURLParameter(PARAM);
    let labels = getArrayURLParameter("labels");
    $labelsFilter.tokenfield("setTokens", labels);
    if (param !== "") {
        $queryFilter.typeahead("val", param);
    }
    if (eager) {
        doSearch();
    }
}

function initFilterIndex(baseUrl, eager, actions, doInitFilter, labels) {
    function init() {
        initLabels();

        if (doInitFilter) {
            initFilter(baseUrl, eager);
        }

        if (actions) {
            initActions();
        }
    }

    function performAction(action, $filter) {
        if (action.confirm === undefined || window.confirm(action.confirm)) {
            let val = $filter.val();
            let url = updateURLParameter(action.action, PARAM, val);
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
        console.log(searchParams);
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
        const colorMap = {};
        for (let label of labels) {
            colorMap[label.name] = label.color;
            label.value = label.name;
        }

        function doSearch() {
            search(baseUrl);
        }

        function validateLabel(e) {
            return labels.map(l => l.name).indexOf(e.attrs.value) >= 0;
        }

        function disableLabel(e) {
            delay(doSearch, 100);
        }

        function enableLabel(e) {
            $(e.relatedTarget).addClass(`accent-${colorMap[e.attrs.value]}`);
            delay(doSearch, 100);
        }


        const engine = new Bloodhound({
            local: labels,
            identify: d => d.id,
            datumTokenizer: d => {
                const result = Bloodhound.tokenizers.whitespace(d.name);
                $.each(result, (i, val) => {
                    for (let i = 1; i < val.length; i++) {
                        result.push(val.substr(i, val.length));
                    }
                });
                return result;
            },
            queryTokenizer: Bloodhound.tokenizers.whitespace,
        });

        const $field = $(LABELS_FILTER_ID);
        $field.on("tokenfield:createtoken", validateLabel);
        $field.on("tokenfield:createdtoken", enableLabel);
        $field.on("tokenfield:removedtoken", disableLabel);
        $field.tokenfield({
            beautify: false,
            typeahead: [{
                highlight: true,
            }, {
                source: engine,
                display: d => d.name,
            }],
        });
    }

    init();
}

export {initFilterIndex, initFilter, search};
