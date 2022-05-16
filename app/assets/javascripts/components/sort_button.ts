import "search.ts";
import { css, html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { searchQuery } from "search";

export class SortQuery {
    active_column: string;
    ascending: boolean;
    listeners: Array<(c: string, a: boolean) => void> = [];

    constructor() {
        this.active_column = searchQuery.queryParams.params.get("order_by[column]");
        this.ascending= searchQuery.queryParams.params.get("order_by[direction]") === "ASC";
        searchQuery.queryParams.subscribeByKey("order_by[column]", (k, o, n) => {
            this.active_column = n;
            this.notify();
        });
        searchQuery.queryParams.subscribeByKey("order_by[direction]", (k, o, n) => {
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
            searchQuery.queryParams.updateParam("order_by[column]", this.active_column);
            searchQuery.queryParams.updateParam("order_by[direction]", this.getDirectionValue());
        }
    }
}
export const sortQuery = new SortQuery();

@customElement("dodona-sort-button")
export class SortButton extends LitElement {
    @property({ type: String })
    column: string;
    @property({ type: String })
    default: string;
    @property({ type: Boolean })
    disabled= false;

    active_column: string;
    ascending: boolean;

    update(changedProperties: Map<string, unknown>): void {
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
            sortQuery.sortBy(this.column, true);
        } else {
            sortQuery.sortBy(this.column, false);
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
            <slot></slot>
            ${this.disabled? "": html`
                <style>:host {cursor: pointer;}</style>
                <i class="mdi mdi-${this.getSortIcon()}"></i>
            `}
        `;
    }
}
