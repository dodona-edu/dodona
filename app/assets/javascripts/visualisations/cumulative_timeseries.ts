// eslint-disable-next-line
// @ts-nocheck
import * as d3 from "d3";
import { RawData, SeriesGraph } from "./series_graph";
import { i18n } from "i18n/i18n";

export class CTimeseriesGraph extends SeriesGraph {
    protected readonly baseUrl = "/stats/cumulative_timeseries?series_id=";
    protected readonly margin = { top: 20, right: 50, bottom: 80, left: 50 };

    private readonly bisector = d3.bisector((d: number) => d).left;

    // scales
    private x: d3.ScaleTime<number, number>;
    private y: d3.ScaleLinear<number, number>;
    private color: d3.ScaleOrdinal<string, unknown>;

    // axes
    private xAxis: d3.Selection<SVGGElement, unknown, HTMLElement, unknown>;
    private yAxis: d3.Selection<SVGGElement, unknown, HTMLElement, unknown>;

    // tooltips things
    private tooltip: d3.Selection<HTMLDivElement, unknown, HTMLElement, unknown>;
    private tooltipIndex = -1; // used to prevent unnecessary tooltip updates
    private tooltipLine: d3.Selection<SVGLineElement, unknown, HTMLElement, unknown>;
    private tooltipDots: d3.Selection<
        Element | SVGCircleElement | d3.EnterElement | Document | Window | null,
        unknown,
        SVGGElement,
        unknown
        >;

    // data

    private data: { ex_id: string, ex_data: { bin: d3.Bin<Date, Date>, cSum: number }[] }[] = [];
    private studentCount: number; // amount of subscribed students
    private maxSum = 0; // largest y-value == max value
    private minDate: Date;
    private maxDate: Date;
    private binTicks: Array<number>;
    private binStep: number;
    private y100 = false; // Whether y range goes to 100% (true) of max of the data (false)

    /**
    * Draws the graph's svg (and other) elements that never change on the screen
    * No more data manipulation is done in this function
    * @param {Boolean} animation Whether to play animations (disabled on a resize redraw)
    */
    protected override draw(animation=true): void {
        if (this.binTicks.length < 2) {
            this.drawNoData();
            return;
        }
        this.height = 400;
        super.draw();

        this.y = d3.scaleLinear()
            .domain([0, this.y100 ? 1 : this.maxSum / this.studentCount])
            .range([this.innerHeight, 0]);

        // Y axis
        this.yAxis = this.graph.append("g");

        // X scale
        this.x = d3.scaleTime()
            .domain(this.binTicks)
            .range([0, this.innerWidth]);

        // add x-axis
        this.xAxis = this.graph.append("g");

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
        this.graph.selectAll(".line")
            .data(this.data, ex => ex.ex_id )
            .join("path")
            .attr("class", "line")
            .style("stroke", ex => this.color(ex.ex_id) as string)
            .style("fill", "none")
            .attr("d", ex => d3.line()
                .x(d => this.x(d.x1))
                .y(this.innerHeight)
                .curve(d3.curveMonotoneX)(ex.ex_data)
            );

        // tooltip functionality
        this.svg.on("mouseover", e => this.tooltipOver(e));
        this.svg.on("mousemove", e => this.tooltipMove(e));
        this.svg.on("mouseleave", () => this.tooltipOut());

        // y range toggle functionality
        // add a rect behind y-axis for bigger clickable area
        this.graph.append("rect")
            .attr("width", 50)
            .attr("height", this.innerHeight+10)
            .attr("x", -50)
            .attr("y", -10)
            .attr("fill", "none")
            .attr("pointer-events", "all")
            .style("cursor", "pointer")
            .on("click", () => this.yRangeToggle());

        this.drawUpdate(animation);
    }

    private drawUpdate(animation=true): void {
        // update Y scale
        this.y = d3.scaleLinear()
            .domain([0, this.y100 ? 1 : this.maxSum / this.studentCount])
            .range([this.innerHeight, 0]);

        this.yAxis
            .transition().duration(animation ? 500: 0)
            .call(d3.axisLeft(this.y).ticks(5, "%"));

        // updateX scale
        this.x = d3.scaleTime()
            .domain([this.minDate, this.maxDate])
            .range([0, this.innerWidth]);

        this.xAxis
            .attr("transform", `translate(0, ${this.innerHeight})`)
            .call(d3.axisBottom(this.x)
                .tickValues(
                    this.binTicks
                )
                .tickFormat(t => {
                    const asDate = new Date(t);
                    const timeZoneDiff = (asDate.getTimezoneOffset() - this.minDate.getTimezoneOffset()) / 60;
                    return this.binStep >= 24 ||
                        (
                            asDate.getHours() === (24 - timeZoneDiff) % 24 &&
                            asDate.getMinutes() === 0
                        ) ?
                        d3.timeFormat(i18n.t("date.formats.weekday_short"))(t):
                        d3.timeFormat(i18n.t("time.formats.plain_time"))(t);
                })
            )
            .selectAll("text")
            .style("text-anchor", "end")
            .attr("dy", ".7em")
            .attr("transform", "rotate(-25)");

        // add lines
        this.graph.selectAll(".line")
            .data(this.data, ex => ex.ex_id )
            .join("path")
            .transition().duration(animation ? 500: 0)
            .attr("d", ex => d3.line()
                .x(d => this.x(d.x1))
                .y(d => this.y(d.cSum / this.studentCount))
                .curve(d3.curveMonotoneX)(ex.ex_data)
            );
    }

    /**
     * Transforms the data from the server into a form usable by the graph.
     *
     * @param {RawData} raw The unprocessed return value of the fetch
     */
    // eslint-disable-next-line camelcase
    protected override processData({ data, exercises, student_count, deadline }: RawData): void {
        this.data = [];

        data as { ex_id: number, ex_data: (string | Date)[] }[];

        this.parseExercises(exercises, data.map(ex => ex.ex_id));

        data.forEach(ex => {
            // convert dates form strings to actual date objects
            ex.ex_data = ex.ex_data.map((d: string) => new Date(d));
        });

        let [minDate, maxDate] = d3.extent(data.flatMap(ex => ex.ex_data)) as Date[];

        if (deadline) {
            maxDate = deadline;
        }

        this.minDate = this.dateStart ? new Date(this.dateStart) : new Date(minDate);
        this.maxDate = this.dateEnd ? new Date(this.dateEnd) : new Date(maxDate);

        // aim for 17 bins (between 15 and 20)
        const [binStep, binTicks, allignedStart] = this.findBinTime(this.minDate, this.maxDate, 17);
        this.binStep = binStep;
        this.binTicks = binTicks;
        this.minDate = allignedStart;
        this.maxDate = new Date(this.binTicks[this.binTicks.length - 1]);

        if (this.binTicks.length < 2) {
            return;
        }

        if (!this.dateStart) {
            this.setPickerDates(this.minDate, this.maxDate);
        }

        // eslint-disable-next-line camelcase
        this.studentCount = student_count; // max value
        this.maxSum = 0;
        // bin data per day (for each exercise)
        data.forEach(ex => {
            const binned = d3.bin()
                .value(d => d.getTime())
                .thresholds(binTicks)
                .domain([0, this.maxDate.getTime()])(ex.ex_data);
            // combine bins with cumsum of the bins
            const binAmount = binned.length;
            if (binned[binAmount-1].x0 === binned[binAmount-1].x1) {
                binned.pop();
            }
            const cSums = d3.cumsum(binned, d => d.length);
            this.data.push({
                ex_id: String(ex.ex_id),
                ex_data: binned.map((bin, i) => ({ x1: bin["x1"], cSum: cSums[i] }))
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
        const min = this.minDate.getTime();
        const max = this.maxDate.getTime();
        if (!this.binTicks) { // probably not necessary, but just to be safe
            return { "date": new Date(0), "i": 0 };
        }
        const date = this.x.invert(mx);
        const index = this.bisector(this.binTicks, date, 1);
        const a = index > 0 ? this.binTicks[index - 1] : min;
        const b = index < this.binTicks.length ? this.binTicks[index] : max;
        if (
            index < this.binTicks.length &&
            date.getTime() - a > b - date.getTime()
        ) {
            return { "date": new Date(b), "i": index };
        } else {
            return { "date": new Date(a), "i": index - 1 };
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
        if (!this.binTicks) {
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
            .attr("cy", ex => this.y(ex.ex_data[i].cSum / this.studentCount));
    }

    /**
     * Show tooltip with data for the closest data point
     *
     * @param {unknown} e The mouse event
     */
    private tooltipMove(e: unknown): void {
        if (!this.binTicks) {
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
                .attr("cy", ex => this.y(ex.ex_data[i].cSum / this.studentCount));
        }
    }

    private tooltipText(i: number): string {
        const date = this.binTicks[i];
        let message = "";

        if (this.binStep < 24) {
            const on = i18n.t("js.date_on");
            const timeFormat = d3.timeFormat(i18n.t("time.formats.plain_time"));
            message += timeFormat(date);
            message += ` ${on} `;
        }

        const weekDay = d3.timeFormat(i18n.t("date.formats.weekday_long"));
        message += weekDay(date);

        this.exOrder.forEach(e => {
            const ex = this.data.find(ex => ex.ex_id === e);
            message += `<br><span style="color: ${this.color(e)}">&FilledSmallSquare;</span> ${d3.format(".1%")(ex.ex_data[i].cSum / this.studentCount)}
                    (${ex.ex_data[i].cSum}/${this.studentCount})`;
        });

        return "<b>" + message + "</b>";
    }

    private yRangeToggle(): void {
        this.y100 = !this.y100;

        this.tooltipOut();
        this.drawUpdate();
    }

    private legendInit(): void {
        // calculate legend element offsets
        const legend = this.container
            .append("div")
            .attr("class", "legend")
            .style("margin-top", "-30px")
            .selectAll("div")
            .data(this.exOrder)
            .enter()
            .append("div")
            .attr("class", "legend-item")
            .on("mouseover", (_, legendId) => {
                this.graph
                    .selectAll(".line")
                    .style("opacity", lineEx => legendId !== lineEx.ex_id ? .2 : 1);
            })
            .on("mouseout", () => {
                this.graph
                    .selectAll(".line")
                    .style("opacity", 1);
            });
        legend
            .append("div")
            .attr("class", "legend-box")
            .style("background", exId => this.color(exId))
            .style("pointer-events", "none");
        legend
            .append("span")
            .attr("class", "legend-text")
            .text(exId => this.exMap[exId])
            .style("color", "currentColor")
            .style("font-size", `${this.fontSize}px`)
            .style("pointer-events", "none");
    }

    protected override init(draw = true, data = undefined): void {
        this.initTimePickers();
        super.init(draw, data);
    }
}
