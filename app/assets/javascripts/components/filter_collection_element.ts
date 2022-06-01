import { property } from "lit/decorators.js";
import { searchQuery } from "search";
import { ShadowlessLitElement } from "components/shadowless_lit_element";

export type Label = {id: string, name: string};
export type FilterCollection = {
    data: Label[],
    multi: boolean,
    color: (l: Label) => string,
    paramVal: (l: Label) => string,
    param: string
};

/**
 * This class represent a lit element that contains a filter collection
 * The class manages selection and deselection of filter labels
 * It interacts with the searchQuery using the listener paradigm to keep the selected filters up to date
 *
 * @prop {string} param - the searchQuery param to be used for this filter
 * @prop {boolean} multi - whether one or more labels can be selected at the same time
 * @prop {(l: Label) => string} paramVal - a function that extracts the value that should be used in a searchQuery for a selected label
 * @prop {[Label]} labels - all labels that could potentially be selected
 */
export class FilterCollectionElement extends ShadowlessLitElement {
    @property()
    param: string;
    @property({ type: Boolean })
    multi: boolean;
    @property()
    paramVal: (l: Label) => string;
    @property({ type: Array })
    labels: Array<Label> = [];
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

    private str(label: Label): string {
        return this.paramVal(label).toString();
    }

    private multiUnSelect(label: Label): void {
        searchQuery.arrayQueryParams.updateParam(this.param, this.multiSelected.filter(s => s !== this.str(label)));
    }

    private multiIsSelected(label: Label): boolean {
        return this.multiSelected.includes(this.str(label));
    }

    private multiSelect(label: Label): void {
        searchQuery.arrayQueryParams.updateParam(this.param, [...this.multiSelected, this.str(label)]);
        searchQuery.queryParams.updateParam("filter", undefined);
    }

    private multiSubscribeToQueryParams(): void {
        this.multiSelected = searchQuery.arrayQueryParams.params.get(this.param) || [];
        searchQuery.arrayQueryParams.subscribeByKey(this.param, (k, o, n) => {
            this.multiSelected = n || [];
        });
    }

    private singleUnSelect(label: Label): void {
        searchQuery.queryParams.updateParam(this.param, undefined);
    }

    private singleSelect(label: Label): void {
        searchQuery.queryParams.updateParam(this.param, this.str(label));
        searchQuery.queryParams.updateParam("filter", undefined);
    }

    private singleIsSelected(label: Label): boolean {
        return this.singleSelected === this.str(label);
    }

    private singleSubscribeToQueryParams(): void {
        this.singleSelected = searchQuery.queryParams.params.get(this.param);
        searchQuery.queryParams.subscribeByKey(this.param, (k, o, n) => this.singleSelected = n || "");
    }

    isSelected = this.singleIsSelected;
    unSelect = this.singleUnSelect;
    select = this.singleSelect;

    toggle(label: Label): void {
        if (this.isSelected(label)) {
            this.unSelect(label);
        } else {
            this.select(label);
        }
    }

    getSelectedLabels(): Label[] {
        return this.labels.filter( l => this.isSelected(l));
    }
}
