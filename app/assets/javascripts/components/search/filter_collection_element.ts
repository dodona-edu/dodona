import { property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { searchQueryState } from "state/SearchQuery";

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
 * @prop {function(Label): string} paramVal - a function that extracts the value that should be used in a searchQuery for a selected label
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

    update(changedProperties: Map<string, unknown>): void {
        if ((changedProperties.has("param") || changedProperties.has("multi")) &&
            this.param !== undefined && this.multi !== undefined) {
            if (this.multi) {
                this.select = this.multiSelect;
                this.unSelect = this.multiUnSelect;
                this.isSelected = this.multiIsSelected;
            } else {
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

    private get multiSelected(): string[] {
        return searchQueryState.arrayQueryParams.get(this.param) || [];
    }

    private multiUnSelect(label: Label): void {
        searchQueryState.arrayQueryParams.set(this.param, this.multiSelected.filter(s => s !== this.str(label)));
    }

    private multiIsSelected(label: Label): boolean {
        return this.multiSelected.includes(this.str(label));
    }

    private multiSelect(label: Label): void {
        searchQueryState.arrayQueryParams.set(this.param, [...this.multiSelected, this.str(label)]);
    }

    private singleUnSelect(label: Label): void {
        searchQueryState.queryParams.set(this.param, undefined);
    }

    private singleSelect(label: Label): void {
        searchQueryState.queryParams.set(this.param, this.str(label));
    }

    private singleIsSelected(label: Label): boolean {
        return searchQueryState.queryParams.get(this.param) === this.str(label);
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
