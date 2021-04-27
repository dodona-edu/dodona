import * as d3 from "d3";
import { formatTitle } from "graph_helper.js";


let selector = undefined;
const margin = { top: 20, right: 60, bottom: 40, left: 105 };
let width = 0;
let height = 0;

function drawViolin(data: {
    "ex_id": string;
    "counts": number[];
    "freq": number[][];
    "median": number;
}[], exMap: Record<string, string>): void {
    const min = d3.min(data, d => d3.min(d.counts));
    const max = d3.max(data, d => d3.max(d.counts));
    const xTicks = 10;
    const elWidth = width / max;
    const yDomain: string[] = Array.from(new Set(data.map(d => d.ex_id)));
    // height = 100 * yDomain.length;
    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;
    const yAxisPadding = 5; // padding between y axis (labels) and the actual graph

    const maxFreq = d3.max(data, d => d3.max(
        d.freq, (bin: number[]) => bin.length
    ));

    const graph = d3.select(selector)
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    // Show the Y scale for the exercises (Big Y scale)
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
        .attr("x", 20)
        .attr("y", innerHeight+margin.top+10)
        .text(I18n.t("js.n_submissions"))
        .attr("class", "violin-label")
        .attr("fill", "currentColor");

    graph
        .selectAll("violins")
        .data(data)
        .enter()
        .append("g")
        .attr("transform", d => `translate(0, ${y(d.ex_id) + y.bandwidth() / 2})`)
        .append("path")
        .datum(ex => {
            return ex.freq;
        }
        )
        .attr("class", "violin-path")
        .attr("d", d3.area()
            .x((_, i) => x(i+1))
            .y0(d => -yBin(d.length))
            .y1(d => yBin(d.length))
            .curve(d3.curveCatmullRom)
        );

    graph.selectAll("groups")
        .data(data)
        .enter()
        .append("g")
        .attr("id", d => `e${d.ex_id}`)
        .attr("transform", d => `translate(0, ${y(d.ex_id) + y.bandwidth() / 2})`);


    function onMouseOver(d): void {
        for (const ex of data) {
            const location = graph
                .append("g")
                .attr("class", "cursor");
            location
                .selectAll("cursorLine")
                .data([d])
                .enter()
                .append("line")
                .attr("x1", d => x(d))
                .attr("x2", d => x(d))
                .attr("y1", y(ex.ex_id))
                .attr("y2", y(ex.ex_id) + y.bandwidth())
                .attr("pointer-events", "none")
                .attr("stroke", "currentColor")
                .style("width", 40);
            location
                .selectAll("cursorTextTop")
                .data([d])
                .enter()
                .append("text")
                .attr("class", "label")
                .text(d => {
                    const length = ex.freq[d-1].length;
                    return `${length} ${length !== 1 ?
                        I18n.t("js.users"):
                        I18n.t("js.user")} ${I18n.t("js.with")}`;
                })
                .attr("x", d => x(d))
                .attr("y", y(ex.ex_id) - y.bandwidth() * .1)
                .attr("text-anchor", "middle")
                .attr("font-family", "sans-serif")
                .attr("pointer-events", "none")
                .attr("fill", "currentColor")
                .attr("font-size", "11px");
            location
                .selectAll("cursorTextBottom")
                .data([d])
                .enter()
                .append("text")
                .attr("class", "label")
                .text(d => `${d} ${d !== 1 ?
                    I18n.t("js.submissions") :
                    I18n.t("js.submission")
                }`)
                .attr("x", d => x(d))
                .attr("y", y(ex.ex_id) + y.bandwidth() * 1.25)
                .attr("text-anchor", "middle")
                .attr("font-family", "sans-serif")
                .attr("pointer-events", "none")
                .attr("fill", "currentColor")
                .attr("font-size", "11px");
        }
    }

    function onMouseOut(): void {
        graph.selectAll(".cursor").remove();
    }

    // add invisible bars between each tick to support cursor functionality
    graph
        .selectAll("invisibars")
        // hack to quickly make list from 1 to 10
        .data(d3.range(1, max+1))
        .enter()
        .append("rect")
        .attr("x", d => x(d) - elWidth/2)
        .attr("y", margin.top)
        .attr("width", elWidth)
        .attr("height", innerWidth)
        .attr("stroke", "black")
        .attr("class", "violin-invisibar")
        .attr("pointer-events", "all")
        .on("mouseover", (_, d) => onMouseOver(d))
        .on("mouseout", onMouseOut);
    graph
        .selectAll("medianDot")
        .data(data)
        .enter()
        .append("circle")
        .attr("cy", d => y(d.ex_id) + y.bandwidth() / 2)
        .attr("cx", d => x(d.median))
        .attr("r", 4)
        .attr("fill", "currentColor")
        .attr("pointer-events", "none");
}

function initViolin(url: string, containerId: string, containerHeight: number): void {
    height = containerHeight;
    selector = containerId;
    const container = d3.select(selector);

    if (!height) {
        height = container.node().clientHeight - 5;
    }
    container.node().style.height = height;
    container.html(""); // clean up possible previous visualisations
    container.attr("class", "text-center").append("span").text(I18n.t("js.loading"));

    width = (container.node() as Element).getBoundingClientRect().width;
    const processor = function (raw): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }
        d3.select(`${selector} *`).remove();

        height = 150 * Object.keys(raw.data).length;
        container.node().style.height = height;

        const data = Object.keys(raw.data).map(k => ({
            "ex_id": k,
            // sort so median is calculated correctly
            "counts": raw.data[k].map(x => parseInt(x)).sort((a: number, b: number) => a-b),
            "freq": {},
            "median": 0
        })) as {
            "ex_id": string;
            "counts": number[];
            "freq": number[][];
            "median": number;
        }[];

        const maxCount: number = d3.max(data, d => d3.max(d.counts));


        data.forEach(ex => {
            ex["freq"] = d3.bin().thresholds(d3.range(1, maxCount+1))
                .domain([1, maxCount])(ex.counts);

            ex.median = d3.quantile(ex.counts, .5);
        });

        drawViolin(data, raw.exercises);
    };
    d3.json(url).then(processor);
}


export { initViolin };
