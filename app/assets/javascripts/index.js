/* globals I18n */
import {showNotification} from "./notifications.js";
import {delay, updateURLParameter, updateArrayURLParameter, getURLParameter, getArrayURLParameter} from "./util.js";

let PARAM = "filter";
let FILTER_ID = "#filter-query";

const {initFilterIndex, initFilter, search} = (() => {
    const enabledTags = [];

    function search(baseUrl, _query) {
        let getUrl = () => baseUrl || window.location.href;
        let query = _query || $(FILTER_ID).val();
        let url = updateURLParameter(getUrl(), PARAM, query);
        url = updateURLParameter(url, "page", 1);
        url = updateArrayURLParameter(url, "tags", enabledTags);
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
        let $filter = $(FILTER_ID);
        let doSearch = () => search(baseUrl, $filter.val());
        $filter.off("keyup"); // Remove previous handler
        $filter.on("keyup", function () {
            delay(doSearch, 300);
        });
        let param = getURLParameter(PARAM);
        let tags = getArrayURLParameter("tags");
        for (let tag of tags) {
            enabledTags.push(tag);
        }
        if (param !== "") {
            $filter.val(param);
        }
        if (eager) {
            doSearch();
        }
    }

    function initFilterIndex(baseUrl, eager, actions, doInitFilter, taggable) {
        function init() {
            if (doInitFilter) {
                initFilter(baseUrl, eager);
            }

            if (actions) {
                initActions();
            }

            if (taggable) {
                initTags();
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
                console.log(key);
                console.log(value);
                url = updateURLParameter(url, key.toString(), value.toString());
            }
            search(url, "");
        }

        function initActions() {
            let $actions = $(".table-toolbar-tools .actions");
            let $filter = $(FILTER_ID);
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


        function initTags() {
            function disableTag() {
                const $tag = $(this);
                const name = $tag.data("tag-name");
                $tag.off("click");
                $tag.click(enableTag);
                $tag.removeClass("enabled");
                const index = enabledTags.indexOf(name);
                if (index >= 0) {
                    enabledTags.splice(index, 1);
                }
                search(baseUrl);
                return false;
            }

            function enableTag() {
                const $tag = $(this);
                $tag.off("click");
                $tag.click(disableTag);
                $tag.addClass("enabled");
                const name = $tag.data("tag-name");
                enabledTags.push(name);
                search(baseUrl);
                return false;
            }

            const tags = document.querySelectorAll(".tag-label");
            for (let tag of tags) {
                const $tag = $(tag);
                const name = $tag.data("tag-name");
                if (enabledTags.indexOf(name) >= 0) {
                    $tag.addClass("enabled");
                    $tag.click(disableTag);
                } else {
                    $tag.click(enableTag);
                }
            }
        }

        init();
    }

    return {search, initFilter, initFilterIndex};
})();

export {initFilterIndex, initFilter, search};
