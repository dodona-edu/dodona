import { createDelayer, fetch, getURLParameter, updateArrayURLParameter, updateURLParameter } from "util.js";
import { InactiveTimeout } from "auto_reload";
import { LoadingBar } from "components/search/loading_bar";
import { searchQueryState } from "state/SearchQuery";
const RELOAD_SECONDS = 2;


class Search {
    autoSearch= false;
    refreshElement: string;
    periodicReload: InactiveTimeout;
    searchIndex = 0;
    appliedIndex = 0;
    loadingBars: LoadingBar[] = [];

    setRefreshElement(refreshElement: string): void {
        this.refreshElement = refreshElement;

        if (this.refreshElement) {
            this.periodicReload = new InactiveTimeout(
                document.querySelector(this.refreshElement),
                RELOAD_SECONDS * 1000,
                () => {
                    this.search();
                }
            );
            this.toggleRefresh();
        } else {
            this.periodicReload = undefined;
        }
    }

    setBaseUrl(baseUrl?: string): void {
        searchQueryState.baseUrl = baseUrl;
    }

    setLocalStorageKey(localStorageKey: string): void {
        searchQueryState.localStorageKey = localStorageKey;
    }

    initPagination(): void {
        const remotePaginationButtons = document.querySelectorAll(".page-link[data-remote=true]");
        remotePaginationButtons.forEach(button => button.addEventListener("click", () => {
            const href = button.getAttribute("href");
            const page = getURLParameter("page", href);
            searchQueryState.queryParams.set("page", page);
        }));
    }

    constructor() {
        // subscribe relevant listeners
        searchQueryState.arrayQueryParams.subscribe((s, k) => this.paramChange(k));
        searchQueryState.queryParams.subscribe((s, k) => this.paramChange(k));
        searchQueryState.queryParams.subscribe( () => this.toggleRefresh(), "refresh");
    }

    private toggleRefresh(): void {
        if (this.periodicReload) {
            if (searchQueryState.queryParams.get("refresh") === "true") {
                this.periodicReload.start();
            } else {
                this.periodicReload.end();
            }
        }
    }

    updateHistory(push: boolean): void {
        if (!searchQueryState.updateAddressBar) {
            return;
        }
        const url = searchQueryState.addParametersToUrl();
        if (url === window.location.href) {
            return;
        }
        if (push) {
            window.history.pushState("set_by_search", "Dodona", url);
        } else {
            window.history.replaceState("set_by_search", "Dodona", url);
        }
    }

    paramChangeDelayer = createDelayer();
    changedParams = [];
    paramChange(key?: string): void {
        this.changedParams.push(key);
        this.paramChangeDelayer(() => {
            if (searchQueryState.queryParams.get("page") !== undefined && searchQueryState.queryParams.get("page") !== "1" && this.changedParams.every(k => k !== "page")) {
                // if we were not on the first page and we changed something else than the page, we should go back to the first page
                this.changedParams = [];
                searchQueryState.queryParams.set("page", "1");
                return;
            }
            this.updateHistory(this.changedParams.some(k => k === "page"));
            if (this.autoSearch) {
                this.search();
            }
            this.changedParams = [];
        }, 100);
    }

    search(): void {
        const url = searchQueryState.addParametersToUrl();
        const localIndex = ++this.searchIndex;

        this.loadingBars.forEach(bar => bar.show());
        fetch(updateURLParameter(url, "format", "js"), {
            headers: {
                "accept": "text/javascript"
            },
            credentials: "same-origin",
        })
            .then(resp => resp.text())
            .then(data => {
                if (this.appliedIndex < localIndex) {
                    this.appliedIndex = localIndex;
                    eval(data);
                }
                this.loadingBars.forEach(bar => bar.hide());

                // if there is local storage key => update the value to reuse later
                if (searchQueryState.localStorageKey) {
                    const urlObj = new URL(url);
                    localStorage.setItem(searchQueryState.localStorageKey, urlObj.searchParams.toString());
                }
            });
    }
}

export const search = new Search();
