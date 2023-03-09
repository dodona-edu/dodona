import "components/search_field";
import { fixture, nextFrame, oneEvent } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { SearchFieldSuggestion } from "components/search_field";
import { Label } from "components/filter_collection_element";
import { html } from "lit";
import { searchQuery } from "search";

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
        searchFieldSuggestion = await fixture(html`
            <d-search-field-suggestion param="foo"
                                       labels='[{ "name": "fool", "id": "1" }, { "name": "bar", "id": "2" }, { "name": "baz", "id": "3" }]'
                                       type="test"
                                       .paramVal=${(l: Label) => l.id}
                                       filter="ba">
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
        screen.getByText(textContentMatcher("bar")).click();
        expect(searchQuery.queryParams.params.get("foo")).toBe("2");
        expect(searchQuery.queryParams.params.get("filter")).toBe(undefined);
    });

    it("should display nothing if the filter does not match any label", async () => {
        searchFieldSuggestion.filter = "nope";
        await nextFrame();
        expect(screen.queryByText(textContentMatcher("bar"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("baz"))).toBeNull();
        expect(screen.queryByText(textContentMatcher("fool"))).toBeNull();
    });
});
