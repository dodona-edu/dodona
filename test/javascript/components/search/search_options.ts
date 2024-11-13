import "components/search/search_options";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { html } from "lit";
import { searchQueryState } from "state/SearchQuery";
import { Option } from "components/search/search_option";

describe("SearchOptions", () => {
    beforeEach(async () => {
        searchQueryState.queryParams.clear();
        searchQueryState.arrayQueryParams.clear();
        const options: Option[] = [
            { param: "foo", label: "foo" },
            { param: "bar", label: "fool" },
        ];
        await fixture(`<div class="toasts"></div>`);
        await fixture(html`
            <d-search-options .options=${options}
            ></d-search-options>`);
    });

    it("should render the search options", () => {
        expect(screen.queryByText("foo")).not.toBeNull();
        expect(screen.queryByText("fool")).not.toBeNull();
        expect(screen.queryByText("bar")).toBeNull();
    });

    it("should show a checkbox for the search options", () => {
        expect(screen.queryByLabelText("foo")).not.toBeNull();
        expect(screen.queryByLabelText("fool")).not.toBeNull();
    });

    test("the search options should be checked when they are active", async () => {
        const checkbox = screen.queryByLabelText("foo") as HTMLInputElement;
        expect(checkbox.checked).toBe(false);
        await userEvent.click(checkbox);
        expect(checkbox.checked).toBe(true);
        expect(searchQueryState.queryParams.get("foo")).toBe("true");
        expect(searchQueryState.queryParams.get("bar")).toBe(undefined);
        searchQueryState.queryParams.set("foo", undefined);
        await nextFrame();
        expect(checkbox.checked).toBe(false);
        searchQueryState.queryParams.set("foo", "true");
        await nextFrame();
        expect(checkbox.checked).toBe(true);
    });
});
