import "components/search/filter_button";
import { FilterButton } from "components/search/filter_button";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { SearchQuery } from "search";

describe("FilterButton", () => {
    let filterButton: FilterButton;
    beforeEach(async () => {
        const searchQuery = new SearchQuery("test.dodona.be");
        filterButton = await fixture(`<d-filter-button .searchQuery=${searchQuery}
                                                                param="foo"
                                                                value="bar">
                                                                <span>Test</span>
                                                </d-filter-button>`);
    });

    it("updates the query parameter when clicked", async () => {
        await userEvent.click(screen.getByText("Test"));
        expect(filterButton.searchQuery.queryParams.params.get("foo")).toBe("bar");
    });

    it("updates the array query parameter when clicked if multi", async () => {
        filterButton.multi = true;
        await nextFrame();
        await userEvent.click(screen.getByText("Test"));
        expect(filterButton.searchQuery.arrayQueryParams.params.get("foo")).toContain("bar");
    });
});
