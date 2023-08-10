// eslint-disable-next-line
// @ts-nocheck
import * as d3 from "d3";
import { RawData } from "./series_graph";
import { SeriesExerciseGraph } from "./series_exercise_graph";
import { themeState } from "state/Theme";

export class StackedStatusGraph extends SeriesExerciseGraph {
    protected readonly baseUrl = "/stats/stacked_status?series_id=";

    // data
    private data: { "exercise_id": string; "status": string; "cSum": number; "count": number }[];
    private maxSum: Record<string, number>; // total number of submissions per exercise

    /**
    * Draws the graph's svg (and other) elements on the screen
    * No more data manipulation is done in this function
    * @param {Boolean} animation Whether to play animations (disabled on a resize redraw)
    */
    protected override draw(animation=true): void {
        super.draw(animation);

        const emptyColor = themeState.getCSSVariable("--d-off-surface");

        // X scale
        const x = d3.scaleLinear()
            .domain([0, 1])
            .range([0, this.innerWidth]);

        // Color scale
        const color = d3.scaleOrdinal()
            .range(d3.schemeDark2)
            .domain(this.statusOrder);

        // Tooltip
        const tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);

        // Legend
        const legend = this.container
            .append("div")
            .attr("class", "legend")
            .style("margin-top", "-20px")
            .selectAll("div")
            .data(this.statusOrder)
            .enter()
            .append("div")
            .attr("class", "legend-item");
        legend
            .append("div")
            .attr("class", "legend-box")
            .style("background", status => color(status) as string);
        legend
            .append("span")
            .attr("class", "legend-text")
            .text(status => I18n.t(`js.status.${status.replaceAll(" ", "_")}`))
            .style("color", "currentColor")
            .style("font-size", `${this.fontSize}px`);

        // Bars
        this.graph.selectAll(".bar")
            .data(this.data)
            .join("rect")
            .attr("class", "bar")
            .attr("x", 0)
            .attr("width", 0)
            .attr("y", d => this.y(d.exercise_id))
            .attr("height", this.y.bandwidth())
            .attr("fill", emptyColor)
            .on("mouseover", (e, d) => {
                tooltip.transition()
                    .duration(200)
                    .style("opacity", .9);
                tooltip.html(`<b>${I18n.t(`js.status.${d.status.replaceAll(" ", "_")}`)}</b><br> ${d3.format(".1%")((d.count) / this.maxSum[d.exercise_id])} (${d.count}/${this.maxSum[d.exercise_id]})`);
            })
            .on("mousemove", e => {
                tooltip
                    .style("left", `${d3.pointer(e, this.svg.node())[0] + 15}px`)
                    .style("top", `${d3.pointer(e, this.svg.node())[1]}px`);
            })
            .on("mouseout", () => {
                tooltip.transition()
                    .duration(500)
                    .style("opacity", 0);
            })
            .transition().duration(animation ? 500 : 0)
            .attr("x", d => x((d.cSum) / this.maxSum[d.exercise_id])) // relative numbers
            .attr("width", d => x(d.count / this.maxSum[d.exercise_id])) // relative numbers
            .attr("fill", d => color(d.status) as string);

        // Gridlines
        const gridlines = this.graph
            .append("g")
            .attr("transform", `translate(0, ${this.y.bandwidth() / 2})`)
            .call(
                d3.axisBottom(x)
                    .tickValues([.2, .4, .6, .8])
                    .tickFormat(d3.format(".0%"))
                    .tickSize(this.innerHeight - this.y.bandwidth()).tickSizeOuter(0)
            );
        gridlines.select(".domain").remove();
        gridlines.selectAll("line").style("stroke-dasharray", ("3, 3"));

        // Metrics
        const metrics = this.graph.append("g")
            .attr("transform", `translate(${this.innerWidth + 10}, 0)`);
        for (const [ex, sum] of Object.entries(this.maxSum)) {
            metrics.append("text")
                .attr("x", (this.margin.right - 20) / 2)
                .attr("y", this.y(ex) + this.y.bandwidth() / 2)
                .text(sum)
                .attr("text-anchor", "middle")
                .attr("dominant-baseline", "central")
                .attr("fill", "currentColor")
                .style("font-size", "18px");
        }
        metrics.append("text")
            .attr("x", (this.margin.right - 20) / 2)
            .attr("y", 10)
            .text(`${I18n.t("js.total")} ${I18n.t("js.submissions")}`)
            .attr("text-anchor", "middle")
            .attr("fill", "currentColor")
            .style("font-size", `${this.fontSize}px`);
    }

    /**
     * Transforms the data from the server into a form usable by the graph.
     *
     * @param {RawData} raw The unprocessed return value of the fetch
     */
    protected override processData({ data, exercises }: RawData): void {
        this.parseExercises(exercises, data.map(ex => ex.ex_id));

        this.maxSum = {};
        this.data = [];
        // turn data into array of records (one for each ex_id/status combination)
        // eslint-disable-next-line camelcase
        data.forEach(({ ex_id, ex_data }) => {
            let sum = 0;
            this.statusOrder.forEach(s => {
                // check if status is present in the data
                // eslint-disable-next-line camelcase
                const c = ex_data[s] ?? 0;
                this.data.push({
                    "exercise_id": String(ex_id), "status": s, "cSum": sum, "count": c
                });
                sum += c;
            });
            // eslint-disable-next-line camelcase
            this.maxSum[ex_id] = sum;
        });
    }
}
