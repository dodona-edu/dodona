// eslint-disable-next-line
// @ts-nocheck

import * as d3 from "d3";
import { RawData } from "./series_graph";
import { SeriesExerciseGraph } from "./series_exercise_graph";

export class ViolinGraph extends SeriesExerciseGraph {
    protected readonly baseUrl = "/stats/violin?series_id=";

    // scales
    private x: d3.ScaleLinear<number, number>;

    // tooltips things
    private tooltipIndex = -1; // used to prevent unnecessary tooltip updates
    private tooltipLine: d3.Selection<SVGLineElement, unknown, HTMLElement, any>;
    private tooltipLabel: d3.Selection<SVGTextElement, unknown, HTMLElement, any>;
    private tooltipLabels: d3.Selection<
        Element | SVGTextElement | d3.EnterElement | Document | Window | null,
        unknown,
        SVGGElement,
        any
    >;

    // data
    private data: {
        "ex_id": string, "counts": number[],
        "freq": d3.Bin<number, number>[], "average": number
    }[];
    private maxFreq = 0; // largest y-value
    private readonly maxSubmissions = 20;

    /**
    * Draws the graph's svg (and other) elements on the screen
    * No more data manipulation is done in this function
    * @param {Boolean} animation Whether to play animations (disabled on a resize redraw)
    */
    protected override draw(animation=true): void {
        super.draw(animation);

        // Y scale per exercise
        const yBin = d3.scaleLinear()
            .domain([0, this.maxFreq])
            .range([0, this.y.bandwidth()]);

        const color = d3.scaleOrdinal()
            .range(d3.schemeDark2)
            .domain(this.exOrder);

        // X scale and axis
        this.x = d3.scaleLinear()
            .domain([0, this.maxSubmissions])
            .range([5, this.innerWidth]);
        this.graph.append("g")
            .attr("transform", `translate(0, ${this.innerHeight})`)
            .call(d3.axisBottom(this.x).tickFormat(t => t === this.maxSubmissions ? `${t}+` : t))
            .select(".domain").remove();
        this.graph.append("text")
            .attr("text-anchor", "middle")
            .attr("x", this.innerWidth / 2)
            .attr("y", this.innerHeight + 30)
            .text(I18n.t("js.n_submissions"))
            .attr("class", "violin-label")
            .attr("fill", "currentColor");

        // Violins
        this.graph
            .selectAll(".violin-path")
            .data(this.data)
            .join("g")
            .attr("transform", d => `translate(0, ${this.y(d.ex_id) + this.y.bandwidth() / 2})`)
            .attr("pointer-events", "none")
            .append("path")
            .attr("fill", d => color(d.ex_id))
            .datum(ex => {
                return ex.freq;
            })
            .attr("class", "violin-path")
            .attr("d", d3.area()
                .x((_, i) => this.x(i))
                .y0(0)
                .y1(0)
                .curve(d3.curveMonotoneX)
            )
            .transition().duration(animation ? 500 : 0)
            .attr("d", d3.area()
                .x((_, i) => this.x(i))
                .y0(d => -yBin(d.length))
                .y1(d => yBin(d.length))
                .curve(d3.curveMonotoneX)
            );

        // Average dots
        const dots = this.graph
            .selectAll("avgDot")
            .data(this.data.filter(d => d.average <= 20))
            .join("circle")
            .attr("class", "avgIcon")
            .style("opacity", 0)
            .attr("cy", d => this.y(d.ex_id) + this.y.bandwidth() / 2)
            .attr("cx", d => this.x(d.average))
            .attr("r", 4)
            .attr("fill", "currentColor");
        dots.transition()
            .duration(animation ? 500 : 0)
            .style("opacity", 1);
        dots.append("title")
            .text(`${I18n.t("js.mean")} ${I18n.t("js.attempts")}`);

        // average > 20 -> arrows instead of dots
        // const arrows = this.graph
        //     .selectAll("avgArrow")
        //     .data(this.data.filter(d => d.average > 20))
        //     .join("path")
        //     .style("opacity", 0)
        //     .attr("d", d3.symbol().type(d3.symbolTriangle))
        //     .attr("fill", "currentColor")
        //     .attr("transform", d => `translate(${this.x(20)}, ${this.y(d.ex_id) + this.y.bandwidth()/2}) rotate(90)`);

        const customArrow = (size: number): string => {
            return `M -${size/2} -${size} c ${size} ${size + size / 4}, ${size} ${size - size/4}, 0 ${2 * size}`;
        };

        const arrows = this.graph.selectAll("avgArrow")
            .data(this.data.filter(d => d.average > 20))
            .join("path")
            .attr("d", customArrow(8))
            .style("opacity", 0)
            .attr("fill", "transparent")
            .attr("stroke", "currentColor")
            .attr("stroke-width", 4)
            .attr("transform", d => `translate(${this.x(20)}, ${this.y(d.ex_id) + this.y.bandwidth()/2})`)


        arrows.transition()
            .duration(animation ? 500 : 0)
            .style("opacity", 1);
        arrows.append("title")
            .text(`${I18n.t("js.mean")} ${I18n.t("js.attempts")}`);

        // Additional metrics
        const metrics = this.graph.append("g")
            .attr("transform", `translate(${this.innerWidth + 15}, 0)`);
        for (const ex of this.data) {
            metrics.append("text")
                .attr("x", (this.margin.right - 20) / 2)
                .attr("y", this.y(ex.ex_id) + this.y.bandwidth() / 2)
                .text(d3.format(".1f")(ex.average))
                .attr("text-anchor", "middle")
                .attr("dominant-baseline", "central")
                .attr("fill", "currentColor")
                .style("font-size", "18px");
        }
        metrics.append("text")
            .attr("x", (this.margin.right - 20) / 2)
            .attr("y", 10)
            .text(`${I18n.t("js.mean")} ${I18n.t("js.attempts")}`)
            .attr("text-anchor", "middle")
            .attr("fill", "currentColor")
            .style("font-size", `${this.fontSize}px`);

        // Initialize tooltip
        this.tooltipLine = this.graph.append("line")
            .attr("y1", 0)
            .attr("y2", this.innerHeight)
            .attr("opacity", 0)
            .attr("stroke", "currentColor")
            .attr("pointer-events", "none");
        this.tooltipLabel = this.graph.append("text")
            .attr("y", 12)
            .attr("opacity", 0)
            .attr("text-anchor", "start")
            .attr("fill", "currentColor")
            .attr("font-size", `${this.fontSize}px`)
            .attr("font-weight", "bold")
            .attr("class", "d3-tooltip-label");
        this.tooltipLabels = this.graph.selectAll("ttlabels")
            .data(this.data, d => d["ex_id"])
            .join("text")
            .attr("text-anchor", "end")
            .attr("fill", "currentColor")
            .attr("transform", d => `translate(0, ${this.y(d.ex_id) + this.y.bandwidth() / 2})`)
            .attr("y", 4)
            .attr("opacity", 0)
            .attr("font-size", `${this.fontSize}px`)
            .attr("class", "d3-tooltip-label");

        this.svg
            .on("mousemove", e => this.svgMouseMove(e, this.graph))
            .on("mouseout", () => this.svgMouseOut());
    }

    /**
     * Transforms the data from the server into a form usable by the graph.
     *
     * @param {RawData} raw The unprocessed return value of the fetch
     */
    protected override processData({ data, exercises }: RawData): void {
        this.parseExercises(exercises, data.map(ex => ex.ex_id));
        this.insertFakeData(data);
        // transform data into array of records for easier binning
        // eslint-disable-next-line camelcase
        this.data = data.map(({ ex_id, ex_data }) => ({
            "ex_id": String(ex_id),
            // sort so median is calculated correctly
            "counts": ex_data.sort((a: number, b: number) => a - b),
            "freq": [],
            "average": 0
        })) as {
            "ex_id": string;
            "counts": number[];
            "freq": d3.Bin<number, number>[];
            "average": number;
            }[];

        // bin each exercise per frequency
        this.data.forEach(ex => {
            // bin per amount of required submissions
            ex.freq = d3.bin()
                .thresholds(d3.range(0, this.maxSubmissions + 1))
                .domain([0, 1000])(ex.counts); // explicitly set domain to force empty bins

            // largest x-value
            this.maxFreq = Math.max(this.maxFreq, d3.max(ex.freq, bin => bin.length));

            ex.average = d3.mean(ex.counts);
        });
    }

    /**
     * Function when mouse is moved over the svg
     * moves the tooltip line and sets the tooltip labels
     * @param {unknown} e  event parameter
     * @param {d3.Selection} graph The graph selection group
     */
    private svgMouseMove(
        e: unknown, graph: d3.Selection<SVGGElement, unknown, HTMLElement, unknown>
    ): void {
        const pos = this.x.invert(d3.pointer(e, graph.node())[0]);
        const i = Math.round(pos);
        if (i !== this.tooltipIndex && i >= 0 && this.x(i) <= this.innerWidth) {
            this.tooltipIndex = i;
            this.tooltipLine
                .attr("opacity", 1)
                .transition()
                .duration(100)
                .attr("x1", this.x(i))
                .attr("x2", this.x(i));
            // check if label doesn't go out of bounds
            const labelMsg = `${i === this.maxSubmissions ? this.maxSubmissions + "+" : i} ${I18n.t(i === 1 ? "js.submission" : "js.submissions")}`;
            const switchSides = this.x(i) +
                this.fontSize / 2 * labelMsg.length +
                5 > this.innerWidth;
            this.tooltipLabel
                .attr("opacity", 1)
                .text(labelMsg)
                .attr("text-anchor", switchSides ? "end" : "start")
                .transition()
                .duration(100)
                .attr("x", switchSides ? this.x(i) - 7 : this.x(i) + 7);
            this.tooltipLabels
                .attr("opacity", 1)
                .text(d => {
                    const freq = d["freq"][Math.max(0, i)].length;
                    // check if plural is needed
                    return `${freq} ${I18n.t(freq === 1 ? "js.user" : "js.users")}`;
                })
                .attr("text-anchor", switchSides ? "end" : "start")
                .transition()
                .duration(100)
                .attr("x", switchSides ? this.x(i) - 7 : this.x(i) + 7);
        }
    }

    /**
     * Hides tooltip on mouse out
     */
    private svgMouseOut(): void {
        this.tooltipIndex = -1;
        this.tooltipLine.attr("opacity", 0);
        this.tooltipLabel.attr("opacity", 0);
        this.tooltipLabels.attr("opacity", 0);
    }

    private insertFakeData(data): void {
        data.forEach(ex => {
            const students = 20 + parseInt(Math.random() * 50);
            let i = 0;
            const exData = [];
            while (i < students) {
                exData.push(parseInt(5 + Math.random()*30));
                i++;
            }
            ex.ex_data = exData;
        });
    }
}
