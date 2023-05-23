import "components/pagination";
import { Pagination } from "components/pagination";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import { screen } from "@testing-library/dom";
import { searchQuery } from "search";

describe("Pagination", () => {
    it("always shows the current page as active", async () => {
        await fixture(`<d-pagination current="2" total="5"></d-pagination>`);
        expect(screen.queryByText("2", { selector: ".active a" })).toBeDefined();
    });

    it("always shows a link to the first and the last page", async () => {
        const pagination = await fixture(`<d-pagination current="2" total="5"></d-pagination>`) as Pagination;
        expect(screen.queryByText("1", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("5", { selector: "a" })).toBeDefined();

        pagination.current = 1;
        await nextFrame();

        expect(screen.queryByText("1", { selector: ".active a" })).toBeDefined();
        expect(screen.queryByText("5", { selector: "a" })).toBeDefined();

        pagination.total = 2;
        await nextFrame();

        expect(screen.queryByText("1", { selector: ".active a" })).toBeDefined();
        expect(screen.queryByText("2", { selector: "a" })).toBeDefined();
    });

    it("shows the four adjacent pages to the current page", async () => {
        await fixture(`<d-pagination current="4" total="9"></d-pagination>`);

        expect(screen.queryByText("1", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("2", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("3", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("4", { selector: ".active a" })).toBeDefined();
        expect(screen.queryByText("5", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("6", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("7", { selector: "a" })).toBeNull();
        expect(screen.queryByText("8", { selector: "a" })).toBeNull();
        expect(screen.queryByText("9", { selector: "a" })).toBeDefined();
    });

    it("shows a next and previous button", async () => {
        const pagination = await fixture(`<d-pagination current="2" total="5"></d-pagination>`) as Pagination;
        expect(screen.queryByText("←", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("→", { selector: "a" })).toBeDefined();

        pagination.current = 1;
        await nextFrame();

        expect(screen.queryByText("←", { selector: ".disabled a" })).toBeDefined();
        expect(screen.queryByText("→", { selector: "a" })).toBeDefined();

        pagination.current = 5;
        await nextFrame();

        expect(screen.queryByText("←", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("→", { selector: ".disabled a" })).toBeDefined();
    });

    it("does not show next and previous buttons when smaller than 5 pages", async () => {
        await fixture(`<d-pagination current="2" total="5" small></d-pagination>`);

        expect(screen.queryByText("←", { selector: ".disabled a" })).toBeNull();
        expect(screen.queryByText("→", { selector: ".disabled a" })).toBeNull();
    });

    it("Only shows 2 adjacent pages when small", async () => {
        await fixture(`<d-pagination current="4" total="9" small></d-pagination>`);

        expect(screen.queryByText("1", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("2", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("3", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("4", { selector: ".active a" })).toBeDefined();
        expect(screen.queryByText("5", { selector: "a" })).toBeDefined();
        expect(screen.queryByText("6", { selector: "a" })).toBeNull();
        expect(screen.queryByText("7", { selector: "a" })).toBeNull();
        expect(screen.queryByText("8", { selector: "a" })).toBeNull();
        expect(screen.queryByText("9", { selector: "a" })).toBeDefined();
    });

    it("updates the current page when clicking on a page", async () => {
        const pagination = await fixture(`<d-pagination current="2" total="5"></d-pagination>`) as Pagination;
        expect(pagination.current).toBe(2);

        const page3 = screen.queryByText("3", { selector: "a" });
        expect(page3).toBeDefined();
        page3?.click();

        expect(searchQuery.queryParams.params.get("page")).toBe("3");
    });
});
