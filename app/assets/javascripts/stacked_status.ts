import * as d3 from "d3";
import { formatTitle } from "graph_helper.js";

export class StackedStatusGraph {
    private selector = ""
    private container: d3.Selection<HTMLDivElement, unknown, HTMLElement, unknown>; // parent div

    private readonly margin = { top: 20, right: 150, bottom: 40, left: 105 };
    private width = 0;
    private height = 0;

    private readonly statusOrder = [
        "correct", "wrong", "compilation error", "runtime error",
        "time limit exceeded", "memory limit exceeded", "output limit exceeded",
    ];

    // data
    private exOrder: string[];
    private exMap: Record<string, string>;
    private data: { "exercise_id": string; "status": string; "cSum": number; "count": number }[];
    private maxSum: Record<string, number> // total number of submissions per exercise

    // draws the graph's svg (and other) elements on the screen
    // No more data manipulation is done in this function
    draw(): void {
        const darkMode = window.dodona.darkMode;
        const emptyColor = darkMode ? "#37474F" : "white";
        const innerWidth = this.width - this.margin.left - this.margin.right;
        const innerHeight = this.height - this.margin.top - this.margin.bottom;

        const yAxisPadding = 5; // padding between y axis (labels) and the actual graph


        const svg = this.container
            .append("svg")
            .style("height", `${this.height}px`)
            .attr("width", this.width)
            .attr("height", this.height);
        const graph = svg
            .append("g")
            .attr("transform",
                "translate(" + this.margin.left + "," + this.margin.top + ")");

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
            .call(formatTitle, this.margin.left-yAxisPadding, this.exMap);


        // Show the X scale
        const x = d3.scaleLinear()
            .domain([0, 1])
            .range([0, innerWidth]);


        // Color scale
        const color = d3.scaleOrdinal()
            .range(d3.schemeDark2)
            .domain(this.statusOrder);

        const tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);

        const legend = graph.append("g")
            .attr("transform", `translate(${-this.margin.left/2}, ${innerHeight + 20})`);

        let legendX = 0;
        for (const status of this.statusOrder) {
            // add legend colors dots
            const group = legend.append("g");

            group
                .append("rect")
                .attr("x", legendX)
                .attr("y", 0)
                .attr("width", 15)
                .attr("height", 15)
                .attr("fill", color(status) as string);

            // add legend text
            group
                .append("text")
                .attr("x", legendX + 20)
                .attr("y", 12)
                .attr("text-anchor", "start")
                .text(status)
                .attr("fill", "currentColor")
                .style("font-size", "12px");

            legendX += group.node().getBBox().width + 20;
        }

        // add bars
        graph.selectAll("bars")
            .data(this.data)
            .enter()
            .append("rect")
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
                    Math.round((d.count) / this.maxSum[d.exercise_id] * 10000) / 100
                }% (${d.count}/${this.maxSum[d.exercise_id]})`);
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
            .attr("x", d => x((d.cSum) / this.maxSum[d.exercise_id]))
            .attr("width", d => x(d.count / this.maxSum[d.exercise_id]))
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

        const metrics = graph.append("g")
            .attr("transform", `translate(${innerWidth+10}, 0)`);

        // add bars
        metrics.append("rect")
            .attr("width", this.margin.right - 20)
            .attr("height", innerHeight)
            .attr("class", "metric-container")
            .attr("rx", 5)
            .attr("ry", 5)
            .style("fill", "none")
            .style("stroke-width", 2);

        // add additional metrics (total submissions)
        for (const ex of this.data) {
            const t = this.maxSum[ex.exercise_id];
            metrics.append("text")
                .attr("x", (this.margin.right - 20) / 2)
                .attr("y", y(ex.exercise_id) + y.bandwidth()/2)
                .text(`${t}`)
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
                .style("font-size", "12px");
        }
    }

    // Displays an error message when there is not enough data
    drawNoData(): void {
        d3.select(this.selector)
            .style("height", "50px")
            .append("div")
            .text(I18n.t("js.no_data"))
            .style("margin", "auto");
    }

    // transforms the data into a form usable by the graph +
    // calculates addinional data
    // finishes by calling draw
    // can be called recursively when a 'data not yet available' response is received
    prepareData(raw: Record<string, unknown>, url: string): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then((r: Record<string, unknown>) => {
                this.prepareData(r, url);
            }), 1000);
            return;
        }
        d3.select(`${this.selector} *`).remove();

        const data = raw.data as Record<string, Record<string, number>>;
        if (Object.keys(data).length === 0) {
            this.drawNoData();
        }

        // extract id's and reverse order (since graphs are built bottom up)
        this.exOrder = (raw.exercises as [string, string][]).map(ex => ex[0]).reverse();

        // convert exercises into object to map id's to exercise names
        this.exMap = (raw.exercises as [string, string][])
            .reduce((map, [id, name]) => ({ ...map, [id]: name }), {});

        this.height = 75 * Object.keys(data).length;

        this.maxSum = {};
        this.data = [];
        // turn data into array of records
        Object.entries(data).forEach(([k, v]: [string, Record<string, number>]) => {
            let sum = 0;
            this.statusOrder.forEach(s => {
                const c = v[s] ? v[s] : 0;
                this.data.push({ "exercise_id": k, "status": s, "cSum": sum, "count": c });
                sum += c;
            });
            this.maxSum[k] = sum;
        });

        this.draw();
    }

    init(url: string, containerId: string, containerHeight: number): void {
        this.height = containerHeight;
        this.selector = containerId;
        this.container = d3.select(this.selector);

        if (!this.height) {
            this.height = (this.container.node() as HTMLElement).getBoundingClientRect().height - 5;
        }
        this.container
            .html("") // clean up possible previous visualisations
            .style("height", `${this.height}px`)
            .style("display", "flex")
            .style("align-items", "center")
            .append("div")
            .text(I18n.t("js.loading"))
            .style("margin", "auto");

        this.width = (this.container.node() as Element).getBoundingClientRect().width;

        d3.json(url).then(r => {
            this.prepareData(r as Record<string, unknown>, url);
        });
    }
}
