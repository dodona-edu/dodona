// eslint-disable-next-line
// @ts-nocheck
import * as d3 from "d3";
import { RawData } from "./series_graph";
import { SeriesExerciseGraph } from "./series_exercise_graph";

export class TimeseriesGraph extends SeriesExerciseGraph {
    protected readonly baseUrl = "/stats/timeseries?series_id=";

    constructor(seriesId: string, containerId: string, data?: RawData) {
        super(seriesId, containerId, data);
        this.margin.right = 40;
    }

    private format: (d: Date) => string;

    // axes
    private x: d3.ScaleTime<number, number>
    private color: d3.ScaleSequential<string>;

    // data
    private maxStack = 0; // largest value (max of colour scale domain)
    private minDate: Date;
    private maxDate: Date;
    private binTicks: Array<number>;
    private binStep: number;

    private data: {
        "ex_id": string,
        "ex_data": { date: Date; sum: number;[index: string]: number | Date }[]
    }[] = [];

    // svg elements
    private tooltip: d3.Selection<HTMLDivElement, unknown, HTMLElement, unknown>;

    /**
    * draws the graph's svg (and other) elements on the screen
    * No more data manipulation is done in this function
    * @param {Boolean} animation Whether to play animations (disabled on a resize redraw)
    */
    protected override draw(animation=true): void {
        super.draw(animation);

        // no data in cell
        const emptyColor = this.darkMode ? "#37474F" : "white";
        // almost no data in cell
        const lowColor = this.darkMode ? "#01579B" : "#E3F2FD";
        // a lot of data in cell
        const highColor = this.darkMode ? "#039BE5" : "#0D47A1";

        const end = new Date(this.maxDate);
        end.setHours(0, 0, 0, 0); // bin and domain seem to handle end differently

        // Scales
        this.color = d3.scaleSequential(d3.interpolate(lowColor, highColor))
            .domain([0, this.maxStack]);
        this.x = d3.scaleBand()
            .domain(this.binTicks)
            .range([0, this.innerWidth]);

        // Axis
        this.graph.append("g")
            .attr("transform", `translate(0, ${this.innerHeight-this.y.bandwidth()/2})`)
            .call(
                d3.axisBottom(this.x)
                    .tickValues(this.binTicks)
                    .tickFormat(this.binStep > 24 ?
                        d3.timeFormat(I18n.t("date.formats.weekday_short")):
                        d3.timeFormat(I18n.t("time.formats.day_time_short")))
            )
            .selectAll("text")
            .style("text-anchor", "end")
            .attr("dy", ".7em")
            .attr("transform", "rotate(-25)");

        this.graph.select(".domain").remove();

        // init tooltip
        this.tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);

        // make sure cell size isn't bigger than bandwidth
        const rectSize = Math.min(
            this.y.bandwidth()*1.5,
            this.innerWidth / this.binTicks.length - 5
        );
        // add cells
        this.graph.selectAll(".rectGroup")
            .data(this.data)
            .join("g")
            .attr("class", "rectGroup")
            // eslint-disable-next-line camelcase
            .each(({ ex_data, ex_id }, i, group) => {
                d3.select(group[i]).selectAll("rect")
                    .data(ex_data, d => d.date)
                    .join("rect")
                    .attr("class", "day-cell")
                    .classed("empty", d => d.sum === 0)
                    .attr("rx", 6)
                    .attr("ry", 6)
                    .attr("fill", emptyColor)
                    .attr("x", d => this.x(d.date) + (this.x.bandwidth() - rectSize)/2)
                    .attr("y", this.y(ex_id) + (this.y.bandwidth() - rectSize)/2)
                    .on("mouseover", (_e, d) => this.tooltipHover(d))
                    .on("mousemove", e => this.tooltipMove(e))
                    .on("mouseout", () => this.tooltipOut())
                    .transition().duration(animation ? 500 : 0)
                    .attr("width", rectSize)
                    .attr("height", rectSize)
                    .attr("fill", d => d.sum === 0 ? "" : this.color(d.sum));
            });
    }

    /**
     * Transforms the data from the server into a form usable by the graph.
     *
     * @param {RawData} raw The unprocessed return value of the fetch
     */
    protected override processData({ data, exercises }: RawData): void {
        // the type of one datum in the ex_data array
        type Datum = { date: (Date | string); status: string; count: number };

        this.parseExercises(exercises, data.map(ex => ex.ex_id));

        data.forEach(ex => {
            // convert dates form strings to actual date objects
            ex.ex_data.forEach((d: Datum) => {
                d.date = new Date(d.date);
                // make sure they are set to midnight
                d.date.setHours(0, 0, 0, 0);
            });
        });

        const [minDate, maxDate] = d3.extent(
            data.flatMap(ex => ex.ex_data),
            (d: Datum) => d.date as Date
        );
        this.minDate = new Date(minDate);
        this.maxDate = new Date(maxDate);

        this.x = d3.scaleTime()
            .domain([this.minDate.getTime(), this.maxDate.getTime()])
            .ticks(20);

        const [binStep, binTicks, allignedStart] = this.findBinTime(this.minDate, this.maxDate);
        this.binStep = binStep;
        this.binTicks = binTicks;
        this.minDate = allignedStart;

        // eslint-disable-next-line camelcase
        data.forEach(({ ex_id, ex_data }) => {
            const binned = d3.bin()
                .value(d => d.date.getTime())
                .thresholds(binTicks)
                .domain([this.minDate.getTime(), this.maxDate.getTime()])(ex_data);

            const parsedData = [];
            // reduce bins to a single record per bin (see this.data)
            binned.forEach(bin => {
                const sum = d3.sum(bin, r => r["count"]);
                this.maxStack = Math.max(this.maxStack, sum);
                parsedData.push(bin.reduce((acc, r) => {
                    acc.sum = sum;
                    acc[r.status] = r.count;
                    return acc;
                }, this.statusOrder.reduce((acc, s) => {
                    acc[s] = 0; // make sure record is initialized with 0 counts
                    return acc;
                }, { "date": bin.x0, "sum": 0 })));
            });
            this.data.push({ ex_id: String(ex_id), ex_data: parsedData });
        });
    }

    /**
     * Shows date and number of submissions on mouse over
     *
     * @param {Object} d datum for a single rectangle
     */
    private tooltipHover(
        d: {
            [index: string]: number | Date;
            date: Date;
            sum: number;
        }): void {
        this.tooltip.transition()
            .duration(200)
            .style("opacity", .9);
        const format = this.binStep > 24 ?
            this.longDateFormat:
            d3.timeFormat(I18n.t("time.formats.day_time_long"));
        const from = I18n.t("js.from");
        const to = I18n.t("js.to");
        let message = `
            <b>${from[0].toUpperCase()+from.slice(1)}:</b> ${format(d.date)}
            <br>
            <b>${to[0].toUpperCase()+to.slice(1)}:  </b> ${format(new Date(d.date+this.binStep*3600000))}
            <br>
            <b>${d.sum} ${I18n.t("js.submissions")}</b>
            `;
        this.statusOrder.forEach(s => {
            if (d[s]) {
                message += `<br>${d[s]} ${I18n.t(`js.status.${s.replaceAll(" ", "_")}`)}`;
            }
        });
        this.tooltip.html(message);
    }

    /**
     * Update tooltip position on mouse move
     *
     * @param {*} e event parameter, used to determine mouse position
     */
    private tooltipMove(e: unknown): void {
        this.tooltip
            .style("left", `${d3.pointer(e, this.svg.node())[0] + 15}px`)
            .style("top", `${d3.pointer(e, this.svg.node())[1]}px`);
    }

    /**
     * Hide tooltip on mouse out
     */
    private tooltipOut(): void {
        this.tooltip.transition()
            .duration(500)
            .style("opacity", 0);
    }
}
