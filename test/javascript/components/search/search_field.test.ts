import "components/search_field";
import { aTimeout, fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { SearchField, SearchFieldSuggestion } from "components/search_field";
import { Label, FilterCollection } from "components/filter_collection_element";
import { html } from "lit";
import { SearchQuery } from "search";

/**
 * https://github.com/testing-library/dom-testing-library/issues/410#issuecomment-1060917305
 * Getting the deepest element that contain string / match regex even when it split between multiple elements
 *
 * @example
 * For:
 * <div>
 *   <span>Hello</span><span> World</span>
 * </div>
 *
 * screen.getByText('Hello World') // ❌ Fail
 * screen.getByText(textContentMatcher('Hello World')) // ✅ pass
 */
function textContentMatcher(textMatch: string | RegExp): (_content: string, node: Element) => boolean {
    // https://stackoverflow.com/questions/42920985/textcontent-without-spaces-from-formatting-text
    const cleanupExcessWhitespace: (string) => string = (text: string) => text.replace(/[\n\r]+|[\s]{2,}/g, " ").trim();
    const hasText = (typeof textMatch === "string") ?
        (node: Element) => cleanupExcessWhitespace(node.textContent) === textMatch :
        (node: Element) => textMatch.test(cleanupExcessWhitespace(node.textContent));

    return (_content: string, node: Element) => {
        if (!hasText(node)) {
            return false;
        }

        const childrenDontHaveText = Array.from(node?.children || []).every(child => !hasText(child));

        return childrenDontHaveText;
    };
}


describe("SearchFieldSuggestion", () => {
    let searchFieldSuggestion;
    beforeEach(async () => {
        const searchQuery = new SearchQuery("test.dodona.be");
        searchFieldSuggestion = await fixture(html`
            <d-search-field-suggestion param="foo"
                                       labels='[{ "name": "fool", "id": "1" }, { "name": "bar", "id": "2" }, { "name": "baz", "id": "3" }]'
                                       type="test"
                                       .paramVal=${(l: Label) => l.id}
                                       filter="ba"
                                       .multi=${false}
                                       .searchQuery=${searchQuery}>
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
        expect(searchFieldSuggestion.searchQuery.queryParams.params.get("foo")).toBe("2");
        expect(searchFieldSuggestion.searchQuery.queryParams.params.get("filter")).toBe(undefined);
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
        expect(searchFieldSuggestion.searchQuery.queryParams.params.get("foo")).toBe("2");

        expect(searchFieldSuggestion.getFilteredLabels().length).toBe(1);
        expect(screen.queryByText(textContentMatcher("bar"))).toBeNull();
    });
});

describe("SearchField", () => {
    async function searchFieldFactory(): Promise<SearchField> {
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
        const searchQuery = new SearchQuery("test.dodona.be");

        return await fixture(html`
            <d-search-field placeholder="Search"
                            .filterCollections="${filterCollections}"
                            .searchQuery=${searchQuery}
            ></d-search-field>
        `);
    }

    it("should display the placeholder", async () => {
        const searchField = await searchFieldFactory();
        const input = searchField.querySelector("input");
        expect(input.placeholder).toBe("Search");
    });

    it("should update the filter query param when the input changes", async () => {
        const searchField = await searchFieldFactory();
        const input = searchField.querySelector("input");
        await userEvent.type(input, "foo");
        await aTimeout(500); // the update is delayed
        expect(searchField.searchQuery.queryParams.params.get("filter")).toBe("foo");
    });

    it("should filter the labels", async () => {
        const searchField = await searchFieldFactory();
        const input = searchField.querySelector("input");
        await userEvent.type(input, "foo");
        expect(screen.queryByText(textContentMatcher("bar"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("baz"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("fool"))).not.toBeNull();
        expect(screen.queryByText(textContentMatcher("food"))).not.toBeNull();
    });

    it("should autocomplete the input with the first label on tab", async () => {
        const searchField = await searchFieldFactory();
        const input = searchField.querySelector("input");
        await userEvent.type(input, "foo{tab}");
        await aTimeout(500); // the update is delayed
        expect(searchField.searchQuery.queryParams.params.get("foo")).toBe("1");
        expect(searchField.searchQuery.queryParams.params.get("filter")).toBeFalsy();
        expect(searchField.searchQuery.queryParams.params.get("bar")).toBeFalsy();
    });

    it("should reset the filter when a label is selected", async () => {
        const searchField = await searchFieldFactory();
        const input = searchField.querySelector("input");
        await userEvent.type(input, "foo");
        await aTimeout(500); // the update is delayed
        expect(searchField.searchQuery.queryParams.params.get("filter")).toBe("foo");
        await userEvent.click(screen.getByText(textContentMatcher("fool")));
        expect(searchField.searchQuery.queryParams.params.get("filter")).toBeFalsy();
        expect(input.value).toBe("");
    });
});
