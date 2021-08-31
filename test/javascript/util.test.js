import { updateArrayURLParameter, updateURLParameter, getURLParameter, getArrayURLParameter } from "../../app/assets/javascripts/util";

let relativePath;
let relativePathParameter;
let noParameterURL;
let oneParameterURL;
let twoParameterURL;
let multipleValueUrl;

beforeEach(() => {
    relativePath = "/test_functions";
    relativePathParameter = "/test_functions?param=paramVal"
    noParameterURL = "https://example.com/test_functions";
    oneParameterURL = "https://example.com/test_functions?param1=paramVal1";
    twoParameterURL = "https://example.com/test_functions?param1=paramVal1&param2=paramVal2";
    // "[]" is converted to "%5B%5D" in a URL
    multipleValueUrl = "https://example.com/test_functions?param%5B%5D=paramVal1&param%5B%5D=paramVal2&param%5B%5D=paramVal3";
});

test("return correct parameter value", () => {
    expect(getURLParameter("param", relativePathParameter)).toBe("paramVal");
    expect(getURLParameter("param1", oneParameterURL)).toBe("paramVal1");
    expect(getURLParameter("param2", twoParameterURL)).toBe("paramVal2");

    expect(getURLParameter("param", relativePath)).toBe(null);
    expect(getURLParameter("param", noParameterURL)).toBe(null);
    expect(getURLParameter("wrongParam", oneParameterURL)).toBe(null);
});

test("return correct array parameter value if present", () => {
    expect(getArrayURLParameter("param", multipleValueUrl)).toEqual(["paramVal1", "paramVal2", "paramVal3"]);

    expect(getArrayURLParameter("param", relativePath)).toEqual([]);
    expect(getArrayURLParameter("param", noParameterURL)).toEqual([]);
    expect(getArrayURLParameter("wrongParam", twoParameterURL)).toEqual([]);
});

test("update URL parameter", () => {
    let updatedURL;

    // test updateURLParameter
    updatedURL = updateURLParameter(relativePath, "param", "paramval")
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

test("Update array URL parameter", () => {
    let updatedURL;

    // test updateArrayURLParameter
    updatedURL = updateArrayURLParameter(relativePath, "param", ["paramVal1", "paramVal1", "paramVal2"]);
    expect(updatedURL).toEqual(`${window.location.origin}${relativePath}?param%5B%5D=paramVal1&param%5B%5D=paramVal2`)

    updatedURL = updateArrayURLParameter(noParameterURL, "param", ["paramVal1", "paramVal1", "paramVal2", "paramVal3"]);
    expect(updatedURL).toEqual(`${noParameterURL}?param%5B%5D=paramVal1&param%5B%5D=paramVal2&param%5B%5D=paramVal3`);

    updatedURL = updateArrayURLParameter(oneParameterURL, "param2", ["paramVal2"]);
    expect(updatedURL).toEqual(`${oneParameterURL}&param2%5B%5D=paramVal2`);

    updatedURL = updateArrayURLParameter(multipleValueUrl, "param", ["paramVal1", "paramVal2"]);
    expect(updatedURL).toEqual(`${noParameterURL}?param%5B%5D=paramVal1&param%5B%5D=paramVal2`);
})
