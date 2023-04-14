import "components/search/filter_button";
import { FilterButton } from "components/search/filter_button";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { searchQueryState } from "state/SearchQuery";

describe("FilterButton", () => {
    let filterButton: FilterButton;
    beforeEach(async () => {
        filterButton = await fixture(`<d-filter-button param="foo"
                                                                value="bar">
                                                                <span>Test</span>
                                                </d-filter-button>`);
    });

    it("updates the query parameter when clicked", async () => {
        await userEvent.click(screen.getByText("Test"));
        expect(searchQueryState.queryParams.get("foo")).toBe("bar");
    });

    it("updates the array query parameter when clicked if multi", async () => {
        filterButton.multi = true;
        await nextFrame();
        await userEvent.click(screen.getByText("Test"));
        expect(searchQueryState.arrayQueryParams.get("foo")).toContain("bar");
    });
});
