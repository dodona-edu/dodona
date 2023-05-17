import { wrapRangesInHtml } from "mark";

test("marking a range in an empty string should still create a marker", () => {
    const result = wrapRangesInHtml("", [{ start: 0, length: 1 }], "mark", () => undefined);
    expect(result).toBe("<mark></mark>");
});

test("marking a range in a string should create a marker", () => {
    const result = wrapRangesInHtml("Hello World", [{ start: 0, length: 5 }], "mark", () => undefined);
    expect(result).toBe("<mark>Hello</mark> World");
});

test("marking a range in a complex html string should create a marker", () => {
    const result = wrapRangesInHtml("<div><span>H<a>e</a></span>l<div>lo Wo</div>rld</div>", [{ start: 0, length: 5 }], "mark", () => undefined);
    expect(result).toBe("<div><span><mark>H</mark><a><mark>e</mark></a></span><mark>l</mark><div><mark>lo</mark> Wo</div>rld</div>");
});

test("Callback should be called for each marker", () => {
    const callback = jest.fn();
    wrapRangesInHtml("<div><span>H<a>e</a></span>l<div>lo Wo</div>rld</div>", [{ start: 0, length: 5 }], "mark", callback);
    expect(callback).toHaveBeenCalledTimes(4);
});

test("should be able to mark multiple ranges", () => {
    const result = wrapRangesInHtml("<div><span>H<a>e</a></span>l<div>lo Wo</div>rld</div>", [{ start: 0, length: 5 }, { start: 6, length: 2 }], "mark", () => undefined);
    expect(result).toBe("<div><span><mark>H</mark><a><mark>e</mark></a></span><mark>l</mark><div><mark>lo</mark> <mark>Wo</mark></div>rld</div>");
});

test("should be able to mark multiple ranges with overlapping ranges", () => {
    const result = wrapRangesInHtml("<div><span>H<a>e</a></span>l<div>lo Wo</div>rld</div>", [{ start: 0, length: 5 }, { start: 2, length: 2 }], "mark", () => undefined);
    expect(result).toBe("<div><span><mark>H</mark><a><mark>e</mark></a></span><mark>l</mark><div><mark>lo</mark> Wo</div>rld</div>");
});

test("Callback should be called for each marker for each range", () => {
    const callback = jest.fn();
    wrapRangesInHtml("<div><span>H<a>e</a></span>l<div>lo Wo</div>rld</div>", [{ start: 0, length: 5 }, { start: 2, length: 2 }], "mark", callback);
    expect(callback).toHaveBeenCalledTimes(6);
});

test("should be able to edit attributes of the marker in the callback", () => {
    const callback = jest.fn((element, range) => {
        const test = element.getAttribute("data-test") || "";
        element.setAttribute("data-test", test + range.data);
    });
    const result = wrapRangesInHtml("<div><span>H<a>e</a></span>l<div>lo Wo</div>rld</div>", [{ start: 0, length: 5, data: "foo" }, { start: 2, length: 7, data: "bar" }], "mark", callback);
    expect(callback).toHaveBeenCalledWith(expect.any(HTMLElement), { start: 0, length: 5, data: "foo" });
    expect(callback).toHaveBeenCalledWith(expect.any(HTMLElement), { start: 2, length: 7, data: "bar" });
    expect(result).toBe("<div><span><mark data-test=\"foo\">H</mark><a><mark data-test=\"foo\">e</mark></a></span><mark data-test=\"foobar\">l</mark><div><mark data-test=\"foobar\">lo</mark><mark data-test=\"bar\"> Wo</mark></div><mark data-test=\"bar\">r</mark>ld</div>");
});

test("should be able to mark zero length ranges", () => {
    const result = wrapRangesInHtml("<div><span>H<a>e</a></span>l<div>lo Wo</div>rld</div>", [{ start: 0, length: 0 }, { start: 5, length: 0 }, { start: 8, length: 0 }, { start: 11, length: 0 }], "mark", () => undefined);
    expect(result).toBe("<div><span><mark></mark>H<a>e</a></span>l<div>lo<mark></mark> Wo<mark></mark></div>rld<mark></mark></div>");
});
