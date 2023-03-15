import "components/standalone-dropdown-filter";
import { StandaloneDropdownFilter } from "components/standalone-dropdown-filter";
import { fixture } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { getByText, queryByText, screen } from "@testing-library/dom";
import { SearchQuery } from "search";
import { html } from "lit/development";


describe("DropdownFilter", () => {
    let standaloneDropdownFilter: StandaloneDropdownFilter;
    let dropdownMenu: HTMLElement;
    let dropdownButton: HTMLElement;
    beforeEach(async () => {
        const searchQuery = new SearchQuery("test.dodona.be");
        standaloneDropdownFilter = await fixture(html`
            <d-standalone-dropdown-filter param="foo"
                                       labels='[{ "name": "fool", "id": "1" }, { "name": "bar", "id": "2" }, { "name": "baz", "id": "3" }]'
                                       .searchQuery=${searchQuery}
                                        default="1">
            </d-standalone-dropdown-filter>`);
        dropdownMenu = screen.getByRole("list");
        dropdownButton = screen.getByRole("button");
    });

    it("Should always display all labels", async () => {
        expect(queryByText(dropdownMenu, "bar")).not.toBeNull();
        expect(queryByText(dropdownMenu, "baz")).not.toBeNull();
        expect(queryByText(dropdownMenu, "fool")).not.toBeNull();
    });

    it("Should set the query param to the selected label", async () => {
        await userEvent.click(getByText(dropdownMenu, "bar"));
        expect(standaloneDropdownFilter.searchQuery.queryParams.params.get("foo")).toBe("2");
    });

    it("Should mark selected labels as active", async () => {
        await userEvent.click(getByText(dropdownMenu, "bar"));
        expect(getByText(dropdownMenu, "bar").classList).toContain("active");
    });

    it("should not uncheck the selected label when clicked again", async () => {
        await userEvent.click(getByText(dropdownMenu, "bar"));
        await userEvent.click(getByText(dropdownMenu, "bar"));
        expect(getByText(dropdownMenu, "bar").classList).toContain("active");
    });

    it("should uncheck the selected label when another label is selected", async () => {
        await userEvent.click(getByText(dropdownMenu, "bar"));
        await userEvent.click(getByText(dropdownMenu, "baz"));
        expect(getByText(dropdownMenu, "baz").classList).toContain("active");
        expect(getByText(dropdownMenu, "bar").classList).not.toContain("active");
    });

    it("should display the active option on the button", async () => {
        await userEvent.click(getByText(dropdownMenu, "bar"));
        expect(queryByText(dropdownButton, "bar")).not.toBeNull();
    });

    it("should treat the default option as active", async () => {
        expect(getByText(dropdownMenu, "fool").classList).toContain("active");
        expect(queryByText(dropdownButton, "fool")).not.toBeNull();
    });

    it("should set the default option as active on the search query", async () => {
        expect(standaloneDropdownFilter.searchQuery.queryParams.params.get("foo")).toBe("1");
    });
});


