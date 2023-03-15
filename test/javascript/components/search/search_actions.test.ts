import "components/search_actions";
import { SearchAction, SearchActions, SearchOption } from "components/search_actions";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/dom";
import { SearchQuery } from "search";
import { html } from "lit";
import * as util from "util.js";

describe("SearchActions", () => {
    let searchActions: SearchActions;
    beforeEach(async () => {
        const actions: (SearchOption | SearchAction)[] = [
            { text: "foo", search: { foo: "bar", fool: "bars" } },
            { text: "bar", icon: "replay", confirm: "Are you sure?", action: "https://test.dodona.be/destroy" },
            { icon: "test", text: "js-test", js: "window.alert('test')" },
            { icon: "link", text: "link-test", url: "https://test.dodona.be" },
        ];
        const searchQuery = new SearchQuery("test.dodona.be");
        await fixture(`<div class="toasts"></div>`);
        searchActions = await fixture(html`
            <d-search-actions .searchQuery=${searchQuery}
                              .actions=${actions}
            ></d-search-actions>`);
    });

    it("should render the search options/actions", () => {
        expect(screen.queryByText("foo")).not.toBeNull();
        expect(screen.queryByText("bar")).not.toBeNull();
        expect(screen.queryByText("js-test")).not.toBeNull();
        expect(screen.queryByText("link-test")).not.toBeNull();
    });

    it("should show a checkbox for the search options", () => {
        expect(screen.queryByLabelText("foo")).not.toBeNull();
    });

    test("the search options should be checked when they are active", async () => {
        const checkbox = screen.queryByLabelText("foo") as HTMLInputElement;
        expect(checkbox.checked).toBe(false);
        await userEvent.click(checkbox);
        expect(checkbox.checked).toBe(true);
        expect(searchActions.searchQuery.queryParams.params.get("foo")).toBe("bar");
        expect(searchActions.searchQuery.queryParams.params.get("fool")).toBe("bars");
        searchActions.searchQuery.queryParams.updateParam("foo", undefined);
        await nextFrame();
        expect(checkbox.checked).toBe(false);
        searchActions.searchQuery.queryParams.updateParam("foo", "bar");
        await nextFrame();
        expect(checkbox.checked).toBe(true);
    });

    test("clicking a js action should execute the js", async () => {
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        jest.spyOn(window, "alert").mockImplementation(() => {});
        await userEvent.click(screen.queryByText("js-test"));
        expect(window.alert).toHaveBeenCalledWith("test");
    });

    test("clicking a link action should navigate to the url", async () => {
        expect(screen.getByText("link-test").closest("a").href).toBe("https://test.dodona.be/");
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
        searchActions.searchQuery.queryParams.updateParam("foo", "bar");
        await userEvent.click(screen.queryByText("bar"));
        expect(util.fetch).toHaveBeenCalledWith("https://test.dodona.be/destroy?foo=bar", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
        });
    });
});
