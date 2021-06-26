import * as d3 from "d3";

export type RawData = {
    data: {exId: number, exData: unknown[]}[],
    exercises: [number, string][],
    students?: number
}

export abstract class SeriesGraph {
    private d3Locale = {
        "dateTime": I18n.t("time.formats.default"),
        "date": I18n.t("date.formats.short"),
        "time": I18n.t("time.formats.short"),
        "periods": [I18n.t("time.am"), I18n.t("time.pm")],
        "days": I18n.t("date.day_names"),
        "shortDays": I18n.t("date.abbr_day_names"),
        "months": I18n.t("date.month_names").slice(1),
        "shortMonths": I18n.t("date.abbr_month_names").slice(1)
    }; // when defined as constant variable (outside class) it seems to always default to en
    protected readonly baseUrl!: string;
    private seriesId: string;

    protected selector = "";
    protected container: d3.Selection<HTMLDivElement, unknown, HTMLElement, unknown>; // parent div
    protected svg: d3.Selection<SVGSVGElement, unknown, HTMLElement, unknown>; // the svg
    // group for graph itself
    protected graph: d3.Selection<SVGGElement, unknown, HTMLElement, unknown>
    protected width = 0; // calculated once
    protected height = 0; // can change depending on number of exercises

    protected exOrder: string[] = []; // array of exId's (in correct order)
    protected exMap: Record<string, string> = {}; // map from exId -> exName

    protected readonly longDateFormat = d3.timeFormat(I18n.t("date.formats.weekday_long"));


    /**
     * Initializes the container for the graph +
     * puts placeholder text when data isn't loaded +
     * starts data loading (and transforming) procedure
     * @param {string} seriesId The id of the series
     * @param {string} containerId the id of the html element in which the svg can be displayed
     * @param {Object} data The data used to draw the graph (unprocessed) (optional)
     */
    constructor(seriesId: string, containerId: string, data?: RawData) {
        this.seriesId = seriesId;
        this.selector = containerId;
        this.container = d3.select(this.selector);

        if (!this.height) {
            this.height = this.container.node().getBoundingClientRect().height - 5;
        }
        this.container
            .html("") // clean up possible previous visualisations
            .style("height", `${this.height}px`);

        this.width = (this.container.node() as Element).getBoundingClientRect().width;

        d3.timeFormatDefaultLocale(this.d3Locale);
        if (data) {
            this.processData(data);
            this.draw();
        }
    }

    // abstract functions
    protected abstract draw(): void;
    protected abstract processData(raw: RawData): void;

    /**
     * Breaks up y-axis labels into multiple lines when they get too long
     * @param {*} selection The selection of y-axis labels
     * @param {number} width     The width available to the labels
     * @param {[String, String]} exMap     An array of tuples [exId, exName] to link the two.
     */
    formatTitle(
        selection: d3.Selection<d3.BaseType, unknown, SVGGElement, unknown>,
        width: number, exMap: Record<string, string>
    ): void {
        selection.each((
            datum: string,
            i: number,
            nodeList: d3.BaseType | ArrayLike<d3.BaseType>
        ) => {
            const text = d3.select(nodeList[i]); // select label i

            // find exName corresponding to exId and split on space
            const words = exMap[datum].split(" ").reverse();
            let word = "";
            let line = [];
            let lineNumber = 0;
            const lineHeight = 1.1; // ems
            const y = text.attr("y"); // original y position (usually seems to be 'null')
            const dy = parseFloat(text.attr("dy")); // original y-shift
            let tspan = text.text(null)
                .append("tspan") // similar to html span
                .attr("x", 0)
                .attr("y", y)
                .attr("dy", `${dy}em`);
            while (word = words.pop()) {
                line.push(word);
                tspan.text(line.join(" "));
                // check if the line fits in the allowed width
                if (tspan.node().getComputedTextLength() > width) {
                    line.pop(); // if not remove last word
                    tspan.text(line.join(" "));
                    line = [word]; // start over with new line
                    tspan = text.append("tspan") // create new tspan for new line
                        .attr("x", -0)
                        .attr("y", y)
                        // new line starts a little lower than last one
                        .attr("dy", `${++lineNumber*lineHeight+dy}em`)
                        .text(word)
                        .attr("text-anchor", "end");
                }
            }
            const fontSize = parseInt(tspan.style("font-size"));
            const tSpans = text.selectAll("tspan");
            const breaks = tSpans.size(); // amount of times the name has been split
            // final y position adjustment so everything is centered
            tSpans.attr("y", -fontSize*(breaks-1)/2);
        });
    }

    /**
     * Converts the tuples of exercises into an list of ids indicating the order
     * and a map form id to title
     * ids from the list are only added if they appear in the data
     * @param {[string, string][]} exercises The list of exercise tuples [id, title]
     * @param {string} keys The ids present in the data
     */
    protected parseExercises(exercises: [number, string][], keys: number[]): void {
        exercises.forEach(([id, title]) => {
            // only add if the key is present in the data
            if (keys.indexOf(id) >= 0) {
                this.exOrder.unshift(String(id));
                this.exMap[id] = title;
            }
        });
    }

    /**
     * Displays an error message when there is not enough data
    */
    protected drawNoData(): void {
        d3.select(this.selector)
            .style("height", "50px")
            .append("div")
            .text(I18n.t("js.no_data"))
            .attr("class", "graph_placeholder");
    }

    /**
     * Fetched the data from specified url
     * If the data has a 'not available' status, wait a second and fetch again
     * @param {string} url The url from which to fetch the data from
     * @param {Object} raw The return value of the fetch
     *  used to check if the data should be fetched again
     */
    protected async fetchData(): Promise<RawData> {
        const url = `/${I18n.locale}` + this.baseUrl + this.seriesId;
        let raw: RawData = undefined;
        while (!raw || raw["status"] == "not available yet") {
            raw = await d3.json(url);
            if (raw["status"] == "not available yet") {
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }
        return raw as RawData;
    }

    /**
     * Fetches and processes data
     */
    async init(): Promise<void> {
        // add loading placeholder
        this.container
            .append("div")
            .text(I18n.t("js.loading"))
            .attr("class", "graph_placeholder");

        // fetch data
        const r: RawData = await this.fetchData();
        // once fetched remove placeholder
        this.container.html("");

        if (r.data.length === 0) {
            this.drawNoData();
        }
        // next process the data
        this.processData(r);
        // next draw the graph
        this.draw();
    }
}
