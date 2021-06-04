import * as d3 from "d3";
import { SeriesGraph } from "series_graph";

export class CTimeseriesGraph extends SeriesGraph {
    protected readonly baseUrl = "/nl/stats/cumulative_timeseries?series_id=";
    private readonly margin = { top: 20, right: 50, bottom: 80, left: 40 };
    private innerWidth: number; // graph width
    private innerHeight: number; // graph height
    private readonly fontSize = 12;

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
    private data: Record<string, [d3.Bin<Date, Date>, number][]>;
    private maxSum: number; // largest y-value = either subscribed students or max value
    private dateArray: Date[]; // an array of dates from minDate -> maxDate (in days)

    /**
    * draws the graph's svg (and other) elements on the screen
    * No more data manipulation is done in this function
    */
    protected draw(): void {
        this.height = 75 * this.exOrder.length;
        this.innerWidth = this.width - this.margin.left - this.margin.right;
        this.innerHeight = this.height - this.margin.top - this.margin.bottom;

        const minDate = this.dateArray[0];
        const maxDate = this.dateArray[this.dateArray.length - 1];

        this.svg = d3.select(this.selector)
            .style("height", `${this.height}px`)
            .append("svg")
            .attr("width", this.width)
            .attr("height", this.height);

        // position graph
        this.graph = this.svg
            .append("g")
            .attr("transform",
                "translate(" + this.margin.left + "," + this.margin.top + ")");

        // axis and scale settings
        // -----------------------------------------------------------------------------------------

        // y scale
        this.y = d3.scaleLinear()
            .domain([0, 1])
            .range([this.innerHeight, 0]);

        // y axis
        this.graph.append("g")
            .call(d3.axisLeft(this.y).ticks(5, ".0%"));

        // X scale
        this.x = d3.scaleTime()
            .domain([minDate, maxDate])
            .range([0, this.innerWidth]);

        // Color scale
        this.color = d3.scaleOrdinal()
            .range(d3.schemeDark2)
            .domain(this.exOrder);

        // add x-axis
        this.graph.append("g")
            .attr("transform", `translate(0, ${this.y(0)})`)
            .call(
                d3.axisBottom(this.x)
                    .tickFormat(d3.timeFormat(I18n.t("date.formats.weekday_short")))
            );

        // -----------------------------------------------------------------------------------------

        // tooltip initialisation
        // -----------------------------------------------------------------------------------------
        this.tooltipInit();
        // -----------------------------------------------------------------------------------------

        // Legend settings
        // -----------------------------------------------------------------------------------------
        this.legendInit();
        // -----------------------------------------------------------------------------------------

        // add lines
        for (const exId of Object.keys(this.data)) {
            const exGroup = this.graph.append("g");
            const bins = this.data[exId];
            exGroup.selectAll("path")
                .data([bins])
                .enter()
                .append("path")
                .style("stroke", this.color(exId) as string)
                .style("fill", "none")
                .attr("d", d3.line()
                    .x(p => this.x(p[0]["x0"]))
                    .y(this.innerHeight)
                    .curve(d3.curveMonotoneX)
                )
                .transition().duration(500)
                .attr("d", d3.line()
                    .x(p => this.x(p[0]["x0"]))
                    .y(p => this.y(p[1]/this.maxSum))
                    .curve(d3.curveMonotoneX)
                );
        }

        this.svg.on("mousemove", e => this.tooltipMove(e));

        this.svg.on("mouseleave", () => {
            this.tooltipDefault();
        });
    }

    /**
     * transforms the data into a form usable by the graph +
     * calculates addinional data
     * finishes by calling draw
     * can be called recursively when a 'data not yet available' response is received
     * @param {Object} raw The unprocessed return value of the fetch
     */
    protected processData(
        raw: {data: Record<string, unknown>, exercises: [number, string][], students?: number}
    ): void {
        const data = raw.data as Record<string, Date[]>;
        this.data = {};

        this.parseExercises(raw.exercises, Object.keys(data));

        Object.entries(data).forEach(([id, submissions]) => {
            // convert dates form strings to actual date objects
            data[id] = submissions.map(d => new Date(d));
        });

        const minDate = new Date(d3.min(Object.values(data), records => d3.min(records)));
        minDate.setHours(0, 0, 0, 0); // set start to midnight
        const maxDate = new Date(d3.max(Object.values(data), records => d3.max(records)));
        maxDate.setHours(23, 59, 59, 99); // set end right before midnight

        this.dateArray = d3.timeDays(minDate, maxDate);

        this.maxSum = raw.students ?? 0; // max value
        // bin data per day (for each exercise)
        Object.entries(data).forEach(([exId, records]) => {
            const binned = d3.bin()
                .value(d => d.getTime())
                .thresholds(
                    d3.scaleTime()
                        .domain([minDate.getTime(), maxDate.getTime()])
                        .ticks(d3.timeDay)
                ).domain([minDate.getTime(), maxDate.getTime()])(records);
            // combine bins with cumsum of the bins
            this.data[exId] = d3.zip(binned, d3.cumsum(binned, d => d.length));

            // if 'students' undefined calculate max value from data
            this.maxSum = Math.max(this.data[exId][this.data[exId].length-1][1], this.maxSum);
        });
    }


    // utility functions

    /**
     * determine where to put tooltip line by 'injecting' the cursor position in the date array
     * @param {number} mx The x position of the mouse cursor
     * @return {Object} The index of the cursor in the date array + the date of that position
     */
    private bisect(mx: number): {"date": Date; "i": number} {
        const min = this.dateArray[0];
        const max = this.dateArray[this.dateArray.length -1];
        if (!this.dateArray) { // probably not necessary, but just to be safe
            return { "date": new Date(0), "i": 0 };
        }
        const date = this.x.invert(mx);
        const index = this.bisector(this.dateArray, date, 1);
        const a = index > 0 ? this.dateArray[index-1] : min;
        const b = index < this.dateArray.length ? this.dateArray[index] : max;
        if (
            index < this.dateArray.length &&
            date.getTime()-a.getTime() > b.getTime()-date.getTime()
        ) {
            return { "date": b, "i": index };
        } else {
            return { "date": a, "i": index-1 };
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
            .data(Object.entries(this.data), d => d[0])
            .join("circle")
            .attr("class", "tooltipDot")
            .attr("r", 4)
            .style("fill", d => this.color(d[0]) as string);
        this.tooltipDotLabels = this.graph.selectAll(".tooltipDotlabel")
            .data(Object.entries(this.data), d => d[0])
            .join("text")
            .attr("class", "tooltipDotlabel")
            .attr("fill", d => this.color(d[0]) as string)
            .attr("font-size", `${this.fontSize}px`);
        this.tooltipDefault();
    }

    /**
     * tooltip settings when mouse is not hovering over svg
    */
    private tooltipDefault(): void {
        this.tooltipIndex = -1;
        const date = this.dateArray[this.dateArray.length-1];
        const last = this.dateArray.length-1;
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
            .attr("cy", d => this.y(d[1][last][1]/this.maxSum));
        this.tooltipDotLabels
            .attr("x", this.x(date) + 5)
            .attr("y", d => this.y(d[1][last][1]/this.maxSum)-5)
            .attr("opacity", 0.6)
            .attr("text-anchor", "start")
            .text(
                d => `${Math.round(d[1][last][1]/this.maxSum*10000)/100}%`
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
                this.fontSize/2*labelMsg.length -
                5 < 0;
            // use main label as reference for switch condition
            const switchDots = this.x(date) +
            this.fontSize/2*labelMsg.length +
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
                .attr("cy", d => this.y(d[1][i][1]/this.maxSum));
            this.tooltipDotLabels
                .attr("opacity", 1)
                .text(
                    d => `${Math.round(d[1][i][1]/this.maxSum*10000)/100}% 
                    (${d[1][i][1]}/${this.maxSum})`
                )
                .attr("text-anchor", switchDots ? "end" : "start")
                .transition()
                .duration(100)
                .attr("x", switchDots ? this.x(date) - 5 : this.x(date) + 5)
                .attr("y", d => this.y(d[1][i][1]/this.maxSum)-5);
        }
    }

    private legendInit(): void {
        // calculate legend element offsets
        const exPosition = [];
        let pos = 0;
        this.exOrder.forEach(ex => {
            exPosition.push([ex, pos]);
            // rect size (15) + 5 padding + 20 inter-group padding + text length
            pos += 40 + this.fontSize/2*this.exMap[ex].length;
        });
        const legend = this.svg
            .append("g")
            .attr("class", "legend")
            .attr(
                "transform",
                `translate(${this.width/2-pos/2}, ${this.height-this.margin.bottom/2})`
            )
            .selectAll("g")
            .data(exPosition)
            .enter()
            .append("g")
            .attr("transform", d => `translate(${d[1]}, 0)`);

        // add legend colors dots
        legend
            .append("rect")
            .attr("x", 0)
            .attr("y", 0)
            .attr("width", 15)
            .attr("height", 15)
            .attr("fill", ex => this.color(ex[0]) as string);

        // add legend text
        legend
            .append("text")
            .attr("x", 20)
            .attr("y", 12)
            .attr("text-anchor", "start")
            .text(ex => this.exMap[ex[0]])
            .attr("fill", "currentColor")
            .style("font-size", `${this.fontSize}px`);
    }
}
