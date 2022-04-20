import "search.ts";
import { html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { searchQuery } from "search";
import {ShadowlessLitElement} from "components/shadowless_lit_element";

export class SortQuery {
    active_column: string;
    ascending: boolean;
    listeners: Array<(c: string, a: boolean) => void> = [];

    constructor() {
        const sortParams = [...searchQuery.query_params.params.entries()].filter(
            ([k, v]) => k.startsWith("order_by_") && (v=== "ASC" || v === "DESC")
        );

        if (sortParams.length > 0) {
            this.active_column = sortParams[0][0].substring(9);
            this.ascending = sortParams[0][1] === "ASC";
            sortParams.slice(1).forEach(([k, _]) => {
                searchQuery.query_params.updateParam(k, undefined);
            });
        }
        searchQuery.query_params.subscribe((k, o, n) => {
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
            searchQuery.query_params.updateParam(this.getQueryKey(), undefined);
            this.active_column = column;
        }
        this.ascending = ascending;
        this.notify();
        if (this.active_column) {
            searchQuery.query_params.updateParam(this.getQueryKey(), this.getQueryValue());
        }
    }
}
export const sortQuery = new SortQuery();

@customElement("dodona-sort-button")
export class SortButton extends ShadowlessLitElement {
    @property({ type: String })
        column: string;

    active_column: string;
    ascending: boolean;

    isActive(): boolean {
        return this.column === this.active_column;
    }

    getSortIcon(): string {
        return this.isActive() ? this.ascending ? "sort-ascending" : "sort-descending" : "sort";
    }

    sort(): void {
        if (!this.isActive()) {
            sortQuery.sortBy(this.column, true);
        } else if (this.ascending) {
            sortQuery.sortBy(this.column, false);
        } else {
            sortQuery.sortBy(undefined, undefined);
        }
    }

    constructor() {
        super();
        this.ascending = sortQuery.ascending;
        this.active_column = sortQuery.active_column;
        sortQuery.subscribe((c, a) => {
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
