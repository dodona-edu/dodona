import "search.ts";
import { css, html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { searchQuery } from "search";

export class SortQuery {
    active_column: string;
    ascending: boolean;
    listeners: Array<(c: string, a: boolean) => void> = [];

    constructor() {
        const sortParams = [...searchQuery.queryParams.params.entries()].filter(
            ([k, v]) => k.startsWith("order_by_") && (v === "ASC" || v === "DESC")
        );

        if (sortParams.length > 0) {
            this.active_column = sortParams[0][0].substring(9);
            this.ascending = sortParams[0][1] === "ASC";
            sortParams.slice(1).forEach(([k, _]) => {
                searchQuery.queryParams.updateParam(k, undefined);
            });
        }
        searchQuery.queryParams.subscribe((k, o, n) => {
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
            searchQuery.queryParams.updateParam(this.getQueryKey(), undefined);
            this.active_column = column;
        }
        this.ascending = ascending;
        this.notify();
        if (this.active_column) {
            searchQuery.queryParams.updateParam(this.getQueryKey(), this.getQueryValue());
        }
    }
}
export const sortQuery = new SortQuery();

@customElement("dodona-sort-button")
export class SortButton extends LitElement {
    @property({ type: String })
    column: string;

    active_column: string;
    ascending: boolean;

    static styles = css`
        :host {
            cursor: pointer;
        }

        .mdi::before {
            display: inline-block;
            font: normal normal normal 24px/1 "Material Design Icons";
            text-rendering: auto;
            box-sizing: border-box;
            line-height: 18px;
            font-size: 16px;
        }

        .mdi-none::before {
          display: none;
        }

        :host(:hover) .mdi-none::before {
            opacity: 0.7;
            display: inline-block;
            content: "\\F0045";
        }

        .mdi-arrow-down::before {
          content: "\\F0045";
        }

        :host(:hover) .mdi-arrow-down::before {
            opacity: 0.7;
            content: "\\F005D";
        }

        .mdi-arrow-up::before {
          content: "\\F005D";
        }

        :host(:hover) .mdi-arrow-up::before {
            visibility: hidden;
        }
    `;

    isActive(): boolean {
        return this.column === this.active_column;
    }

    getSortIcon(): string {
        return this.isActive() ? this.ascending ? "arrow-down" : "arrow-up" : "none";
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
        this.addEventListener("click", () => this.sort());
    }

    render(): TemplateResult {
        return html`
            <i class="mdi mdi-${this.getSortIcon()}"></i>
            <slot></slot>
        `;
    }
}
