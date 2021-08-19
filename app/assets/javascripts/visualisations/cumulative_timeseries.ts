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
    private tooltipIndex = -1; // used to prevent unnecessary tooltip updates
    private tooltipLine: d3.Selection<SVGLineElement, unknown, HTMLElement, any>;
    private tooltipLabel: d3.Selection<SVGTextElement, unknown, HTMLElement, any>;
    private tooltipDots: d3.Selection<
        Element | SVGCircleElement | d3.EnterElement | Document | Window | null,
        unknown,
        SVGGElement,
        any
    >;
    private tooltipDotLabels: d3.Selection<
        Element | SVGTextElement | d3.EnterElement | Document | Window | null,
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
    */
    protected override draw(): void {
        this.height = 300;
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
                .tickFormat(d3.timeFormat(I18n.t("date.formats.weekday_short")))
            );

        // Color scale
        this.color = d3.scaleOrdinal()
            .range(d3.schemeDark2)
            .domain(this.exOrder);

        this.tooltipInit();
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
                .transition().duration(500)
                .attr("d", d3.line()
                    .x(d => this.x(d.bin["x0"]))
                    .y(d => this.y(d.cSum / this.maxSum))
                    .curve(d3.curveMonotoneX)
                );
        });

        this.svg.on("mousemove", e => this.tooltipMove(e));

        // lambda necessary to prevent rebinding of 'this' keyword
        this.svg.on("mouseleave", () => this.tooltipDefault());
    }

    /**
     * Transforms the data from the server into a form usable by the graph.
     *
     * @param {RawData} raw The unprocessed return value of the fetch
     */
    protected override processData({ data, exercises, students }: RawData): void {
        // eslint-disable-next-line camelcase
        data as { ex_id: number, ex_data: (string | Date)[] }[];

        this.parseExercises(exercises, data.map(ex => ex.ex_id));

        data.forEach(ex => {
            // convert dates form strings to actual date objects
            ex.ex_data = ex.ex_data.map((d: string) => new Date(d));
        });

        let [minDate, maxDate] = d3.extent(data.flatMap(ex => ex.ex_data)) as Date[];
        minDate = new Date(minDate);
        maxDate = new Date(maxDate);
        minDate.setHours(0, 0, 0, 0); // set start to midnight
        maxDate.setHours(23, 59, 59, 99); // set end right before midnight

        this.dateArray = d3.timeDays(minDate, maxDate);

        const threshold = d3.scaleTime()
            .domain([minDate.getTime(), maxDate.getTime()])
            .ticks(d3.timeDay);

        this.maxSum = students ?? 0; // max value
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

    // tooltip functions

    /**
     * Initializes the tooltip elements along with the settings that never change
     */
    private tooltipInit(): void {
        this.tooltipLine = this.graph.append("line")
            .attr("y1", 0)
            .attr("y2", this.innerHeight)
            .attr("pointer-events", "none")
            .attr("stroke", "currentColor")
            .style("width", 40);
        this.tooltipLabel = this.graph.append("text")
            .attr("y", 0)
            .attr("dominant-baseline", "hanging")
            .attr("fill", "currentColor")
            .attr("font-size", `${this.fontSize}px`);
        this.tooltipDots = this.graph.selectAll(".tooltipDot")
            .data(this.data, ex => ex.ex_id)
            .join("circle")
            .attr("class", "tooltipDot")
            .attr("r", 4)
            .style("fill", ex => this.color(ex.ex_id) as string);
        this.tooltipDotLabels = this.graph.selectAll(".tooltipDotlabel")
            .data(this.data, ex => ex.ex_id)
            .join("text")
            .attr("class", "tooltipDotlabel")
            .attr("fill", ex => this.color(ex.ex_id) as string)
            .attr("font-size", `${this.fontSize}px`);
        this.tooltipDefault();
    }

    /**
     * tooltip settings when mouse is not hovering over svg
    */
    private tooltipDefault(): void {
        this.tooltipIndex = -1;
        const last = this.dateArray.length - 1;
        const date = this.dateArray[last];
        this.tooltipLine
            .attr("x1", this.x(date))
            .attr("x2", this.x(date))
            .attr("opacity", 0.6);
        this.tooltipLabel
            .attr("x", this.x(date) - 5)
            .attr("text-anchor", "end")
            .attr("opacity", 0.6)
            .text(this.longDateFormat(date));
        this.tooltipDots
            .attr("opacity", 0.6)
            .attr("cx", this.x(date))
            .attr("cy", ex => this.y(ex.ex_data[last].cSum / this.maxSum));
        this.tooltipDotLabels
            .attr("x", this.x(date) + 5)
            .attr("y", ex => this.y(ex.ex_data[last].cSum / this.maxSum) - 5)
            .attr("opacity", 0.6)
            .attr("text-anchor", "start")
            .text(
                ex => `${d3.format(".2%")(ex.ex_data[last].cSum / this.maxSum)}`
            );
    }

    /**
     * Function when mouse is moved over the svg, sets the tooltip position and labels
     * @param {unknown} e event parameter, used to check mouse cursor position
     */
    private tooltipMove(e: unknown): void {
        if (!this.dateArray) {
            return;
        }
        // find insert point in array
        const { date, i } = this.bisect(d3.pointer(e, this.graph.node())[0]);
        if (i !== this.tooltipIndex) { // check if tooltip position changed
            this.tooltipIndex = i;
            this.tooltipLine
                .attr("opacity", 1)
                .transition()
                .duration(100)
                .attr("x1", this.x(date))
                .attr("x2", this.x(date));

            const labelMsg = this.longDateFormat(date);
            // check if label won't go out of bounds
            const switchLabel = this.x(date) -
                this.fontSize / 2 * labelMsg.length -
                5 < 0;
            // use main label as reference for switch condition
            const switchDots = this.x(date) +
                this.fontSize / 2 * labelMsg.length +
                5 > this.innerWidth;
            this.tooltipLabel
                .attr("opacity", 1)
                .text(this.longDateFormat(date))
                .attr("text-anchor", switchLabel ? "start" : "end")
                .transition()
                .duration(100)
                .attr("x", switchLabel ? this.x(date) + 5 : this.x(date) - 5);
            this.tooltipDots
                .attr("opacity", 1)
                .transition()
                .duration(100)
                .attr("cx", this.x(date))
                .attr("cy", ex => this.y(ex.ex_data[i].cSum / this.maxSum));
            this.tooltipDotLabels
                .attr("opacity", 1)
                .text(
                    ex => `${d3.format(".2%")(ex.ex_data[i].cSum / this.maxSum)}
                    (${ex.ex_data[i].cSum}/${this.maxSum})`
                )
                .attr("text-anchor", switchDots ? "end" : "start")
                .transition()
                .duration(100)
                .attr("x", switchDots ? this.x(date) - 5 : this.x(date) + 5)
                .attr("y", ex => this.y(ex.ex_data[i].cSum / this.maxSum) - 5);
        }
    }

    private legendInit(): void {
        // calculate legend element offsets
        const exPosition = [];
        let pos = 0;
        Array.from(this.exOrder).reverse().forEach(ex => {
            exPosition.push({ ex_id: ex, pos: pos });
            // rect size (15) + 5 padding + 20 inter-group padding + text length
            pos += 40 + this.fontSize / 2 * this.exMap[ex].length;
        });
        const legend = this.svg
            .append("g")
            .attr("class", "legend")
            .attr(
                "transform",
                `translate(${this.width / 2 - pos / 2}, ${this.height - this.margin.bottom / 2})`
            )
            .selectAll("g")
            .data(exPosition)
            .enter()
            .append("g")
            .attr("transform", d => `translate(${d.pos}, 0)`);

        // add legend colors dots
        legend
            .append("rect")
            .attr("x", 0)
            .attr("y", 0)
            .attr("width", 15)
            .attr("height", 15)
            .attr("fill", ex => this.color(ex.ex_id) as string);

        // add legend text
        legend
            .append("text")
            .attr("x", 20)
            .attr("y", 12)
            .attr("text-anchor", "start")
            .text(ex => this.exMap[ex.ex_id])
            .attr("fill", "currentColor")
            .style("font-size", `${this.fontSize}px`);
    }
}
