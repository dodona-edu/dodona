import "components/dropdown_filter";
import { DropdownFilter } from "components/dropdown_filter";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import userEvent from "@testing-library/user-event";
import { getByLabelText, screen } from "@testing-library/dom";
import { SearchQuery } from "search";
import { html } from "lit/development";
import { Label } from "components/filter_collection_element";

describe("DropdownFilter", () => {
    let dropdownFilter;
    beforeEach(async () => {
        const searchQuery = new SearchQuery("test.dodona.be");
        dropdownFilter = await fixture(html`
            <d-dropdown-filter param="foo"
                                       labels='[{ "name": "fool", "id": "1" }, { "name": "bar", "id": "2" }, { "name": "baz", "id": "3" }]'
                                       type="test"
                                       .paramVal=${(l: Label) => l.id}
                                       .color=${() => "pink"}
                                       .multi=${false}
                                       .searchQuery=${searchQuery}>
            </d-dropdown-filter>`) as DropdownFilter;
    });

    it("Should always display all labels", async () => {
        expect(screen.queryByText("bar")).not.toBeNull();
        expect(screen.queryByText("baz")).not.toBeNull();
        expect(screen.queryByText("fool")).not.toBeNull();
    });

    it("Should set the query param to the selected label", async () => {
        await userEvent.click(screen.getByText("bar"));
        expect(dropdownFilter.searchQuery.queryParams.params.get("foo")).toBe("2");
    });

    it("Should mark selected labels as active", async () => {
        await userEvent.click(screen.getByText("bar"));
        const input = getByLabelText(dropdownFilter, "bar") as HTMLInputElement;
        expect(input.checked).toBe(true);
    });

    it("should unchecked the selected label when clicked again", async () => {
        await userEvent.click(screen.getByText("bar"));
        await userEvent.click(screen.getByText("bar"));
        const input = getByLabelText(dropdownFilter, "bar") as HTMLInputElement;
        expect(input.checked).toBe(false);
    });

    it("should uncheck the selected label when another label is selected", async () => {
        await userEvent.click(screen.getByText("bar"));
        await userEvent.click(screen.getByText("baz"));
        const input = getByLabelText(dropdownFilter, "bar") as HTMLInputElement;
        expect(input.checked).toBe(false);
        const input2 = getByLabelText(dropdownFilter, "baz") as HTMLInputElement;
        expect(input2.checked).toBe(true);
    });

    it("should allow multiple labels to be selected when multi is true", async () => {
        dropdownFilter.multi = true;
        await nextFrame();
        await userEvent.click(screen.getByText("bar"));
        await userEvent.click(screen.getByText("baz"));
        const input = getByLabelText(dropdownFilter, "bar") as HTMLInputElement;
        expect(input.checked).toBe(true);
        const input2 = getByLabelText(dropdownFilter, "baz") as HTMLInputElement;
        expect(input2.checked).toBe(true);
    });

    it("should display a colored dot on the button for each selected label", async () => {
        dropdownFilter.multi = true;
        await nextFrame();
        await userEvent.click(screen.getByText("bar"));
        await userEvent.click(screen.getByText("baz"));
        const button = screen.getByRole("button");
        expect(button.querySelectorAll(".accent-pink").length).toBe(2);
    });

    it("Should display a search field if more then 15 labels are present", async () => {
        expect(dropdownFilter.querySelector("input[type='text']")).toBeNull();
        dropdownFilter.labels = Array.from({ length: 16 }, (_, i) => {
            return { name: `label ${i}`, id: `${i}` };
        });
        await nextFrame();
        expect(dropdownFilter.querySelector("input[type='text']")).not.toBeNull();
    });

    it("Should filter the labels based on the input field", async () => {
        dropdownFilter.labels = Array.from({ length: 16 }, (_, i) => {
            return { name: `label ${i}`, id: `${i}` };
        });
        await nextFrame();
        const input = dropdownFilter.querySelector("input[type='text']") as HTMLInputElement;
        await userEvent.type(input, "label 1");
        expect(screen.queryByText("label 1")).not.toBeNull();
        expect(screen.queryByText("label 2")).toBeNull();
        expect(screen.queryByText("label 14")).not.toBeNull();
    });

    it("Should update if the search query changes", async () => {
        dropdownFilter.searchQuery.queryParams.updateParam("foo", "2");
        await nextFrame();
        const input = getByLabelText(dropdownFilter, "bar") as HTMLInputElement;
        expect(input.checked).toBe(true);
    });
});


