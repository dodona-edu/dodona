import "components/search/search_field";
import { aTimeout, fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { SearchField, SearchFieldSuggestion } from "components/search/search_field";
import { Label, FilterCollection } from "components/search/filter_collection_element";
import { html } from "lit";
import { searchQueryState } from "state/SearchQuery";
import { textContentMatcher } from "../../test_helpers";

describe("SearchFieldSuggestion", () => {
    let searchFieldSuggestion;
    beforeEach(async () => {
        searchQueryState.queryParams.clear();
        searchFieldSuggestion = await fixture(html`
            <d-search-field-suggestion param="foo"
                                       labels='[{ "name": "fool", "id": "1" }, { "name": "bar", "id": "2" }, { "name": "baz", "id": "3" }]'
                                       type="test"
                                       .paramVal=${(l: Label) => l.id}
                                       filter="ba"
                                       .multi=${false}>
            </d-search-field-suggestion>`) as SearchFieldSuggestion;
    });

    it("should display all labels matching the filter", async () => {
        expect(screen.queryByText(textContentMatcher("bar"))).not.toBeNull();
        expect(screen.queryByText(textContentMatcher("baz"))).not.toBeNull();
        expect(screen.queryByText(textContentMatcher("fool"))).toBeNull();
    });

    it("should display all labels matching the filter after the filter is changed", async () => {
        searchFieldSuggestion.filter = "fo";
        await nextFrame();
        expect(screen.queryByText(textContentMatcher("bar"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("baz"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("fool"))).not.toBeNull();
    });

    it("should set the query param to the selected label", async () => {
        await userEvent.click(screen.getByText(textContentMatcher("bar")));
        expect(searchQueryState.queryParams.get("foo")).toBe("2");
        expect(searchQueryState.queryParams.get("filter")).toBe(undefined);
    });

    it("should display nothing if the filter does not match any label", async () => {
        searchFieldSuggestion.filter = "nope";
        await nextFrame();
        expect(screen.queryByText(textContentMatcher("bar"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("baz"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("fool"))).toBeNull();
    });

    it("should not display already selected labels", async () => {
        await userEvent.click(screen.getByText(textContentMatcher("bar")));
        searchFieldSuggestion.filter = "ba";
        await nextFrame();
        expect(searchQueryState.queryParams.get("foo")).toBe("2");

        expect(searchFieldSuggestion.getFilteredLabels().length).toBe(1);
        expect(screen.queryByText(textContentMatcher("bar"))).toBeNull();
    });
});

describe("SearchField", () => {
    let searchField: SearchField;
    beforeEach(async () => {
        searchQueryState.queryParams.clear();
        const filterCollections: Record<string, FilterCollection> = {
            first: {
                param: "foo",
                data: [
                    { name: "fool", id: "1" },
                    { name: "bar", id: "2" },
                    { name: "baz", id: "3" },
                ],
                multi: false,
                color: () => "red",
                paramVal: (l: Label) => l.id,
            },
            second: {
                param: "bar",
                data: [
                    { name: "food", id: "1" },
                    { name: "barn", id: "2" },
                    { name: "baz", id: "3" },
                ],
                multi: false,
                color: () => "red",
                paramVal: (l: Label) => l.id,
            }
        };

        searchField = await fixture(html`
            <d-search-field placeholder="Search"
                            .filterCollections="${filterCollections}"
            ></d-search-field>
        `);
    });

    it("should display the placeholder", async () => {
        const input = searchField.querySelector("input");
        expect(input.placeholder).toBe("Search");
    });

    it("should update the filter query param when the input changes", async () => {
        const input = searchField.querySelector("input");
        await userEvent.type(input, "foo");
        await aTimeout(500); // the update is delayed
        expect(searchQueryState.queryParams.get("filter")).toBe("foo");
    });

    it("should filter the labels", async () => {
        const input = searchField.querySelector("input");
        await userEvent.type(input, "foo");
        await aTimeout(500); // the update is delayed
        expect(screen.queryByText(textContentMatcher("bar"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("baz"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("fool"))).not.toBeNull();
        expect(screen.queryByText(textContentMatcher("food"))).not.toBeNull();
    });

    it("should autocomplete the input with the first label on tab", async () => {
        const input = searchField.querySelector("input");
        await userEvent.type(input, "foo{tab}");
        await aTimeout(500); // the update is delayed
        expect(searchQueryState.queryParams.get("foo")).toBe("1");
        expect(searchQueryState.queryParams.get("filter")).toBeFalsy();
        expect(searchQueryState.queryParams.get("bar")).toBeFalsy();
    });

    it("should reset the filter when a label is selected", async () => {
        const input = searchField.querySelector("input");
        await userEvent.type(input, "foo");
        await aTimeout(500); // the update is delayed
        expect(searchQueryState.queryParams.get("filter")).toBe("foo");
        await userEvent.click(screen.getByText(textContentMatcher("fool")));
        expect(searchQueryState.queryParams.get("filter")).toBeFalsy();
        expect(input.value).toBe("");
    });
});
