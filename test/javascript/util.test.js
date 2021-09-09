import {
    updateArrayURLParameter, updateURLParameter, getURLParameter, getArrayURLParameter,
    delay, createDelayer
} from "../../app/assets/javascripts/util";

jest.useFakeTimers();

describe("Url functions", () => {
    const relativePath = "/test_functions";
    const relativePathParameter = "/test_functions?param=paramVal";
    const noParameterURL = "https://example.com/test_functions";
    const oneParameterURL = "https://example.com/test_functions?param1=paramVal1";
    const twoParameterURL = "https://example.com/test_functions?param1=paramVal1&param2=paramVal2";
    // "[]" is converted to "%5B%5D" in a URL
    // eslint-disable-next-line max-len
    const multipleValueUrl = "https://example.com/test_functions?param%5B%5D=paramVal1&param%5B%5D=paramVal2&param%5B%5D=paramVal3";

    test("return correct parameter value", () => {
        expect(getURLParameter("param", relativePathParameter)).toBe("paramVal");
        expect(getURLParameter("param1", oneParameterURL)).toBe("paramVal1");
        expect(getURLParameter("param2", twoParameterURL)).toBe("paramVal2");

        expect(getURLParameter("param", relativePath)).toBe(null);
        expect(getURLParameter("param", noParameterURL)).toBe(null);
        expect(getURLParameter("wrongParam", oneParameterURL)).toBe(null);
    });

    test("return correct array parameter value if present", () => {
        expect(getArrayURLParameter("param", multipleValueUrl))
            .toEqual(["paramVal1", "paramVal2", "paramVal3"]);
        expect(getArrayURLParameter("param", relativePath)).toEqual([]);
        expect(getArrayURLParameter("param", noParameterURL)).toEqual([]);
        expect(getArrayURLParameter("wrongParam", twoParameterURL)).toEqual([]);
    });

    test("update URL parameter", () => {
        let updatedURL = updateURLParameter(relativePath, "param", "paramval");
        expect(updatedURL).toEqual(`${window.location.origin}${relativePath}?param=paramval`);

        updatedURL = updateURLParameter(noParameterURL, "param", "paramVal");
        expect(updatedURL).toEqual(`${noParameterURL}?param=paramVal`);

        updatedURL = updateURLParameter(oneParameterURL, "param1", "newParamVal1");
        expect(updatedURL).toEqual(`${noParameterURL}?param1=newParamVal1`);

        updatedURL = updateURLParameter(twoParameterURL, "param3", "paramVal3");
        expect(updatedURL).toEqual(`${twoParameterURL}&param3=paramVal3`);

        updatedURL = updateURLParameter(oneParameterURL, "param1");
        expect(updatedURL).toEqual(noParameterURL);
    });

    test("update array URL parameter", () => {
        let updatedURL = updateArrayURLParameter(relativePath, "param",
            ["paramVal1", "paramVal1", "paramVal2"]);
        // eslint-disable-next-line max-len
        expect(updatedURL).toEqual(`${window.location.origin}${relativePath}?param%5B%5D=paramVal1&param%5B%5D=paramVal2`);

        updatedURL = updateArrayURLParameter(noParameterURL, "param",
            ["paramVal1", "paramVal1", "paramVal2", "paramVal3"]);
        // eslint-disable-next-line max-len
        expect(updatedURL).toEqual(`${noParameterURL}?param%5B%5D=paramVal1&param%5B%5D=paramVal2&param%5B%5D=paramVal3`);

        updatedURL = updateArrayURLParameter(oneParameterURL, "param2", ["paramVal2"]);
        expect(updatedURL).toEqual(`${oneParameterURL}&param2%5B%5D=paramVal2`);

        updatedURL = updateArrayURLParameter(multipleValueUrl, "param", ["paramVal1", "paramVal2"]);
        expect(updatedURL).toEqual(`${noParameterURL}?param%5B%5D=paramVal1&param%5B%5D=paramVal2`);
    });
});

describe("Delay tests", () => {
    test("delay debounces result", () => {
        const callback = jest.fn(() => {
        });
        delay(callback, 100);
        delay(callback, 100);
        // Fast forward until everything is run.
        jest.advanceTimersByTime(200);
        expect(callback.mock.calls.length).toBe(1);
    });

    test("different delayers are independent", () => {
        const callback = jest.fn(() => {
        });
        const delay1 = createDelayer();
        const delay2 = createDelayer();
        delay(callback, 100);
        delay1(callback, 100);
        delay2(callback, 100);
        // Fast forward until everything is run.
        jest.advanceTimersByTime(200);
        expect(callback.mock.calls.length).toBe(3);
    });
});
