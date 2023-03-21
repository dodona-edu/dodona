import "components/search/filter_tabs";
import { FilterTabs } from "components/search/filter_tabs";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { SearchQuery } from "search";

describe("FilterTabs", () => {
    let filterTabs: FilterTabs;
    beforeEach(async () => {
        const searchQuery = new SearchQuery("test.dodona.be");
        filterTabs = await fixture(`<d-filter-tabs .searchQuery=${searchQuery}
                                                           labels='[{ "name": "fool", "id": "1" }, { "name": "bar", "id": "2" }, { "name": "baz", "id": "3" }]'
                                       ></d-filter-tabs>`);
    });

    it("should always display all labels", async () => {
        expect(screen.queryByText("bar")).not.toBeNull();
        expect(screen.queryByText("baz")).not.toBeNull();
        expect(screen.queryByText("fool")).not.toBeNull();
    });

    it("should set the query param to the selected label", async () => {
        await userEvent.click(screen.getByText("bar"));
        expect(filterTabs.searchQuery.queryParams.params.get("tab")).toBe("2");
    });

    it("should mark selected labels as active", async () => {
        await userEvent.click(screen.getByText("bar"));
        expect(screen.getByText("bar").classList).toContain("active");
    });

    it("should select the first label when no label is selected", async () => {
        expect(screen.getByText("fool").classList).toContain("active");
        expect(filterTabs.searchQuery.queryParams.params.get("tab")).toBe("1");
    });

    it("should update the active label when the query param changes", async () => {
        filterTabs.searchQuery.queryParams.updateParam("tab", "2");
        await nextFrame();
        expect(screen.getByText("bar").classList).toContain("active");
    });

    it("should always have only one active label", async () => {
        await userEvent.click(screen.getByText("bar"));
        await userEvent.click(screen.getByText("baz"));
        expect(screen.getByText("baz").classList).toContain("active");
        expect(screen.getByText("bar").classList).not.toContain("active");
    });
});
