import "components/search/search_actions";
import { SearchAction, SearchActions } from "components/search/search_actions";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { html } from "lit";
import * as util from "utilities";
import { searchQueryState } from "state/SearchQuery";

describe("SearchActions", () => {
    let searchActions: SearchActions;
    beforeEach(async () => {
        searchQueryState.queryParams.clear();
        searchQueryState.arrayQueryParams.clear();
        const actions: SearchAction[] = [
            { text: "bar", icon: "replay", confirm: "Are you sure?", action: "https://test.dodona.be/destroy" },
            { icon: "test", text: "js-test", js: "window.alert('test')" },
            { icon: "link", text: "link-test", url: "https://test.dodona.be" },
            { icon: "play", text: "bars", filterValue: "bar", url: "https://test.dodona.be" },
        ];
        await fixture(`<div class="toasts"></div>`);
        searchActions = await fixture(html`
            <d-search-actions .actions=${actions}
                              filter-param="foo"
            ></d-search-actions>`);
    });

    it("should render the search actions", () => {
        expect(screen.queryByText("bar")).not.toBeNull();
        expect(screen.queryByText("js-test")).not.toBeNull();
        expect(screen.queryByText("link-test")).not.toBeNull();
    });

    test("clicking a js action should execute the js", async () => {
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        jest.spyOn(window, "alert").mockImplementation(() => {});
        await userEvent.click(screen.queryByText("js-test"));
        expect(window.alert).toHaveBeenCalledWith("test");
    });

    test("clicking a link action should navigate to the url", async () => {
        jest.spyOn(window, "open").mockImplementation(() => window);
        await userEvent.click(screen.queryByText("link-test"));
        expect(window.open).toHaveBeenCalledWith("https://test.dodona.be");
    });

    test("clicking a link action should add query params to the url", async () => {
        jest.spyOn(window, "open").mockImplementation(() => window);
        searchQueryState.queryParams.set("foo", "bar");
        await userEvent.click(screen.queryByText("link-test"));
        expect(window.open).toHaveBeenCalledWith("https://test.dodona.be/?foo=bar");
    });

    test("clicking a confirm action should show a confirmation dialog", async () => {
        jest.spyOn(window, "confirm").mockImplementation(() => false);
        await userEvent.click(screen.queryByText("bar"));
        expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
    });

    test("clicking on an action should make a post request to the action url and execute returned javascript", async () => {
        jest.spyOn(window, "confirm").mockImplementation(() => true);
        jest.spyOn(util, "fetch").mockImplementation(() => Promise.resolve({
            json: () => Promise.resolve({ js: "window.alert('test')" }),
        } as Response));
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        jest.spyOn(window, "alert").mockImplementation(() => {});
        await userEvent.click(screen.queryByText("bar"));
        expect(util.fetch).toHaveBeenCalledWith("https://test.dodona.be/destroy", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
        });
        expect(window.alert).toHaveBeenCalledWith("test");
    });

    test("clicking an action should show a toast with the response message", async () => {
        jest.spyOn(window, "confirm").mockImplementation(() => true);
        jest.spyOn(util, "fetch").mockImplementation(() => Promise.resolve({
            json: () => Promise.resolve({ message: "test-toast" }),
        } as Response));
        await userEvent.click(screen.queryByText("bar"));
        expect(screen.queryByText("test-toast")).not.toBeNull();
    });

    test("clicking an action should add query params to the post url", async () => {
        jest.spyOn(window, "confirm").mockImplementation(() => true);
        jest.spyOn(util, "fetch").mockImplementation(() => Promise.resolve({
            json: () => Promise.resolve({}),
        } as Response));
        searchQueryState.queryParams.set("foo", "bar");
        await userEvent.click(screen.queryByText("bar"));
        expect(util.fetch).toHaveBeenCalledWith("https://test.dodona.be/destroy?foo=bar", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
        });
    });

    test("actions with a filterValue should only be shown when the filterOaram is set to the filterValue", async () => {
        expect(screen.queryByText("bars")).toBeNull();
        searchQueryState.queryParams.set("foo", "bar");
        await nextFrame();
        expect(screen.queryByText("bars")).not.toBeNull();
        searchQueryState.queryParams.set("foo", "baz");
        await nextFrame();
        expect(screen.queryByText("bars")).toBeNull();
    });
});
