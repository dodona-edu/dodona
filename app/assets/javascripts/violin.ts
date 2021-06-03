import * as d3 from "d3";
import { SeriesGraph } from "series_graph";


export class ViolinGraph extends SeriesGraph {
    private readonly margin = { top: 20, right: 160, bottom: 40, left: 125 };
    private innerWidth = 0;
    private innerHeight = 0;
    private fontSize = 12;

    // scales
    private x: d3.ScaleLinear<number, number>;

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
    private data: {
        "ex_id": string, "counts": number[],
        "freq": d3.Bin<number, number>[], "median": number, "average": number
    }[];
    private maxCount = 0; // largest y-value
    private maxFreq = 0; // largest x-value

    /**
    * draws the graph's svg (and other) elements on the screen
    * No more data manipulation is done in this function
    */
    protected draw(): void {
        console.log(this.exOrder, this.exOrder.length);
        this.height = 75 * this.exOrder.length;
        this.innerWidth = this.width - this.margin.left - this.margin.right;
        this.innerHeight = this.height - this.margin.top - this.margin.bottom;

        const min = d3.min(this.data, d => d3.min(d.counts));
        const max = d3.max(this.data, d => d3.max(d.counts));
        const xTicks = 10;
        const yAxisPadding = 5; // padding between y axis (labels) and the actual graph

        const svg = this.container
            .style("height", `${this.height}px`)
            .append("svg")
            .attr("width", this.width)
            .attr("height", this.height);
        const graph = svg
            .append("g")
            .attr("transform",
                "translate(" + this.margin.left + "," + this.margin.top + ")");

        // Show the Y scale for the exercises (Big Y scale)
        const y = d3.scaleBand()
            .range([this.innerHeight, 0])
            .domain(this.exOrder)
            .padding(.5);

        const yAxis = graph.append("g")
            .call(d3.axisLeft(y).tickSize(0))
            .attr("transform", `translate(-${yAxisPadding}, 0)`);
        yAxis
            .select(".domain").remove();
        yAxis
            .selectAll(".tick text")
            .call(this.formatTitle, this.margin.left-yAxisPadding, this.exMap, 5);

        // y scale per exercise
        const yBin = d3.scaleLinear()
            .domain([0, this.maxFreq])
            .range([0, y.bandwidth()]);

        // Show the X scale
        this.x = d3.scaleLinear()
            .domain([min, max])
            .range([5, this.innerWidth]);
        graph.append("g")
            .attr("transform", "translate(0," + this.innerHeight + ")")
            .call(d3.axisBottom(this.x).ticks(xTicks))
            .select(".domain").remove();

        // Add X axis label:
        graph.append("text")
            .attr("text-anchor", "end")
            .attr("x", -5)
            .attr("y", this.innerHeight+5)
            .text(I18n.t("js.n_submissions"))
            .attr("class", "violin-label")
            .attr("fill", "currentColor");

        // add the areas
        graph
            .selectAll("violins")
            .data(this.data)
            .enter()
            .append("g")
            .attr("transform", d => `translate(0, ${y(d.ex_id) + y.bandwidth() / 2})`)
            .attr("pointer-events", "none")
            .append("path")
            .datum(ex => {
                return ex.freq;
            })
            .attr("class", "violin-path")
            .attr("d", d3.area()
                .x((_, i) => this.x(i+1))
                .y0(0)
                .y1(0)
                .curve(d3.curveCatmullRom)
            )
            .transition().duration(500)
            .attr("d", d3.area()
                .x((_, i) => this.x(i+1))
                .y0(d => -yBin(d.length))
                .y1(d => yBin(d.length))
                .curve(d3.curveCatmullRom)
            );

        // median dot
        graph
            .selectAll("medianDot")
            .data(this.data)
            .enter()
            .append("circle")
            .style("opacity", 0)
            .attr("cy", d => y(d.ex_id) + y.bandwidth() / 2)
            .attr("cx", d => this.x(d.median))
            .attr("r", 4)
            .attr("fill", "currentColor")
            .attr("pointer-events", "none")
            .transition().duration(500)
            .style("opacity", 1);

        // Additional metrics
        const metrics = graph.append("g")
            .attr("transform", `translate(${this.innerWidth+15}, 0)`);

        metrics.append("rect")
            .attr("width", this.margin.right - 20)
            .attr("height", this.innerHeight)
            .attr("class", "metric-container")
            .attr("rx", 5)
            .attr("ry", 5);

        for (const ex of this.data) {
            // round to two decimals
            const t = Math.round(ex.average*100)/100;
            metrics.append("text")
                .attr("x", (this.margin.right - 20) / 2)
                .attr("y", y(ex.ex_id) + y.bandwidth()/2)
                .text(`${t}`)
                .attr("text-anchor", "middle")
                .attr("fill", "currentColor")
                .style("font-size", "14px");

            metrics.append("text")
                .attr("x", (this.margin.right - 20) / 2)
                .attr("y", y(ex.ex_id) + y.bandwidth())
                .text(
                    `${I18n.t("js.mean")} ${I18n.t("js.submissions")}`
                )
                .attr("text-anchor", "middle")
                .attr("fill", "currentColor")
                .style("font-size", `${this.fontSize}px`);
        }

        // initialize tooltip
        this.tooltipLine = graph.append("line")
            .attr("y1", 0)
            .attr("y2", this.innerHeight)
            .attr("pointer-events", "none")
            .attr("opacity", 0)
            .attr("stroke", "currentColor")
            .style("width", 40);
        this.tooltipLabel = graph.append("text")
            .attr("opacity", 0)
            .attr("y", this.innerHeight - 10)
            .attr("text-anchor", "start")
            .attr("fill", "currentColor")
            .attr("font-size", `${this.fontSize}px`)
            .attr("class", "d3-tooltip-label");
        this.tooltipDots = graph.selectAll("dots")
            .data(this.data, d => d["ex_id"])
            .join("circle")
            .attr("r", 4)
            .attr("transform", d => `translate(0, ${y(d.ex_id) + y.bandwidth() / 2})`)
            .attr("opacity", 0)
            .style("fill", "currentColor");
        this.tooltipDotLabels = graph.selectAll("dotlabels")
            .data(this.data, d => d["ex_id"])
            .join("text")
            .attr("text-anchor", "end")
            .attr("fill", "currentColor")
            .attr("transform", d => `translate(0, ${y(d.ex_id) + y.bandwidth() / 2})`)
            .attr("y", -5)
            .attr("opacity", 0)
            .attr("font-size", `${this.fontSize}px`)
            .attr("class", "d3-tooltip-label");

        svg
            .on("mousemove", e => this.svgMouseMove(e, graph))
            .on("mouseout", () => this.svgMouseOut());
    }


    /**
     * transforms the data into a form usable by the graph +
     * calculates addinional data
     * finishes by calling draw
     * can be called recursively when a 'data not yet available' response is received
     * @param {Object} raw The unprocessed return value of the fetch
     */
    protected processData(
        raw: {data: Record<string, unknown>, exercises: [string, string][]}
    ): void {
        this.parseExercises(raw.exercises, Object.keys(raw.data));

        // transform data into array of records for easier binning
        this.data = Object.keys(raw.data).map(k => ({
            "ex_id": k,
            // sort so median is calculated correctly
            "counts": raw.data[k].map(x => parseInt(x)).sort((a: number, b: number) => a-b),
            "freq": [],
            "median": 0,
            "average": 0
        })) as {
            "ex_id": string;
            "counts": number[];
            "freq": d3.Bin<number, number>[];
            "median": number;
            "average": number;
        }[];

        // largest y-value
        this.maxCount = d3.max(this.data, d => d3.max(d.counts));


        // bin each exercise per frequency
        this.data.forEach(ex => {
            // bin per amount of required submissions
            ex["freq"] = d3.bin().thresholds(d3.range(1, this.maxCount+1))
                .domain([1, this.maxCount])(ex.counts);

            // largest x-value
            this.maxFreq = Math.max(this.maxFreq, d3.max(ex["freq"], bin => bin.length));

            ex.median = d3.quantile(ex.counts, .5);
            ex.average = d3.mean(ex.counts);
        });

        this.draw();
    }

    /**
     * Function when mouse is moved over the svg
     * moves the tooltip line and sets the tooltip labels
     * @param {unknown} e  event parameter, not used
     * @param {d3.Selection} graph The graph selection group
     */
    private svgMouseMove(
        e: unknown, graph: d3.Selection<SVGGElement, unknown, HTMLElement, unknown>
    ): void {
        const pos = this.x.invert(d3.pointer(e, graph.node())[0]);
        const i = Math.round(pos);
        if (i !== this.tooltipIndex && i > 0 && this.x(i) <= this.innerWidth) {
            this.tooltipIndex = i;
            this.tooltipLine
                .attr("opacity", 1)
                .transition()
                .duration(100)
                .attr("x1", this.x(i))
                .attr("x2", this.x(i));
            // check if label doesn't go out of bounds
            const labelMsg = `${i} ${I18n.t(i === 1 ? "js.submission" : "js.submissions")}`;
            const switchSides = this.x(i) +
                this.fontSize/2*labelMsg.length +
                5 > this.innerWidth;
            this.tooltipLabel
                .attr("opacity", 1)
                .text(labelMsg)
                .attr("text-anchor", switchSides ? "end" : "start")
                .transition()
                .duration(100)
                .attr("x", switchSides ? this.x(i) - 10 : this.x(i) + 10);
            this.tooltipDots
                .attr("opacity", 1)
                .transition()
                .duration(100)
                .attr("cx", this.x(i));
            this.tooltipDotLabels
                .attr("opacity", 1)
                .text(d => {
                    const freq = d["freq"][Math.max(0, i-1)].length;
                    // check if plural is needed
                    return `${freq} ${I18n.t(freq === 1 ? "js.user" : "js.users")}`;
                })
                .attr("text-anchor", switchSides ? "end" : "start")
                .transition()
                .duration(100)
                .attr("x", switchSides ? this.x(i) - 5 : this.x(i)+5);
        }
    }

    /**
     * Function when mouse is moved out of the svg
     * makes everything involving the tooltip disappear
     */
    private svgMouseOut(): void {
        this.tooltipIndex = -1;
        this.tooltipLine
            .attr("opacity", 0);
        this.tooltipLabel
            .attr("opacity", 0);
        this.tooltipDots
            .attr("opacity", 0);
        this.tooltipDotLabels
            .attr("opacity", 0);
    }
}
