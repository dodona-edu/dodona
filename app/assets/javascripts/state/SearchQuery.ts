import { State } from "state/state_system/State";
import { StateMap } from "state/state_system/StateMap";
import { updateArrayURLParameter, updateURLParameter } from "utilities";

class SearchQueryState extends State {
    readonly arrayQueryParams: StateMap<string, string[]> = new StateMap();
    readonly queryParams: StateMap<string, string> = new StateMap();

    updateAddressBar = true;
    private _baseUrl: string;
    get baseUrl(): string {
        return this._baseUrl;
    }

    set baseUrl(value: string) {
        this.updateAddressBar = value === undefined || value === "";
        const _url = value || window.location.href;
        const url = new URL(_url.replace(/%5B%5D/g, "[]"), window.location.origin);
        this._baseUrl = url.href;

        // initialise present parameters
        this.initialiseParams(url.searchParams);
    }


    private _localStorageKey: string;
    /**
     * fetch params from localStorage using the localStorageKey
     */
    set localStorageKey(value: string) {
        this._localStorageKey = value;
        if (value) {
            const searchParamsStringFromStorage = localStorage.getItem(value);
            if (searchParamsStringFromStorage) {
                const searchParamsFromStorage = new URLSearchParams(searchParamsStringFromStorage);
                this.initialiseParams(searchParamsFromStorage);
            }
        }
    }

    get localStorageKey(): string {
        return this._localStorageKey;
    }

    constructor() {
        super();
        this.baseUrl = undefined;

        window.onpopstate = e => {
            if (this.updateAddressBar && e.state === "set_by_search") {
                this.arrayQueryParams.clear();
                this.queryParams.clear();
                this.baseUrl = undefined;
            }
        };

        window.history.replaceState("set_by_search", "Dodona");
    }

    addParametersToUrl(baseUrl?: string): string {
        let url: string = baseUrl || this.baseUrl;
        this.queryParams.forEach((v, k) => url = updateURLParameter(url, k, v));
        this.arrayQueryParams.forEach((v, k) => url = updateArrayURLParameter(url, k, v));

        return url;
    }

    /**
     * @param {URLSearchParams} searchParams the obj whose params we want to use
     *
     * apply the param values from the URLSearchParams obj to the current queryParams and arrayQueryParams
     */
    private initialiseParams(searchParams: URLSearchParams) : void {
        for (const key of searchParams.keys()) {
            if (SearchQueryState.isArrayQueryParamsKey(key)) {
                this.arrayQueryParams.set(SearchQueryState.extractArrayQueryParamsKey(key), searchParams.getAll(key));
            } else {
                this.queryParams.set(key, searchParams.get(key));
            }
        }
    }

    /**
     *
     * @param {string} key the key value stored in the url
     * @private
     * @return {boolean} true if the key ends with [] otherwise false
     */
    private static isArrayQueryParamsKey(key: string): boolean {
        return key.endsWith("[]");
    }

    /**
     *
     * @param {string} key the key value stored in the url
     * @private
     * @return {string} the key without the [] at the end
     */
    private static extractArrayQueryParamsKey(key: string): string {
        return key.substring(0, key.length-2);
    }
}

export const searchQueryState = new SearchQueryState();
