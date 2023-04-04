import "components/search/sort_button";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import { screen } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { html } from "lit";
import { searchQueryState } from "state/SearchQuery";

describe("SortButton", () => {
    beforeEach(async () => {
        await fixture(html`
            <d-sort-button column="foo"
                           default="ASC">
                Foo
            </d-sort-button>
            <d-sort-button column="bar">
                Bar
            </d-sort-button>
            <d-sort-button column="bal"
                           .disabled="${true}">
                Bal
            </d-sort-button>
        `);
    });

    it("should set the sort query parameter when clicked", async () => {
        await userEvent.click(screen.getByText("Bar"));
        expect(searchQueryState.queryParams.get("order_by[column]")).toBe("bar");
        expect(searchQueryState.queryParams.get("order_by[direction]")).toBe(true);
    });

    it("should set the sort query parameter to descending when clicked twice", async () => {
        await userEvent.click(screen.getByText("Bar"));
        await userEvent.click(screen.getByText("Bar"));
        expect(searchQueryState.queryParams.get("order_by[column]")).toBe("bar");
        expect(searchQueryState.queryParams.get("order_by[direction]")).toBe(false);
    });

    it("should set the sort query back to ascending when clicked three times", async () => {
        await userEvent.click(screen.getByText("Bar"));
        await userEvent.click(screen.getByText("Bar"));
        await userEvent.click(screen.getByText("Bar"));
        expect(searchQueryState.queryParams.get("order_by[column]")).toBe("bar");
        expect(searchQueryState.queryParams.get("order_by[direction]")).toBe(true);
    });

    it("should trigger descending when starting as ascending", async () => {
        await userEvent.click(screen.getByText("Foo"));
        expect(searchQueryState.queryParams.get("order_by[column]")).toBe("foo");
        expect(searchQueryState.queryParams.get("order_by[direction]")).toBe(false);
    });

    it("should not do anything when clicking a disabled button", async () => {
        await userEvent.click(screen.getByText("Bal"));
        expect(searchQueryState.queryParams.get("order_by[column]")).toBe(undefined);
        expect(searchQueryState.queryParams.get("order_by[direction]")).toBe(false);
    });

    it("should update if change is set from outside", async () => {
        searchQueryState.queryParams.set("order_by[column]", "bar");
        searchQueryState.queryParams.set("order_by[direction]", false);
        await nextFrame();
        await userEvent.click(screen.getByText("Bar"));
        expect(searchQueryState.queryParams.get("order_by[column]")).toBe("bar");
        expect(searchQueryState.queryParams.get("order_by[direction]")).toBe(true);
    });

    it("also updates the search query", async () => {
        await userEvent.click(screen.getByText("Bar"));
        expect(searchQueryState.queryParams.get("order_by[column]")).toBe("bar");
        expect(searchQueryState.queryParams.get("order_by[direction]")).toBe("ASC");
    });
});
