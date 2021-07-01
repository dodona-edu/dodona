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
            "time.am": "'s ochtends",
            "time.pm": "'s middags",
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
                "Jul", "Aug", "Sep", "Okt", "Nov", "Dec"],
            "js.no_data": "Er is niet genoeg data om een grafiek te maken."
        }[arg]) as string);
    I18n.locale = "nl";
});

describe("Violin tests", () => {
    let violin;
    const data = {
        data: [{ ex_id: 1, ex_data: [4, 5, 2] }], exercises: [[1, "test"]], students: 3
    };
    beforeEach(() => {
        document.body.innerHTML = "<div id='container'></div>";
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
        expect(datum["median"]).toBe(4);
        expect(datum["average"]).toBe((2+4+5)/3);
        expect(datum["freq"]).toHaveLength(5); // bin from 1-5
        expect(violin["maxCount"]).toBe(5);
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
        ], exercises: [[1, "test"]], students: 3
    };
    beforeEach(() => {
        document.body.innerHTML = "<div id='container'></div>";
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
    const data = {
        data: [
            {
                ex_id: 1,
                ex_data: [
                    { date: "1302-07-11", status: "wrong", count: 9 },
                    { date: "1302-07-11", status: "correct", count: 3 },
                    { date: "1302-07-12", status: "correct", count: 6 }
                ]
            }
        ], exercises: [[1, "test"]], students: 3
    };
    let timeseries;
    beforeEach(() => {
        document.body.innerHTML = "<div id='container'></div>";
        timeseries = new TimeseriesGraph(
            "1", "#container"
        );
    });

    test("TimeseriesGraph should generate correct url", () => {
        const url = timeseries["getUrl"](); // circumvent typescript access errors
        expect(url).toMatch("/nl/stats/timeseries?series_id=1");
    });

    test("TimeseriesGraph should correctly transform data", () => {
        timeseries.processData(data);
        expect(timeseries.data).toHaveLength(1); // one exercise
        const ex = timeseries.data[0];
        expect(ex["ex_id"]).toBe("1");
        const datum = ex["ex_data"];
        expect(datum).toHaveLength(2);
        expect(datum[0]["sum"]).toBe(12); // day 1
        expect(datum[1]["sum"]).toBe(6); // day 2

        expect(timeseries["dateRange"]).toBe(2);
        expect(timeseries["maxStack"]).toBe(12);
    });
});

describe("CTimeseries tests", () => {
    const data = {
        data: [
            {
                ex_id: 1,
                ex_data: [
                    new Date(2021, 7, 29).getTime(),
                    new Date(2021, 7, 30).getTime(),
                    new Date(2021, 7, 30).getTime(),
                    new Date(2021, 7, 30).getTime(),
                ]
            }
        ],
        exercises: [[1, "test"]],
        students: 3
    };
    let cTimeseries;
    beforeEach(() => {
        document.body.innerHTML = "<div id='container'></div>";
        cTimeseries = new CTimeseriesGraph(
            "1", "#container"
        );
    });

    test("CTimeseriesGraph should generate correct url", () => {
        const url = cTimeseries["getUrl"](); // circumvent typescript access errors
        expect(url).toMatch("/nl/stats/cumulative_timeseries?series_id=1");
    });

    test("CTimeseriesGraph should correctly transform data", () => {
        cTimeseries.processData(data);
        expect(cTimeseries.data).toHaveLength(1); // 1 exercise
        expect(cTimeseries.data[0]["ex_id"]).toBe("1");
        const datum = cTimeseries.data[0]["ex_data"];
        expect(datum).toHaveLength(2);
        expect(datum[0]["cSum"]).toBe(1); // one submissions on day 1
        expect(datum[1]["cSum"]).toBe(4); // 3 subs on day 2 + sub on day 1

        expect(cTimeseries["maxSum"]).toBe(4);
    });
});

describe("General tests", () => {
    let graph;
    beforeEach(() => {
        document.body.innerHTML = "<div id='container'></div>";
        // eslint-disable-next-line
        // @ts-ignore
        graph = new SeriesGraph(
            "1", "#container"
        );
    });

    test("parseExercises should produce the correct data", () => {
        graph.parseExercises([["2", "test2"], ["3", "test3"], ["1", "test1"]], ["2", "1"]);
        expect(graph.exOrder).toEqual(["1", "2"]); // should be in reverse order
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
