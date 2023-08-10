// see https://stackoverflow.com/questions/39830580/jest-test-fails-typeerror-window-matchmedia-is-not-a-function
Object.defineProperty(window, "matchMedia", {
    writable: true,
    value: jest.fn().mockImplementation(query => ({
        matches: false,
        media: query,
        onchange: null,
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
        dispatchEvent: jest.fn(),
    })),
});

import { ViolinGraph } from "visualisations/violin";
import { StackedStatusGraph } from "visualisations/stacked_status";
import { CTimeseriesGraph } from "visualisations/cumulative_timeseries";
import { TimeseriesGraph } from "visualisations/timeseries";
import { SeriesGraph } from "visualisations/series_graph";

beforeAll(() => {
    jest
        .spyOn(I18n, "t")
        .mockImplementation(arg => ({
            "time.formats.default": "%d-%m-%Y",
            "date.formats.short": "%e %b",
            "time.formats.flatpickr_long": "F j Y H:i",
            "time.formats.flatpickr_short": "m/d/Y H:i",
            "time.am": "'s ochtends",
            "time.pm": "'s middags",
            "js.no_data": "Er is niet genoeg data om een grafiek te maken."
        }[arg]) as string);
    jest
        .spyOn(I18n, "t_a")
        .mockImplementation(arg => ({
            "date.day_names": [
                "Zondag", "Maandag", "Dinsdag", "Woensdag", "Donderdag", " Vrijdag", "Zaterdag"
            ],
            "date.abbr_day_names": ["Zo", "Ma", "Di", "Wo", "Do", "Vr", "Za"],
            "date.month_names": [
                null, "januari", "februari", "maart", "april", "mei", "juni",
                "juli", "augustus", "september", "oktober", "november", "december"
            ],
            "date.abbr_month_names": [
                null, "Jan", "Feb", "Mrt", "Apr", "Mei", "Jun",
                "Jul", "Aug", "Sep", "Okt", "Nov", "Dec"]
        }[arg]) as string[]);
    I18n.locale = "nl";


    document.body.innerHTML = "" +
    "<div class='daterange-picker' id='daterange-<%= series.id %>'>" +
        "<div class='input-group date-picker' id='scope-start-<%= series.id %>'>" +
            "<input type='text' class='form-control' data-input>" +
        "</div>" +
        "<div class='input-group date-picker' id='scope-end-<%= series.id %>'>" +
            "<input type='text' class='form-control' data-input>" +
        "</div>" +
        "<button class='btn btn-icon' id='scope-apply-<%= series.id %>'></button>" +
    "</div>";
});

afterAll(() => {
    jest.restoreAllMocks();
});

describe("Violin tests", () => {
    let violin;
    const data = {
        data: [{ ex_id: 1, ex_data: [4, 5, 2] }], exercises: [[1, "test"]], student_count: 3
    };
    beforeEach(() => {
        document.body.innerHTML += "<div id='container'></div>";
        violin = new ViolinGraph(
            "1", "#container"
        );
    });

    test("ViolinGraph should generate correct url", () => {
        const url = violin["getUrl"]();
        expect(url).toMatch("/nl/stats/violin?series_id=1");
    });

    test("ViolinGraph should correctly transform data", () => {
        violin.processData(data);
        expect(violin.data).toHaveLength(1);
        const datum = violin["data"][0];
        expect(datum["ex_id"]).toBe("1");
        expect(datum["counts"]).toEqual([2, 4, 5]); // same as input, but sorted
        expect(datum["average"]).toBe((2+4+5)/3);
        expect(datum["freq"]).toHaveLength(violin["maxSubmissions"] + 1);
        expect(violin["maxFreq"]).toBe(1);
    });
});

describe("Stacked tests", () => {
    let stacked;
    const data = {
        data: [
            // eslint-disable-next-line
            // @ts-ignore
            { ex_id: 1, ex_data: { "wrong": 9, "correct": 6 } }
        ], exercises: [[1, "test"]], student_count: 3
    };
    beforeEach(() => {
        document.body.innerHTML += "<div id='container'></div>";
        stacked = new StackedStatusGraph(
            "1", "#container"
        );
    });

    test("StackedStatusGraph should generate correct url", () => {
        const url = stacked["getUrl"](); // circumvent typescript access errors
        expect(url).toMatch("/nl/stats/stacked_status?series_id=1");
    });

    test("StackedStatusGraph should correctly transform data", () => {
        stacked.processData(data);
        expect(stacked.data).toHaveLength(7); // one for every status
        expect(stacked.data).toContainEqual(
            { "exercise_id": "1", "status": "correct", "cSum": 0, "count": 6 }
        );
        expect(stacked.data).toContainEqual(
            { "exercise_id": "1", "status": "wrong", "cSum": 6, "count": 9 }
        );
        expect(stacked["maxSum"]).toMatchObject({ "1": 15 });
    });
});

describe("Timeseries tests", () => {
    const tzOffset = new Date("2020-07-11 00:00Z").getTimezoneOffset() * 60000;
    // make sure we're using the defined dateTimes in local time
    const data = {
        data: [
            {
                ex_id: 1,
                ex_data: [
                    {
                        date: new Date(
                            new Date("2020-07-11 00:00Z").getTime() + tzOffset
                        ).toUTCString(),
                        status: "wrong", count: 9
                    },
                    {
                        date: new Date(
                            new Date("2020-07-11 03:59Z").getTime() + tzOffset
                        ).toUTCString(),
                        status: "correct", count: 3
                    },
                    {
                        date: new Date(
                            new Date("2020-07-15 00:00Z").getTime() + tzOffset
                        ).toUTCString(),
                        status: "correct", count: 6
                    }
                ]
            }
        ], exercises: [[1, "test"]], student_count: 3
    };
    let timeseries;
    beforeEach(() => {
        document.body.innerHTML += "<div id='container'></div>";
        timeseries = new TimeseriesGraph(
            "1", "#container"
        );
    });

    test("TimeseriesGraph should generate correct url", () => {
        const url = timeseries["getUrl"](); // circumvent typescript access errors
        expect(url).toMatch("/nl/stats/timeseries?series_id=1");
    });

    test("TimeseriesGraph should correctly transform data", () => {
        timeseries.dateStart = new Date("2020-07-11 00:00Z").toISOString();
        timeseries.processData(data);
        expect(timeseries.data).toHaveLength(1); // one exercise
        expect(timeseries.binStep).toBe(4); // 4 hours per bin
        const ex = timeseries.data[0];
        expect(ex["ex_id"]).toBe("1");
        const datum = ex["ex_data"];
        expect(datum).toHaveLength(25); // 25 bins total
        expect(datum[0]["sum"]).toBe(12); // first two should get binned together
        expect(datum[24]["sum"]).toBe(6); // last datum should be put in last bin

        expect(timeseries["maxStack"]).toBe(12);
    });
});

describe("CTimeseries tests", () => {
    const tzOffset = new Date("2020-07-11 00:00Z").getTimezoneOffset() * 60000;
    const data = {
        data: [
            {
                ex_id: 1,
                ex_data: [
                    new Date(
                        new Date("2020-07-09 00:00Z").getTime() + tzOffset
                    ).toUTCString(),
                    new Date(
                        new Date("2020-07-11 00:00Z").getTime() + tzOffset
                    ).toUTCString(),
                    new Date(
                        new Date("2020-07-11 03:59Z").getTime() + tzOffset
                    ).toUTCString(),
                    new Date(
                        new Date("2020-07-15 00:00Z").getTime() + tzOffset
                    ).toUTCString(),
                ]
            }
        ],
        exercises: [[1, "test"]],
        student_count: 3,
    };
    let cTimeseries;
    beforeEach(() => {
        document.body.innerHTML += "<div id='container'></div>";
        cTimeseries = new CTimeseriesGraph(
            "1", "#container"
        );
    });

    test("CTimeseriesGraph should generate correct url", () => {
        const url = cTimeseries["getUrl"](); // circumvent typescript access errors
        expect(url).toMatch("/nl/stats/cumulative_timeseries?series_id=1");
    });

    test("CTimeseriesGraph should correctly transform data", () => {
        cTimeseries.dateStart = new Date("2020-07-11 00:00Z").toISOString();
        cTimeseries.processData(data);
        expect(cTimeseries.data).toHaveLength(1); // 1 exercise
        expect(cTimeseries.data[0]["ex_id"]).toBe("1");
        expect(cTimeseries.binStep).toBe(4);
        const datum = cTimeseries.data[0]["ex_data"];
        expect(datum).toHaveLength(26); // 25 bins total + 1 for 'before' section
        expect(datum[0]["cSum"]).toBe(1); // 'before' bin should contain 1 submission
        expect(datum[1]["cSum"]).toBe(3); // two submissions in first normal bin + 1 from before
        const last = datum.length - 1;
        expect(datum[last]["cSum"]).toBe(4); // 3 subs from former bins + 1 from last

        expect(cTimeseries["maxSum"]).toBe(4);
    });
});

describe("General tests", () => {
    let graph;
    beforeEach(() => {
        document.body.innerHTML += "<div id='container'></div>";
        // eslint-disable-next-line
        // @ts-ignore
        graph = new SeriesGraph(
            "1", "#container"
        );
    });

    test("parseExercises should produce the correct data", () => {
        graph.parseExercises([["2", "test2"], ["3", "test3"], ["1", "test1"]], ["2", "1"]);
        expect(graph.exOrder).toEqual(["2", "1"]);
        expect(graph.exMap).toMatchObject({ "1": "test1", "2": "test2" });
    });

    test("drawNoData should insert a div", () => {
        expect(document.querySelector("#container").childNodes).toHaveLength(0);
        graph.drawNoData();
        expect(document.querySelector("#container").children.length).toBe(1);
        expect((document.querySelector("#container").firstChild as HTMLElement).innerHTML)
            .toMatch("Er is niet genoeg data om een grafiek te maken.");
    });
});
