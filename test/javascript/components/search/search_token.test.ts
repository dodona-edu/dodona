import "components/search_token";
import { SearchToken } from "components/search_token";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { SearchQuery } from "search";
import { html } from "lit/development";
import { Label } from "components/filter_collection_element";

describe("SearchToken", () => {
    let searchToken;
    beforeEach(async () => {
        const searchQuery = new SearchQuery("test.dodona.be");
        searchToken = await fixture(html`
            <d-search-token param="foo"
                                       labels='[{ "name": "fool", "id": "1" }, { "name": "bar", "id": "2" }, { "name": "baz", "id": "3" }]'
                                       type="test"
                                       .paramVal=${(l: Label) => l.id}
                                       .color=${() => "pink"}
                                       .multi=${false}
                                       .searchQuery=${searchQuery}>
            </d-search-token>`) as SearchToken;
    });

    it("should only display selected labels", async () => {
        expect(screen.queryByText("bar")).toBeNull();
        expect(screen.queryByText("baz")).toBeNull();
        expect(screen.queryByText("fool")).toBeNull();
        searchToken.searchQuery.queryParams.updateParam("foo", "2");
        await nextFrame();
        expect(screen.queryByText("bar")).not.toBeNull();
        expect(screen.queryByText("baz")).toBeNull();
        expect(screen.queryByText("fool")).toBeNull();
    });

    it("can only display one label when multi is false", async () => {
        searchToken.searchQuery.queryParams.updateParam("foo", "2");
        await nextFrame();
        expect(screen.queryByText("bar")).not.toBeNull();
        expect(screen.queryByText("baz")).toBeNull();
        expect(screen.queryByText("fool")).toBeNull();
        searchToken.searchQuery.queryParams.updateParam("foo", "3");
        await nextFrame();
        expect(screen.queryByText("bar")).toBeNull();
        expect(screen.queryByText("baz")).not.toBeNull();
        expect(screen.queryByText("fool")).toBeNull();
    });

    it("can display multiple labels when multi is true", async () => {
        searchToken.multi = true;
        await nextFrame();
        searchToken.searchQuery.arrayQueryParams.updateParam("foo", ["2", "3"]);
        await nextFrame();
        expect(screen.queryByText("bar")).not.toBeNull();
        expect(screen.queryByText("baz")).not.toBeNull();
        expect(screen.queryByText("fool")).toBeNull();
    });

    it("should have a button to remove the selected label", async () => {
        searchToken.searchQuery.queryParams.updateParam("foo", "2");
        await nextFrame();
        expect(screen.queryByText("bar")).not.toBeNull();
        const button = searchToken.querySelector("a.close");
        await userEvent.click(button);
        expect(screen.queryByText("bar")).toBeNull();
    });
});


