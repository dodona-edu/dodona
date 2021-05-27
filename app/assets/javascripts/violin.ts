import * as d3 from "d3";
import { formatTitle } from "graph_helper.js";


let selector = undefined;
const margin = { top: 20, right: 160, bottom: 40, left: 125 };
let width = 0;
let height = 0;

function drawViolin(data: {
    "ex_id": string;
    "counts": number[];
    "freq": number[][];
    "median": number;
    "average": number;
}[], exercises: [string, string][]): void {
    const min = d3.min(data, d => d3.min(d.counts));
    const max = d3.max(data, d => d3.max(d.counts));
    const xTicks = 10;

    // extract id's and reverse order (since graphs are built bottom up)
    const exOrder: string[] = exercises.map(ex => ex[0]).reverse();

    // convert exercises into object to map id's to exercise names
    const exMap = exercises.reduce((map, [id, name]) => ({ ...map, [id]: name }), {});

    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;
    const yAxisPadding = 5; // padding between y axis (labels) and the actual graph

    const maxFreq = d3.max(data, d => d3.max(
        d.freq, (bin: number[]) => bin.length
    ));

    const svg = d3.select(selector)
        .append("svg")
        .attr("width", width)
        .attr("height", height);
    const graph = svg
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    // Show the Y scale for the exercises (Big Y scale)
    const y = d3.scaleBand()
        .range([innerHeight, 0])
        .domain(exOrder)
        .padding(.5);

    const yAxis = graph.append("g")
        .call(d3.axisLeft(y).tickSize(0))
        .attr("transform", `translate(-${yAxisPadding}, 0)`);
    yAxis
        .select(".domain").remove();
    yAxis
        .selectAll(".tick text")
        .call(formatTitle, margin.left-yAxisPadding, exMap, 5);

    // y scale per exercise
    const yBin = d3.scaleLinear()
        .domain([0, maxFreq])
        .range([0, y.bandwidth()]);

    // Show the X scale
    const x = d3.scaleLinear()
        .domain([min, max])
        .range([5, innerWidth]);
    graph.append("g")
        .attr("transform", "translate(0," + innerHeight + ")")
        .call(d3.axisBottom(x).ticks(xTicks))
        .select(".domain").remove();

    // Add X axis label:
    graph.append("text")
        .attr("text-anchor", "end")
        .attr("x", -5)
        .attr("y", innerHeight+5)
        .text(I18n.t("js.n_submissions"))
        .attr("class", "violin-label")
        .attr("fill", "currentColor");

    let tooltipI = -1;

    // add the areas
    graph
        .selectAll("violins")
        .data(data)
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
            .x((_, i) => x(i+1))
            .y0(0)
            .y1(0)
            .curve(d3.curveCatmullRom)
        )
        .transition().duration(500)
        .attr("d", d3.area()
            .x((_, i) => x(i+1))
            .y0(d => -yBin(d.length))
            .y1(d => yBin(d.length))
            .curve(d3.curveCatmullRom)
        );

    // median dot
    graph
        .selectAll("medianDot")
        .data(data)
        .enter()
        .append("circle")
        .style("opacity", 0)
        .attr("cy", d => y(d.ex_id) + y.bandwidth() / 2)
        .attr("cx", d => x(d.median))
        .attr("r", 4)
        .attr("fill", "currentColor")
        .attr("pointer-events", "none")
        .transition().duration(500)
        .style("opacity", 1);

    // Additional metrics
    const metrics = graph.append("g")
        .attr("transform", `translate(${innerWidth+15}, 0)`);

    metrics.append("rect")
        .attr("width", margin.right - 20)
        .attr("height", innerHeight)
        .attr("class", "metric-container")
        .attr("rx", 5)
        .attr("ry", 5)
        .style("fill", "none")
        .style("stroke-width", 2);

    for (const ex of data) {
        const t = Math.round(ex.average*100)/100;
        metrics.append("text")
            .attr("x", (margin.right - 20) / 2)
            .attr("y", y(ex.ex_id) + y.bandwidth()/2)
            .text(`${t}`)
            .attr("text-anchor", "middle")
            .attr("fill", "currentColor")
            .style("font-size", "14px");

        metrics.append("text")
            .attr("x", (margin.right - 20) / 2)
            .attr("y", y(ex.ex_id) + y.bandwidth())
            .text(
                `${I18n.t("js.mean")} ${I18n.t("js.submissions")}`
            )
            .attr("text-anchor", "middle")
            .attr("fill", "currentColor")
            .style("font-size", "12px");
    }

    // initialize tooltip
    const tooltip = graph.append("line")
        .attr("y1", 0)
        .attr("y2", innerHeight)
        .attr("pointer-events", "none")
        .attr("opacity", 0)
        .attr("stroke", "currentColor")
        .style("width", 40);
    const tooltipLabel = graph.append("text")
        .attr("opacity", 0)
        .text("_") // dummy text to calculate height
        .attr("text-anchor", "start")
        .attr("fill", "currentColor")
        .attr("font-size", "12px")
        .attr("class", "d3-tooltip-label");
    tooltipLabel
        .attr("y", innerHeight - 10);
    const tooltipDots = graph.selectAll("dots")
        .data(data, d => d.ex_id)
        .join("circle")
        .attr("r", 4)
        .attr("transform", d => `translate(0, ${y(d.ex_id) + y.bandwidth() / 2})`)
        .attr("opacity", 0)
        .style("fill", "currentColor");
    const tooltipDotLabels = graph.selectAll("dotlabels")
        .data(data, d => d.ex_id)
        .join("text")
        .attr("text-anchor", "end")
        .attr("fill", "currentColor")
        .attr("transform", d => `translate(0, ${y(d.ex_id) + y.bandwidth() / 2})`)
        .attr("y", -5)
        .attr("opacity", 0)
        .attr("font-size", "12px")
        .attr("class", "d3-tooltip-label");

    function onMouseOver(e): void {
        const pos = x.invert(d3.pointer(e, graph.node())[0]);
        const i = Math.round(pos);
        if (i !== tooltipI && x(i) <= innerWidth) {
            tooltipI = i;
            tooltip
                .attr("opacity", 1)
                .attr("x1", x(i))
                .attr("x2", x(i));
            const switchSides = x(i) + tooltipLabel.node().getBBox().width + 5 > innerWidth;
            tooltipLabel
                .attr("opacity", 1)
                .text(`${i} ${I18n.t(i === 1 ? "js.submission" : "js.submissions")}`)
                .attr("text-anchor", switchSides ? "end" : "start")
                .attr("x", switchSides ? x(i) - 10 : x(i) + 10);
            tooltipDots
                .attr("opacity", 1)
                .attr("cx", x(i));
            tooltipDotLabels
                .attr("opacity", 1)
                .text(d => {
                    const freq = d.freq[Math.max(0, i-1)].length;
                    return `${freq} ${I18n.t(freq === 1 ? "js.user" : "js.users")}`;
                })
                .attr("text-anchor", switchSides ? "end" : "start")
                .attr("x", switchSides ? x(i) - 5 : x(i)+5);
        }
    }

    function onMouseOut(): void {
        tooltipI = -1;
        tooltip
            .attr("opacity", 0);
        tooltipLabel
            .attr("opacity", 0);
        tooltipDots
            .attr("opacity", 0);
        tooltipDotLabels
            .attr("opacity", 0);
    }

    svg.on("mousemove", e => onMouseOver(e)).on("mouseout", onMouseOut);
}

function initViolin(url: string, containerId: string, containerHeight: number): void {
    height = containerHeight;
    selector = containerId;
    const container = d3.select(selector);

    if (!height) {
        height = container.node().getBoundingClientRect().height - 5;
    }
    container
        .html("") // clean up possible previous visualisations
        .style("height", `${height}px`)
        .style("display", "flex")
        .style("align-items", "center")
        .append("div")
        .text(I18n.t("js.loading"))
        .style("margin", "auto");

    width = (container.node() as Element).getBoundingClientRect().width;
    const processor = function (raw): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }
        d3.select(`${selector} *`).remove();

        if (Object.keys(raw.data).length === 0) {
            container
                .style("height", "50px")
                .append("div")
                .text(I18n.t("js.no_data"))
                .style("margin", "auto");
            return;
        }

        height = 75 * Object.keys(raw.data).length;
        container.style("height", `${height}px`);

        // transform data into array of records for easier binning
        const data = Object.keys(raw.data).map(k => ({
            "ex_id": k,
            // sort so median is calculated correctly
            "counts": raw.data[k].map(x => parseInt(x)).sort((a: number, b: number) => a-b),
            "freq": {},
            "median": 0,
            "average": 0
        })) as {
            "ex_id": string;
            "counts": number[];
            "freq": number[][];
            "median": number;
            "average": number;
        }[];

        const maxCount: number = d3.max(data, d => d3.max(d.counts));


        // bin each exercise per frequency
        data.forEach(ex => {
            ex["freq"] = d3.bin().thresholds(d3.range(1, maxCount+1))
                .domain([1, maxCount])(ex.counts);

            ex.median = d3.quantile(ex.counts, .5);
            ex.average = d3.mean(ex.counts);
        });

        drawViolin(data, raw.exercises);
    };
    d3.json(url).then(processor);
}


export { initViolin };
