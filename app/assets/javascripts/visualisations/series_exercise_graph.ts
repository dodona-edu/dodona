import * as d3 from "d3";
import { SeriesGraph } from "./series_graph";

export abstract class SeriesExerciseGraph extends SeriesGraph {
    protected readonly yAxisPadding = 5;
    protected y: d3.ScaleBand<string>;
    protected yAxis: d3.Selection<SVGGElement, unknown, HTMLElement, unknown>;

    protected readonly statusOrder = [
        "correct", "wrong", "compilation error", "runtime error",
        "time limit exceeded", "memory limit exceeded", "output limit exceeded",
    ];

    protected override draw(animation=true): void {
        this.height = 60 * this.exOrder.length + this.margin.top + this.margin.bottom;
        super.draw(animation);

        // y-scale for exercises
        this.y = d3.scaleBand()
            .range([0, this.innerHeight])
            .domain(this.exOrder)
            .padding(.5);

        // y-axis with exercise names
        this.yAxis = this.graph.append("g")
            .call(d3.axisLeft(this.y).tickSize(0))
            .attr("transform", `translate(-${this.yAxisPadding}, 0)`);
        this.yAxis
            .select(".domain").remove();
        this.yAxis
            .selectAll(".tick text")
            .call(this.formatTitle, this.margin.left - this.yAxisPadding, this.exMap);
    }
}
