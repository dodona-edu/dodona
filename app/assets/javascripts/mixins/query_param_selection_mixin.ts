import { LitElement } from "lit";
import { property } from "lit/decorators.js";
import { searchQuery } from "search";

type Constructor<T = unknown> = new (...args: any[]) => T;

export declare class QueryParamSelectionInterface {
    param: string;
    multi: boolean;
    update(changedProperties: Map<string, unknown>): void;
    isSelected(label: string): boolean;
    unSelect(label: string): void;
    select(label: string): void;
    toggle(label: string): void;
}


export function queryParamSelectionMixin<T extends Constructor<LitElement>>(superClass: T): Constructor<QueryParamSelectionInterface> & T {
    class QueryParamSelectionClass extends superClass {
        @property()
        param: string;
        @property({ type: Boolean })
        multi: boolean;
        @property({ state: true })
        private multiSelected: string[] = [];
        @property({ state: true })
        private singleSelected = "";

        update(changedProperties: Map<string, unknown>): void {
            if ((changedProperties.has("param") || changedProperties.has("multi")) &&
                this.param !== undefined && this.multi !== undefined) {
                if (this.multi) {
                    this.multiSubscribeToQueryParams();
                    this.select = this.multiSelect;
                    this.unSelect = this.multiUnSelect;
                    this.isSelected = this.multiIsSelected;
                } else {
                    this.singleSubscribeToQueryParams();
                    this.select = this.singleSelect;
                    this.unSelect = this.singleUnSelect;
                    this.isSelected = this.singleIsSelected;
                }
            }
            super.update(changedProperties);
        }

        private multiUnSelect(label: string): void {
            searchQuery.arrayQueryParams.updateParam(this.param, this.multiSelected.filter(s => s !== label));
        }

        private multiIsSelected(label: string): boolean {
            return this.multiSelected.includes(label);
        }

        private multiSelect(label: string): void {
            searchQuery.arrayQueryParams.updateParam(this.param, [...this.multiSelected, label]);
            searchQuery.queryParams.updateParam("filter", undefined);
        }

        private multiSubscribeToQueryParams(): void {
            this.multiSelected = searchQuery.arrayQueryParams.params.get(this.param) || [];
            searchQuery.arrayQueryParams.subscribeByKey(this.param, (k, o, n) => {
                this.multiSelected = n || [];
            });
        }

        private singleUnSelect(label: string): void {
            searchQuery.queryParams.updateParam(this.param, undefined);
        }

        private singleSelect(label: string): void {
            searchQuery.queryParams.updateParam(this.param, label);
            searchQuery.queryParams.updateParam("filter", undefined);
        }

        private singleIsSelected(label: string): boolean {
            return this.singleSelected === label;
        }

        private singleSubscribeToQueryParams(): void {
            this.singleSelected = searchQuery.queryParams.params.get(this.param);
            searchQuery.queryParams.subscribeByKey(this.param, (k, o, n) => this.singleSelected = n || "");
        }

        isSelected = this.singleIsSelected;
        unSelect = this.singleUnSelect;
        select = this.singleSelect;

        toggle(label: string): void {
            if (this.isSelected(label)) {
                this.unSelect(label);
            } else {
                this.select(label);
            }
        }
    }
    return QueryParamSelectionClass as Constructor<QueryParamSelectionInterface> & T;
}
