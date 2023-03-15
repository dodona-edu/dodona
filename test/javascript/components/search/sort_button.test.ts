import "components/sort_button";
import { SortQuery } from "components/sort_button";
import { SearchQuery } from "search";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import { screen } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { html } from "lit";

describe("SortButton", () => {
    let sortQuery: SortQuery;
    beforeEach(async () => {
        const searchQuery = new SearchQuery("test.dodona.be");
        sortQuery = new SortQuery(searchQuery);
        await fixture(html`
            <d-sort-button .sortQuery=${sortQuery}
                           column="foo"
                           default="ASC">
                Foo
            </d-sort-button>
            <d-sort-button .sortQuery=${sortQuery}
                           column="bar">
                Bar
            </d-sort-button>
            <d-sort-button .sortQuery=${sortQuery}
                           column="bal"
                           .disabled="${true}">
                Bal
            </d-sort-button>
        `);
    });

    it("should set the sort query parameter when clicked", async () => {
        await userEvent.click(screen.getByText("Bar"));
        expect(sortQuery.active_column).toBe("bar");
        expect(sortQuery.ascending).toBe(true);
    });

    it("should set the sort query parameter to descending when clicked twice", async () => {
        await userEvent.click(screen.getByText("Bar"));
        await userEvent.click(screen.getByText("Bar"));
        expect(sortQuery.active_column).toBe("bar");
        expect(sortQuery.ascending).toBe(false);
    });

    it("should set the sort query back to ascending when clicked three times", async () => {
        await userEvent.click(screen.getByText("Bar"));
        await userEvent.click(screen.getByText("Bar"));
        await userEvent.click(screen.getByText("Bar"));
        expect(sortQuery.active_column).toBe("bar");
        expect(sortQuery.ascending).toBe(true);
    });

    it("should trigger descending when starting as ascending", async () => {
        await userEvent.click(screen.getByText("Foo"));
        expect(sortQuery.active_column).toBe("foo");
        expect(sortQuery.ascending).toBe(false);
    });

    it("should not do anything when clicking a disabled button", async () => {
        await userEvent.click(screen.getByText("Bal"));
        expect(sortQuery.active_column).toBe(undefined);
        expect(sortQuery.ascending).toBe(false);
    });

    it("should update if change is set from outside", async () => {
        sortQuery.active_column = "bar";
        sortQuery.ascending = false;
        await nextFrame();
        await userEvent.click(screen.getByText("Bar"));
        expect(sortQuery.active_column).toBe("bar");
        expect(sortQuery.ascending).toBe(true);
    });

    it("Also updates the search query", async () => {
        await userEvent.click(screen.getByText("Bar"));
        expect(sortQuery.searchQuery.queryParams.params.get("order_by[column]")).toBe("bar");
        expect(sortQuery.searchQuery.queryParams.params.get("order_by[direction]")).toBe("ASC");
    });
});
