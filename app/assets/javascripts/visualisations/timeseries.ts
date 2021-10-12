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

    // axes
    private x: d3.ScaleTime<number, number>
    private color: d3.ScaleSequential<string>;

    // data
    private maxStack = 0; // largest value (max of colour scale domain)
    private dateRange: number; // difference between first and last date in days
    private minDate: Date;
    private maxDate: Date;

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
        this.x = d3.scaleTime()
            .domain([this.minDate, end])
            .range([5, this.innerWidth]);

        // Axis
        this.graph.append("g")
            .attr("transform", `translate(0, ${this.innerHeight})`)
            .call(
                d3.axisBottom(this.x)
                    .ticks(15, I18n.t("date.formats.weekday_short"))
            );

        // init tooltip
        this.tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);

        // make sure cell size isn't bigger than bandwidth
        // this is commented for now awaiting more data
        // const rectSize = Math.min(this.y.bandwidth()*1.5, this.innerWidth / this.dateRange - 5);
        const rectSize = this.y.bandwidth();
        // add cells
        this.graph.selectAll(".rectGroup")
            .data(this.data)
            .join("g")
            .attr("class", "rectGroup")
            // eslint-disable-next-line camelcase
            .each(({ ex_data, ex_id }, i, group) => {
                d3.select(group[i]).selectAll("rect")
                    .data(ex_data, d => d["date"].getTime())
                    .join("rect")
                    .attr("class", "day-cell")
                    .classed("empty", d => d.sum === 0)
                    .attr("rx", 6)
                    .attr("ry", 6)
                    .attr("fill", emptyColor)
                    .attr("x", d => this.x(d.date) - rectSize / 2)
                    .attr("y", this.y(ex_id))
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
        this.maxDate.setHours(23, 59, 59, 99); // set end right before midnight

        this.dateRange = d3.timeDay.count(this.minDate, this.maxDate) + 1; // dateRange in days
        const threshold = d3.scaleTime()
            .domain([this.minDate.getTime(), this.maxDate.getTime()])
            .ticks(d3.timeDay);

        // eslint-disable-next-line camelcase
        data.forEach(({ ex_id, ex_data }) => {
            // bin per day
            const binned = d3.bin()
                .value(d => d.date.getTime())
                .thresholds(threshold)
                .domain([this.minDate.getTime(), this.maxDate.getTime()])(ex_data);

            const parsedData = [];
            // reduce bins to a single record per bin (see this.data)
            binned.forEach((bin, i) => {
                const newDate = new Date(this.minDate);
                newDate.setDate(newDate.getDate() + i);
                const sum = d3.sum(bin, r => r["count"]);
                this.maxStack = Math.max(this.maxStack, sum);
                parsedData.push(bin.reduce((acc, r) => {
                    acc.date = r.date;
                    acc.sum = sum;
                    acc[r.status] = r.count;
                    return acc;
                }, this.statusOrder.reduce((acc, s) => {
                    acc[s] = 0; // make sure record is initialized with 0 counts
                    return acc;
                }, { "date": newDate, "sum": 0 })));
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
        let message = `<b>${this.longDateFormat(d.date)}</b><br><b>${d.sum} ${I18n.t("js.submissions")}</b>`;
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
