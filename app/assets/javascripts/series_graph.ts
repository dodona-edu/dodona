import * as d3 from "d3";

const d3Locale = {
    "dateTime": I18n.t("time.formats.default"),
    "date": I18n.t("date.formats.short"),
    "time": I18n.t("time.formats.short"),
    "periods": [I18n.t("time.am"), I18n.t("time.pm")],
    "days": I18n.t("date.day_names"),
    "shortDays": I18n.t("date.abbr_day_names"),
    "months": I18n.t("date.month_names").slice(1),
    "shortMonths": I18n.t("date.abbr_month_names").slice(1)
};

export abstract class SeriesGraph {
    protected selector = "";
    protected container: d3.Selection<HTMLDivElement, unknown, HTMLElement, unknown>; // parent div
    protected width = 0;
    protected height = 0;

    protected exOrder: string[]; // array of exId's (in correct order)
    protected exMap: Record<string, string>; // map from exId -> exName

    protected readonly longDateFormat = d3.timeFormat(I18n.t("date.formats.weekday_long"));

    // abstract functions
    abstract draw(): void;
    abstract prepareData(raw: Record<string, unknown>, url: string): void;

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
        selection.each((datum, i, nodeList) => {
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

    // Displays an error message when there is not enough data
    drawNoData(): void {
        d3.select(this.selector)
            .style("height", "50px")
            .append("div")
            .text(I18n.t("js.no_data"))
            .attr("class", "graph_placeholder");
    }

    // Initializes the container for the graph +
    // puts placeholder text when data isn't loaded +
    // starts data loading (and transforming) procedure
    init(url: string, containerId: string): void {
        this.selector = containerId;
        this.container = d3.select(this.selector);

        if (!this.height) {
            this.height = this.container.node().getBoundingClientRect().height - 5;
        }
        this.container
            .html("") // clean up possible previous visualisations
            .style("height", `${this.height}px`)
            .append("div")
            .text(I18n.t("js.loading"))
            .attr("class", "graph_placeholder");

        this.width = (this.container.node() as Element).getBoundingClientRect().width;

        d3.timeFormatDefaultLocale(d3Locale);
        d3.json(url).then((r: Record<string, unknown>) => {
            this.prepareData(r, url);
        });
    }
}
