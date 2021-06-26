import * as d3 from "d3";
import { RawData, SeriesGraph } from "series_graph";

export class StackedStatusGraph extends SeriesGraph {
    protected readonly baseUrl = "/stats/stacked_status?series_id=";
    private readonly margin = { top: 20, right: 150, bottom: 40, left: 105 };
    private readonly fontSize = 12;

    private readonly statusOrder = [
        "correct", "wrong", "compilation error", "runtime error",
        "time limit exceeded", "memory limit exceeded", "output limit exceeded",
    ];

    // data
    private data: { "exercise_id": string; "status": string; "cSum": number; "count": number }[];
    private maxSum: Record<string, number> // total number of submissions per exercise

    /**
    * draws the graph's svg (and other) elements on the screen
    * No more data manipulation is done in this function
    */
    protected override draw(): void {
        this.height = 75 * this.exOrder.length;
        const innerWidth = this.width - this.margin.left - this.margin.right;
        const innerHeight = this.height - this.margin.top - this.margin.bottom;
        const darkMode = window.dodona.darkMode;
        const emptyColor = darkMode ? "#37474F" : "white";

        const yAxisPadding = 5; // padding between y axis (labels) and the actual graph

        const svg = this.container
            .append("svg")
            .style("height", `${this.height}px`)
            .attr("width", this.width)
            .attr("height", this.height);
        const graph = svg
            .append("g")
            .attr("transform",
                `translate(${this.margin.left}, ${this.margin.top})`);

        // Show the Y scale
        const y = d3.scaleBand()
            .range([innerHeight, 0])
            .domain(this.exOrder)
            .padding(.5);

        const yAxis = graph.append("g")
            .call(d3.axisLeft(y).tickSize(0))
            .attr("transform", `translate(-${yAxisPadding}, 0)`);
        yAxis
            .select(".domain").remove();
        yAxis
            .selectAll(".tick text")
            // format and break up exercise titles
            .call(this.formatTitle, this.margin.left-yAxisPadding, this.exMap);


        // Show the X scale
        const x = d3.scaleLinear()
            .domain([0, 1])
            .range([0, innerWidth]);


        // Color scale
        const color = d3.scaleOrdinal()
            .range(d3.schemeDark2)
            .domain(this.statusOrder);

        // tooltip init
        const tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);

        // calculate offset for legend elements
        const statePosition = [];
        let pos = 0;
        this.statusOrder.forEach(status => {
            statePosition.push({ status: status, pos: pos });
            // rect size (15) + 5 padding + 20 inter-group padding + text length
            pos += 40 + this.fontSize/2*status.length;
        });
        // draw legend
        const legend = svg
            .append("g")
            .attr("class", "legend")
            .attr(
                "transform",
                `translate(${this.width/2-pos/2}, ${this.height-this.margin.bottom/2})`
            )
            .selectAll("g")
            .data(statePosition)
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
            .attr("fill", s => color(s.status) as string);

        // add legend text
        legend
            .append("text")
            .attr("x", 20)
            .attr("y", 12)
            .attr("text-anchor", "start")
            .text(s => s.status)
            .attr("fill", "currentColor")
            .style("font-size", `${this.fontSize}px`);

        // add bars
        graph.selectAll(".bar")
            .data(this.data)
            .enter()
            .append("rect")
            .attr("class", "bar")
            .attr("x", 0)
            .attr("width", 0)
            .attr("y", d => y(d.exercise_id))
            .attr("height", y.bandwidth())
            .attr("fill", emptyColor)
            .on("mouseover", (e, d) => {
                tooltip.transition()
                    .duration(200)
                    .style("opacity", .9);
                tooltip.html(`${d.status}<br> ${
                    d3.format(".2%")((d.count) / this.maxSum[d.exercise_id])
                } (${d.count}/${this.maxSum[d.exercise_id]})`);
            })
            .on("mousemove", (e, _) => {
                const bbox = tooltip.node().getBoundingClientRect();
                tooltip
                    .style(
                        "left",
                        `${d3.pointer(e, svg.node())[0]-bbox.width*1.1}px`
                    )
                    .style(
                        "top",
                        `${d3.pointer(e, svg.node())[1]-bbox.height*1.25}px`
                    );
            })
            .on("mouseout", () => {
                tooltip.transition()
                    .duration(500)
                    .style("opacity", 0);
            })
            .transition().duration(500)
            .attr("x", d => x((d.cSum) / this.maxSum[d.exercise_id])) // relative numbers
            .attr("width", d => x(d.count / this.maxSum[d.exercise_id])) // relative numbers
            .transition().duration(500)
            .attr("fill", d => color(d.status) as string);

        // add gridlines
        const gridlines = graph.append("g").attr("transform", `translate(0, ${y.bandwidth()/2})`)
            .call(
                d3.axisBottom(x)
                    .tickValues([.2, .4, .6, .8])
                    .tickFormat(d3.format(".0%"))
                    .tickSize(innerHeight-y.bandwidth()).tickSizeOuter(0)
            );
        gridlines
            .select(".domain").remove();
        gridlines.selectAll("line").style("stroke-dasharray", ("3, 3"));

        // add additional metrics (total submissions)
        const metrics = graph.append("g")
            .attr("transform", `translate(${innerWidth+10}, 0)`);

        // metrics border
        metrics.append("rect")
            .attr("width", this.margin.right - 20)
            .attr("height", innerHeight)
            .attr("class", "metric-container")
            .attr("rx", 5)
            .attr("ry", 5)
            .style("fill", "none")
            .style("stroke-width", 2);

        // metrics data
        for (const ex of this.data) {
            metrics.append("text")
                .attr("x", (this.margin.right - 20) / 2)
                .attr("y", y(ex.exercise_id) + y.bandwidth()/2)
                .text(this.maxSum[ex.exercise_id])
                .attr("text-anchor", "middle")
                .attr("fill", "currentColor")
                .style("font-size", "14px");

            metrics.append("text")
                .attr("x", (this.margin.right - 20) / 2)
                .attr("y", y(ex.exercise_id) + y.bandwidth())
                .text(
                    `${I18n.t("js.total")} ${I18n.t("js.submissions")}`
                )
                .attr("text-anchor", "middle")
                .attr("fill", "currentColor")
                .style("font-size", `${this.fontSize}px`);
        }
    }

    /**
     * Transforms the data from the server into a form usable by the graph.
     *
     * @param {RawData} raw The unprocessed return value of the fetch
     */
    protected override processData({ data, exercises }: RawData): void {
        this.parseExercises(exercises, data.map(ex => ex.exId));

        this.maxSum = {};
        this.data = [];
        // turn data into array of records (one for each exId/status combination)
        data.forEach(({ exId, exData }) => {
            let sum = 0;
            this.statusOrder.forEach(s => {
                // check if status is present in the data
                const c = exData[s] ?? 0;
                this.data.push({
                    "exercise_id": String(exId), "status": s, "cSum": sum, "count": c
                });
                sum += c;
            });
            this.maxSum[exId] = sum;
        });
    }
}
