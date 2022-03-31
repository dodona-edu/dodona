import "search.ts";
import { html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

export class SortQuery {
    active_column: string;
    ascending: boolean;
    listeners: Array<(c: string, a: boolean) => void> = [];

    constructor() {
        const sortParams = [...dodona.search_query.query_params.params.entries()].filter(
            ([k, v]) => k.startsWith("order_by_") && (v=== "ASC" || v === "DESC")
        );

        if (sortParams.length > 0) {
            this.active_column = sortParams[0][0].substring(9);
            this.ascending = sortParams[0][1] === "ASC";
            sortParams.slice(1).forEach(([k, _]) => {
                dodona.search_query.query_params.updateParam(k, undefined);
            });
        }
        dodona.search_query.query_params.subscribe((k, o, n) => {
            if (
                k.startsWith("order_by_") &&
                !(k === this.getQueryKey() && n === this.getQueryValue()) &&
                (n === "ASC" || n === "DESC")
            ) {
                this.active_column = k.substring(9);
                this.ascending = n === "ASC";
                this.notify();
            }
        });
    }

    getQueryKey(): string {
        return "order_by_" + this.active_column;
    }

    getQueryValue(): string {
        return this.ascending ? "ASC" : "DESC";
    }

    subscribe(listener: (c: string, a: boolean) => void): void {
        this.listeners.push(listener);
    }

    notify(): void {
        this.listeners.forEach(f => f(this.active_column, this.ascending));
    }

    sortBy(column: string, ascending: boolean): void {
        if (this.active_column === column && this.ascending === ascending) {
            return;
        }

        if (this.active_column !== column) {
            dodona.search_query.query_params.updateParam(this.getQueryKey(), undefined);
            this.active_column = column;
        }
        this.ascending = ascending;
        this.notify();
        if (this.active_column) {
            dodona.search_query.query_params.updateParam(this.getQueryKey(), this.getQueryValue());
        }
    }
}
dodona.state = {};
dodona.state.sort_query = new SortQuery();

@customElement("dodona-sort-button")
export class SortButton extends LitElement {
    @property({ type: String })
        column: string;

    active_column: string;
    ascending: boolean;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    isActive(): boolean {
        return this.column === this.active_column;
    }

    getSortIcon(): string {
        return this.isActive() ? this.ascending ? "sort-ascending" : "sort-descending" : "sort";
    }

    sort(): void {
        if (!this.isActive()) {
            dodona.state.sort_query.sortBy(this.column, true);
        } else if (this.ascending) {
            dodona.state.sort_query.sortBy(this.column, false);
        } else {
            dodona.state.sort_query.sortBy(undefined, undefined);
        }
    }

    constructor() {
        super();
        this.ascending = dodona.state.sort_query.ascending;
        this.active_column = dodona.state.sort_query.active_column;
        dodona.state.sort_query.subscribe((c, a) => {
            this.active_column = c;
            this.ascending = a;
        });
    }

    render(): TemplateResult {
        return html`
            <i class="mdi mdi-16 mdi-${this.getSortIcon()} sort-icon" @click=${() => this.sort()}></i>
        `;
    }
}
