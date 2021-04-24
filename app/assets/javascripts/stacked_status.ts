import * as d3 from "d3";
import { formatTitle } from "graph_helper.js";

let selector = "#stacked_status-container";
const margin = { top: 20, right: 10, bottom: 20, left: 105 };
let width = 0;
let height = 0;
const statusOrder = [
    "correct", "wrong", "compilation error", "runtime error",
    "time limit exceeded", "memory limit exceeded", "output limit exceeded",
];

function drawStacked(data, maxSum, exMap): void {
    const yDomain: string[] = Array.from(new Set(data.map(d => d.exercise_id)));
    // height = 100 * yDomain.length;
    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;
    const yAxisPadding = 5; // padding between y axis (labels) and the actual graph

    const container = d3.select(selector);


    const graph = container
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    // Show the Y scale
    const y = d3.scaleBand()
        .range([innerHeight, 0])
        .domain(yDomain)
        .padding(.5);

    const yAxis = graph.append("g")
        .call(d3.axisLeft(y).tickSize(0))
        .attr("transform", `translate(-${yAxisPadding}, 0)`);
    yAxis
        .select(".domain").remove();
    yAxis
        .selectAll(".tick text")
        .call(formatTitle, margin.left-yAxisPadding, exMap);


    // Show the X scale
    const x = d3.scaleLinear()
        .domain([0, 1])
        .range([0, innerWidth]);


    // Color scale
    const color = d3.scaleOrdinal()
        .range(d3.schemeDark2)
        .domain(statusOrder);

    const tooltip = d3.select(selector).append("div")
        .attr("class", "d3-tooltip")
        .attr("pointer-events", "none")
        .style("opacity", 0)
        .style("z-index", 5);

    // add bars
    graph.selectAll("bars")
        .data(data)
        .enter()
        .append("rect")
        .attr("x", d => x((d.cum_sum - d.count) / maxSum[d.exercise_id]))
        .attr("width", d => x(d.count / maxSum[d.exercise_id]))
        .attr("y", d => y(d.exercise_id))
        .attr("height", y.bandwidth())
        .attr("fill", d => color(d.status))
        .on("mouseover", (e, d) => {
            tooltip.transition()
                .duration(200)
                .style("opacity", .9);
            tooltip.html(`Status: ${d.status}`);
        })
        .on("mousemove", (e, _) => {
            tooltip
                .style("left", `${d3.pointer(e)[0] - 20}px`)
                .style("top", `${d3.pointer(e)[1] - 40}px`);
        })
        .on("mouseout", () => {
            tooltip.transition()
                .duration(500)
                .style("opacity", 0);
        });


    const gridlines = graph.append("g")
        .call(d3.axisBottom(x).tickValues([.2, .4, .6, .8]).tickFormat(() => "")
            .tickSize(innerHeight).tickSizeOuter(0));
    gridlines
        .select(".domain").remove();
    console.log(gridlines);
    gridlines.selectAll("line").style("stroke-dasharray", ("3, 3"));
}

function initStacked(url, containerId: string, containerHeight: number): void {
    height = containerHeight;
    selector = containerId;
    const container = d3.select(selector);

    if (!height) {
        height = container.node().clientHeight - 5;
    }
    container.html(""); // clean up possible previous visualisations
    container.attr("class", "text-center").append("span").text(I18n.t("js.loading"));

    width = (container.node() as Element).getBoundingClientRect().width;
    const processor = function (raw): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }
        d3.select(`${selector} *`).remove();

        const data = raw.data;
        data.sort((a, b) => {
            if (a.exercise_id === b.exercise_id) {
                return statusOrder.indexOf(a.status) - statusOrder.indexOf(b.status);
            } else {
                return a.exercise_id - b.exercise_id;
            }
        });
        let prevId = data[0].exercise_id;
        let prevSum = 0;
        const maxSum = {};
        data.forEach(d => {
            if (prevId !== d.exercise_id) {
                maxSum[prevId] = prevSum;
                prevId = d.exercise_id;
                prevSum = 0;
            }
            prevSum += d.count;
            d["cum_sum"] = prevSum;
        });
        maxSum[prevId] = prevSum;

        drawStacked(data, maxSum, raw.exercises);
    };
    d3.json(url).then(processor);
}

export { initStacked };
