import { DodonaElement } from "components/meta/dodona_element";
import { property } from "lit/decorators.js";
import { FilterOptions } from "components/search/filter_element";
import { search } from "search";

export class FilterCollection extends DodonaElement {
    @property({ type: Array })
    filters: FilterOptions[] = [];
    @property({ type: Array })
    hide: string[] = [];

    constructor() {
        super();
        search.filterCollections.push(this);
    }

    get visibleFilters(): FilterOptions[] {
        return this.filters.filter(f => !this.hide.includes(f.param));
    }
}
