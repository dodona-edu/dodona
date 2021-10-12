// eslint-disable-next-line
// @ts-nocheck
import * as d3 from "d3";
import { RawData, SeriesGraph } from "./series_graph";

export class CTimeseriesGraph extends SeriesGraph {
    protected readonly baseUrl = "/stats/cumulative_timeseries?series_id=";
    protected readonly margin = { top: 20, right: 50, bottom: 80, left: 40 };

    private readonly bisector = d3.bisector((d: Date) => d.getTime()).left;

    // scales
    private x: d3.ScaleTime<number, number>;
    private y: d3.ScaleLinear<number, number>;
    private color: d3.ScaleOrdinal<string, unknown>;

    // tooltips things
    private tooltip: d3.Selection<HTMLDivElement, unknown, HTMLElement, unknown>;
    private tooltipIndex = -1; // used to prevent unnecessary tooltip updates
    private tooltipLine: d3.Selection<SVGLineElement, unknown, HTMLElement, any>;
    private tooltipDots: d3.Selection<
        Element | SVGCircleElement | d3.EnterElement | Document | Window | null,
        unknown,
        SVGGElement,
        any
        >;

    // data
    // eslint-disable-next-line camelcase
    private data: { ex_id: string, ex_data: { bin: d3.Bin<Date, Date>, cSum: number }[] }[] = [];
    private maxSum: number; // largest y-value = either subscribed students or max value
    private dateArray: Date[]; // an array of dates from minDate -> maxDate (in days)

    /**
    * Draws the graph's svg (and other) elements on the screen
    * No more data manipulation is done in this function
    * @param {Boolean} animation Whether to play animations (disabled on a resize redraw)
    */
    protected override draw(animation=true): void {
        this.height = 400;
        super.draw();

        const minDate = this.dateArray[0];
        const maxDate = this.dateArray[this.dateArray.length - 1];

        // Y scale
        this.y = d3.scaleLinear()
            .domain([0, 1])
            .range([this.innerHeight, 0]);

        // Y axis
        this.graph.append("g")
            .call(d3.axisLeft(this.y).ticks(5, ".0%"));

        // X scale
        this.x = d3.scaleTime()
            .domain([minDate, maxDate])
            .range([0, this.innerWidth]);

        // add x-axis
        this.graph.append("g")
            .attr("transform", `translate(0, ${this.y(0)})`)
            .call(d3.axisBottom(this.x)
                .tickValues(this.dateArray.filter((e, i, a) => {
                    if (a.length < 10) return true;
                    if (i === 0 || i === a.length - 1) return true;
                    if (i % Math.floor(a.length / 10) === 0) return true;
                    return false;
                }))
                .tickFormat(d3.timeFormat(I18n.t("date.formats.weekday_short")))
            );

        // Color scale
        this.color = d3.scaleOrdinal()
            .range(d3.schemeDark2)
            .domain(this.exOrder);

        // Tooltip
        this.tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);
        this.tooltipLine = this.graph.append("line")
            .attr("y1", 0)
            .attr("y2", this.innerHeight)
            .attr("pointer-events", "none")
            .attr("stroke", "currentColor")
            .attr("opacity", 0);
        this.tooltipDots = this.graph.selectAll(".tooltipDot")
            .data(this.data, ex => ex.ex_id)
            .join("circle")
            .attr("class", "tooltipDot")
            .attr("r", 4)
            .attr("opacity", 0)
            .style("fill", ex => this.color(ex.ex_id) as string);

        this.legendInit();

        // add lines
        // eslint-disable-next-line camelcase
        this.data.forEach(({ ex_data, ex_id }) => {
            const exGroup = this.graph.append("g");
            exGroup.selectAll("path")
                // I have no idea why this is necessary but removing the '[]' breaks everything
                // eslint-disable-next-line camelcase
                .data([ex_data])
                .join("path")
                .style("stroke", this.color(ex_id) as string)
                .style("fill", "none")
                .attr("d", d3.line()
                    .x(d => this.x(d.bin["x0"]))
                    .y(this.innerHeight)
                    .curve(d3.curveMonotoneX)
                )
                .transition().duration(animation ? 500 : 0)
                .attr("d", d3.line()
                    .x(d => this.x(d.bin["x0"]))
                    .y(d => this.y(d.cSum / this.maxSum))
                    .curve(d3.curveMonotoneX)
                );
        });

        this.svg.on("mouseover", e => this.tooltipOver(e));
        this.svg.on("mousemove", e => this.tooltipMove(e));
        this.svg.on("mouseleave", () => this.tooltipOut());
    }

    /**
     * Transforms the data from the server into a form usable by the graph.
     *
     * @param {RawData} raw The unprocessed return value of the fetch
     */
    // eslint-disable-next-line camelcase
    protected override processData({ data, exercises, student_count }: RawData): void {
        // eslint-disable-next-line camelcase
        data as { ex_id: number, ex_data: (string | Date)[] }[];

        this.parseExercises(exercises, data.map(ex => ex.ex_id));

        data.forEach(ex => {
            // convert dates form strings to actual date objects
            ex.ex_data = ex.ex_data.map((d: string) => new Date(d));
        });

        let [minDate, maxDate] = d3.extent(data.flatMap(ex => ex.ex_data)) as Date[];
        minDate = d3.timeDay.offset(new Date(minDate), -1); // start 1 day earlier from 0
        maxDate = new Date(maxDate);
        minDate.setHours(0, 0, 0, 0); // set start to midnight
        maxDate.setHours(23, 59, 59, 99); // set end right before midnight

        this.dateArray = d3.timeDays(minDate, maxDate);

        const threshold = d3.scaleTime()
            .domain([minDate.getTime(), maxDate.getTime()])
            .ticks(d3.timeDay);

        // eslint-disable-next-line camelcase
        this.maxSum = student_count; // max value
        // bin data per day (for each exercise)
        data.forEach(ex => {
            const binned = d3.bin()
                .value(d => d.getTime())
                .thresholds(threshold)
                .domain([minDate.getTime(), maxDate.getTime()])(ex.ex_data);
            // combine bins with cumsum of the bins
            const cSums = d3.cumsum(binned, d => d.length);
            this.data.push({
                ex_id: String(ex.ex_id),
                ex_data: binned.map((bin, i) => ({ bin: bin, cSum: cSums[i] }))
            });

            // if 'students' undefined calculate max value from data
            this.maxSum = Math.max(cSums[cSums.length - 1], this.maxSum);
        });
    }

    // utility functions

    /**
     * Calculates the closest data point near the x-position of the mouse.
     *
     * @param {number} mx The x position of the mouse cursor
     * @return {Object} The index of the cursor in the date array + the date of that position
     */
    private bisect(mx: number): { "date": Date; "i": number } {
        const min = this.dateArray[0];
        const max = this.dateArray[this.dateArray.length - 1];
        if (!this.dateArray) { // probably not necessary, but just to be safe
            return { "date": new Date(0), "i": 0 };
        }
        const date = this.x.invert(mx);
        const index = this.bisector(this.dateArray, date, 1);
        const a = index > 0 ? this.dateArray[index - 1] : min;
        const b = index < this.dateArray.length ? this.dateArray[index] : max;
        if (
            index < this.dateArray.length &&
            date.getTime() - a.getTime() > b.getTime() - date.getTime()
        ) {
            return { "date": b, "i": index };
        } else {
            return { "date": a, "i": index - 1 };
        }
    }

    /**
     * Hide tooltips on mouse out
     */
    private tooltipOut(): void {
        this.tooltipIndex = -1;
        this.tooltip.style("opacity", 0);
        this.tooltipLine.attr("opacity", 0);
        this.tooltipDots.attr("opacity", 0);
    }

    /**
     * Show tooltip with data for the closest data point
     *
     * @param {unknown} e The mouse event
     */
    private tooltipOver(e: unknown): void {
        if (!this.dateArray) {
            return;
        }
        // find insert point in array
        const { date, i } = this.bisect(d3.pointer(e, this.graph.node())[0]);
        this.tooltip
            .html(this.tooltipText(i))
            .style("left", `${this.x(date) + this.margin.left + 5}px`)
            .style("top", `${this.margin.top}px`);

        this.tooltipLine
            .attr("x1", this.x(date))
            .attr("x2", this.x(date));

        this.tooltipDots
            .attr("cx", this.x(date))
            .attr("cy", ex => this.y(ex.ex_data[i].cSum / this.maxSum));
    }

    /**
     * Show tooltip with data for the closest data point
     *
     * @param {unknown} e The mouse event
     */
    private tooltipMove(e: unknown): void {
        if (!this.dateArray) {
            return;
        }
        // find insert point in array
        const { date, i } = this.bisect(d3.pointer(e, this.graph.node())[0]);
        if (i !== this.tooltipIndex) { // check if tooltip position changed
            this.tooltipIndex = i;

            this.tooltip
                .html(this.tooltipText(i))
                .transition()
                .duration(100)
                .style("opacity", 0.9)
                .style("left", `${this.x(date) + this.margin.left + 5}px`)
                .style("top", `${this.margin.top}px`);

            this.tooltipLine
                .transition()
                .duration(100)
                .attr("opacity", 1)
                .attr("x1", this.x(date))
                .attr("x2", this.x(date));

            this.tooltipDots
                .transition()
                .duration(100)
                .attr("opacity", 1)
                .attr("cx", this.x(date))
                .attr("cy", ex => this.y(ex.ex_data[i].cSum / this.maxSum));
        }
    }

    private tooltipText(i: number): string {
        let result = `<b>${this.longDateFormat(this.dateArray[this.tooltipIndex])}</b>`;
        this.exOrder.forEach(e => {
            const ex = this.data.find(ex => ex.ex_id === e);
            result += `<br><span style="color: ${this.color(e)}">&FilledSmallSquare;</span> ${d3.format(".1%")(ex.ex_data[i].cSum / this.maxSum)}
                    (${ex.ex_data[i].cSum}/${this.maxSum})`;
        });
        return result;
    }

    private legendInit(): void {
        // calculate legend element offsets
        const legend = this.container
            .append("div")
            .attr("class", "legend")
            .style("margin-top", "-50px")
            .selectAll("div")
            .data(this.exOrder)
            .enter()
            .append("div")
            .attr("class", "legend-item");
        legend
            .append("div")
            .attr("class", "legend-box")
            .style("background", exId => this.color(exId));
        legend
            .append("span")
            .attr("class", "legend-text")
            .text(exId => this.exMap[exId])
            .style("color", "currentColor")
            .style("font-size", `${this.fontSize}px`);
    }
}
