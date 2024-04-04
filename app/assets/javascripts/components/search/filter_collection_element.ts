import { property } from "lit/decorators.js";
import { searchQueryState } from "state/SearchQuery";
import { DodonaElement } from "components/meta/dodona_element";

export type Label = {id: string, name: string};
export type AccentColor = "red" | "pink" | "purple" | "deep-purple" | "indigo" | "teal" | "orange" | "brown" | "blue-gray";
export type FilterCollection = {
    data: Label[],
    multi: boolean,
    color?: AccentColor,
    param: string
};

/**
 * This class represent a lit element that contains a filter collection
 * The class manages selection and deselection of filter labels
 * It interacts with the searchQuery using the listener paradigm to keep the selected filters up to date
 *
 * @prop {FilterCollection} filterCollection - the filter collection to be displayed
 */
export class FilterCollectionElement extends DodonaElement {
    @property({ type: Object, attribute: "filter-collection" })
    filterCollection: FilterCollection;

    get param(): string {
        return this.filterCollection.param;
    }

    get multi(): boolean {
        return this.filterCollection.multi;
    }

    get labels(): Label[] {
        return this.filterCollection.data;
    }

    get color(): AccentColor | undefined {
        return this.filterCollection.color;
    }

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

    private get multiSelected(): string[] {
        return searchQueryState.arrayQueryParams.get(this.param) || [];
    }

    private multiUnSelect(label: Label): void {
        searchQueryState.arrayQueryParams.set(this.param, this.multiSelected.filter(s => s !== label.id));
    }

    private multiIsSelected(label: Label): boolean {
        return this.multiSelected.includes(label.id);
    }

    private multiSelect(label: Label): void {
        searchQueryState.arrayQueryParams.set(this.param, [...this.multiSelected, label.id]);
    }

    private singleUnSelect(label: Label): void {
        searchQueryState.queryParams.set(this.param, undefined);
    }

    private singleSelect(label: Label): void {
        searchQueryState.queryParams.set(this.param, label.id);
    }

    private singleIsSelected(label: Label): boolean {
        return searchQueryState.queryParams.get(this.param) === label.id;
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
