import { createDelayer, fetch, updateArrayURLParameter, updateURLParameter } from "util.js";


export class QueryParameters<T> {
    params: Map<string, T> = new Map();
    listeners_by_key: Map<string, Array<(k: string, o: T, n: T)=>void>> = new Map();
    listeners: Array<(k: string, o: T, n: T)=>void> = [];

    resetParams(): void {
        this.params.forEach((v, k) => {
            if (v !== undefined) {
                this.updateParam(k, undefined);
            }
        });
    }

    updateParam(key: string, value: T ): void {
        const old: T = this.params.get(key);
        this.params.set(key, value);

        this.listeners.forEach(f => f(key, old, value));
        const listeners = this.listeners_by_key.get(key);
        if (listeners) {
            listeners.forEach(f => f(key, old, value));
        }
    }

    subscribeByKey(key: string, listener: (k: string, o: T, n: T)=>void): void {
        const listeners = this.listeners_by_key.get(key);
        if (listeners) {
            listeners.push(listener);
        } else {
            this.listeners_by_key.set(key, [listener]);
        }
    }

    subscribe(listener: (k: string, o: T, n: T)=>void): void {
        this.listeners.push(listener);
    }
}

export class SearchQuery {
    baseUrl: string;
    searchIndex = 0;
    appliedIndex = 0;
    array_query_params: QueryParameters<string[]> = new QueryParameters<string[]>();
    query_params: QueryParameters<string> = new QueryParameters<string>();

    constructor(baseUrl?: string) {
        const _url = baseUrl || window.location.href;
        const url = new URL(_url.replace(/%5B%5D/g, "[]"), window.location.origin);
        this.baseUrl = url.href;
        for (const key of url.searchParams.keys()) {
            if (key.endsWith("[]")) {
                this.array_query_params.updateParam(key.substring(0, -2), url.searchParams.getAll(key));
            } else {
                this.query_params.updateParam(key, url.searchParams.get(key));
            }
        }
        const delay = createDelayer();
        this.array_query_params.subscribe(k => delay(() => this.search(k), 100));
        this.query_params.subscribe(k => delay(() => this.search(k), 100));
    }

    addParametersToUrl(baseUrl?: string): string {
        let url: string = baseUrl || this.baseUrl;
        this.query_params.params.forEach((v, k) => url = updateURLParameter(url, k, v));
        this.array_query_params.params.forEach((v, k) => url = updateArrayURLParameter(url, k, v));

        return url;
    }

    resetAllQueryParams(): void {
        this.query_params.resetParams();
        this.array_query_params.resetParams();
    }

    search(key?: string): void {
        if (key === "page") {
            return;
        }
        this.query_params.updateParam("page", "1");

        const url = this.addParametersToUrl();
        const localIndex = ++this.searchIndex;

        // TODO CHECK REASON FOR if (updateAddressBar)
        window.history.replaceState(null, "Dodona", url);
        document.getElementById("progress-filter").style.visibility = "visible";
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
                document.getElementById("progress-filter").style.visibility = "hidden";
            });
    }
}

dodona.search_query = new SearchQuery();
