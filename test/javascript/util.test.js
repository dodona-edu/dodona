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
    multipleValueUrl = "https://example.com/test_functions?param=paramVal1&param=paramVal2&param=paramVal3";
});

test("return correct parameter value if present", () => {
    expect(getURLParameter("param", relativePathParameter)).toBe("paramVal");
    expect(getURLParameter("param1", oneParameterURL)).toBe("paramVal1");
    expect(getURLParameter("param2", twoParameterURL)).toBe("paramVal2");
    expect(getURLParameter("param", multipleValueUrl)).toBe("paramVal1");

    expect(getArrayURLParameter("param", relativePathParameter)).toEqual(["paramVal"]);
    expect(getArrayURLParameter("param1", twoParameterURL)).toEqual(["paramVal1"]);
    expect(getArrayURLParameter("param", multipleValueUrl)).toEqual(["paramVal1", "paramVal2", "paramVal3"]);
});

test("return null or empty list when parameter not present", () => {
    expect(getURLParameter("param", relativePath)).toBe(null);
    expect(getURLParameter("param", noParameterURL)).toBe(null);
    expect(getURLParameter("wrongParam", oneParameterURL)).toBe(null);

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

    updatedURL = updateURLParameter(multipleValueUrl, "param", "newParamVal");
    expect(updatedURL).toEqual(`${noParameterURL}?param=newParamVal`);

    updatedURL = updateURLParameter(oneParameterURL, "param1");
    expect(updatedURL).toEqual(noParameterURL);

    // test updateArrayURLParameter
    updatedURL = updateArrayURLParameter(relativePath, "param", ["paramVal1", "paramVal1", "paramVal2"]);
    expect(updatedURL).toEqual(`${window.location.origin}${relativePath}?param=paramVal1&param=paramVal2`)

    updatedURL = updateArrayURLParameter(noParameterURL, "param", ["paramVal1", "paramVal1", "paramVal2", "paramVal3"]);
    expect(updatedURL).toEqual(`${noParameterURL}?param=paramVal1&param=paramVal2&param=paramVal3`);

    updatedURL = updateArrayURLParameter(oneParameterURL, "param2", ["paramVal2"]);
    expect(updatedURL).toEqual(`${oneParameterURL}&param2=paramVal2`);

    updatedURL = updateArrayURLParameter(multipleValueUrl, "param", ["paramVal1", "paramVal2"]);
    expect(updatedURL).toEqual(`${noParameterURL}?param=paramVal1&param=paramVal2`);

    updatedURL = updateArrayURLParameter(oneParameterURL, "param1", []);
    expect(updatedURL).toEqual(noParameterURL);
});
