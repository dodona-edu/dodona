import "search.ts";
import { css, html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { searchQuery, SearchQuery } from "search";

/**
 * This class is made to manage the currently active sort parameter in the search query
 */
export class SortQuery {
    active_column: string;
    ascending: boolean;
    listeners: Array<(c: string, a: boolean) => void> = [];
    searchQuery: SearchQuery;

    constructor(_searchQuery: SearchQuery = searchQuery) {
        this.searchQuery = _searchQuery;
        this.active_column = this.searchQuery.queryParams.params.get("order_by[column]");
        this.ascending = this.searchQuery.queryParams.params.get("order_by[direction]") === "ASC";
        this.searchQuery.queryParams.subscribeByKey("order_by[column]", (k, o, n) => {
            this.active_column = n;
            this.notify();
        });
        this.searchQuery.queryParams.subscribeByKey("order_by[direction]", (k, o, n) => {
            this.ascending = n === "ASC";
            this.notify();
        });
    }

    getDirectionValue(): string {
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

        this.active_column = column;
        this.ascending = ascending;
        if (this.active_column) {
            this.searchQuery.queryParams.updateParam("order_by[column]", this.active_column);
            this.searchQuery.queryParams.updateParam("order_by[direction]", this.getDirectionValue());
        }
    }
}
export const sortQuery = new SortQuery();

/**
 * This component represents a sort button.
 * It is clickable and contains an icon indicating the current sort direction.
 *
 * @element d-sort-button
 *
 * @prop {string} column - the column by which should be sorted
 * @prop {string} default - posible values: "ASC" or "DESC". if present this sortButton is supposed to be active when no sort params ore in the searchQuery
 * @prop {boolean} disabled - disables the functionality
 *
 * @slot - this contains the clickable button content (left of the sort icon)
 */
@customElement("d-sort-button")
export class SortButton extends LitElement {
    @property({ type: String })
    column: string;
    @property({ type: String })
    default: string;
    @property({ type: Boolean })
    disabled = false;
    @property({ type: Object })
    sortQuery: SortQuery = sortQuery;

    active_column: string;
    ascending: boolean;

    update(changedProperties: Map<string, unknown>): void {
        if (changedProperties.has("sortQuery")) {
            this.ascending = this.sortQuery.ascending;
            this.active_column = this.sortQuery.active_column;
            this.sortQuery.subscribe((c, a) => {
                this.active_column = c;
                this.ascending = a;
            });
        }
        if ( changedProperties.has("disabled") ) {
            if (!this.disabled) {
                this.addEventListener("click", this.sort);
            } else {
                this.removeEventListener("click", this.sort);
            }
        }
        if (changedProperties.has("default") &&
            (this.default === "ASC" || this.default === "DESC" ) &&
            this.active_column === undefined) {
            this.active_column = this.column;
            this.ascending = this.default === "ASC";
        }
        super.update(changedProperties);
    }

    static styles = css`
        :host {
            white-space: nowrap;
        }

        .mdi::before {
            display: inline-block;
            font: normal normal normal 24px/1 "Material Design Icons";
            text-rendering: auto;
            box-sizing: border-box;
            line-height: 15px;
            font-size: 15px;
        }

        .mdi-none::before {
           content: "\\F0045";
           visibility: hidden;
        }

        :host(:hover) .mdi-none::before {
            opacity: 0.7;
            visibility: visible;
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
            opacity: 0.7;
            content: "\\F0045";
        }
    `;

    isActive(): boolean {
        return this.column === this.active_column;
    }

    getSortIcon(): string {
        return this.isActive() ? this.ascending ? "arrow-up" : "arrow-down" : "none";
    }

    sort(): void {
        if (!this.isActive() || !this.ascending) {
            this.sortQuery.sortBy(this.column, true);
        } else {
            this.sortQuery.sortBy(this.column, false);
        }
    }

    render(): TemplateResult {
        return html`
            <slot></slot>
            ${this.disabled? "": html`
                <style>:host {cursor: pointer;}</style>
                <i class="mdi mdi-${this.getSortIcon()}"></i>
            `}
        `;
    }
}
