import * as d3 from "d3";


const selector = "#violin-container";
const margin = { top: 50, right: 10, bottom: 20, left: 70 };
const width = 1100 - margin.left - margin.right;
const height = 500 - margin.top - margin.bottom;

function vtest() {
    // console.log(d3.json('/nl/stats/violin?course_id=5&series_id=108'));
    // console.log(d3.json('/nl/stats/stacked_status?course_id=5&series_id=108'));
    console.log(d3.json('/nl/stats/timeseries?course_id=5&series_id=108'));
}

function initViolin(url: string) {
    d3.select(selector).attr("class", "text-center").append("span").text(I18n.t("js.loading"));
    const processor = function (raw): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }
        d3.select(`${selector} *`).remove();

        let data = Object.keys(raw.data).map(k => ({
            ex_id: k,
            // sort so median is calculated correctly
            counts: raw.data[k].map(x => parseInt(x)).sort((a, b) => a-b),
            freq: {},
            median: 0
        }))

        data.forEach((ex) => {
            ex['freq'] = ex.counts.reduce((acc, v) => {
                acc.hasOwnProperty(v) ? acc[v].freq += 1: acc[v] = {label: v, freq: 1};
                return acc;
            }, {})

            ex.median = d3.quantile(ex.counts, .5);
        });

        drawViolin(data);
    };
    d3.json(url).then(processor);
}

function drawViolin(data: Array<{ex_id: string, counts: [number], freq: {}, median: number}>) {

    let min = d3.min(data, d => d3.min(d.counts));
    let max = d3.max(data, d => d3.max(d.counts));
    const xTicks = 10;
    let elWidth = width / max;

    let maxFreq = d3.max(data, d => d3.max(Object.values(d.freq), (f: {label: string, freq: number}) => f.freq));

    const graph = d3.select(selector)
        .append("svg")
        .attr("width", 1200)
        .attr("height", 550)
        .append("g")
            .attr("transform",
                  "translate(" + margin.left + "," + margin.top + ")");

    // Show the Y scale
    let y = d3.scaleBand()
        .range([height, 0])
        .domain(data.map(d => d.ex_id))
        .padding(.5);
    graph.append("g")
        .call(d3.axisLeft(y).tickSize(0))
        .select(".domain").remove();

    let yBin = d3.scaleLinear()
        .domain([0, maxFreq])
        .range([0, y.bandwidth()])

    // Show the X scale
    let x = d3.scaleLinear()
        .domain([min, max])
        .range([5, width-5])
    graph.append("g")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(x).ticks(xTicks))
        .select(".domain").remove();

    // Add X axis label:
    graph.append("text")
        .attr("text-anchor", "end")
        .attr("x", width)
        .attr("y", height + 30)
        .text("Amount of submissions")
        .attr("fill", "currentColor")
        .style("font-size", "11px");

    graph
        .selectAll("violins")
        .data(data)
        .enter()
        .append('g')
            .attr('transform', d => `translate(0, ${y(d.ex_id) + y.bandwidth() / 2})`)
        .append('path')
            .datum(ex =>
                Object.values(ex.freq)
            )
            .style("stroke", "none")
            .style("fill", "#69b3a2")
            .attr("d", d3.area()
                .x(d => x(d.label))
                .y0(d => -yBin(d.freq))
                .y1(d => yBin(d.freq))
                .curve(d3.curveCatmullRom)
            )

    graph.selectAll("groups")
        .data(data)
        .enter()
        .append("g")
        .attr("id", d => `e${d.ex_id}`)
        .attr('transform', d => `translate(0, ${y(d.ex_id) + y.bandwidth() / 2})`)

    // add invisible bars between each tick to support cursor functionality
    for (let ex of data) {
        let group = graph.selectAll(`#e${ex.ex_id}`) // html doesn't seem to like numerical id's
        group
            .selectAll("invisibars")
            .data([...Array(max+2).keys()].slice(1, -1))
            .enter()
            .append("rect")
                .attr("x", d => x(d) - elWidth/2)
                .attr("y", -yBin.range()[1] / 2)
                .attr("width", elWidth)
                .attr("height", y.bandwidth())
                .attr("stroke", "black")
                .style("visibility", "hidden")
                .attr("pointer-events", "all")
                .style("fill", "none")
            .on("mouseover", (_, d) => onMouseOver(d, ex.ex_id))
            .on("mouseout", onMouseOut)
    }
    graph
        .selectAll("medianDot")
        .data(data)
        .enter()
        .append("circle")
            .attr("cy", d => y(d.ex_id) + y.bandwidth() / 2)
            .attr("cx", d => x(d.median))
            .attr("r", 4)
            .attr("fill", "currentColor")
            .attr("pointer-events", "none")

    function onMouseOver(d, groupName) {
        console.log(d);
        let location = graph.selectAll("#cursor").data([d]).enter()
            .append("g")
                .attr("id", "cursor")
        location
            .selectAll("cursorLine")
            .data([d])
            .enter()
            .append("line")
                .attr("x1", d => x(d))
                .attr("x2", d => x(d))
                .attr("y1", y(groupName))
                .attr("y2", y(groupName) + y.bandwidth())
                    .attr("pointer-events", "none")
                .attr("stroke", "currentColor")
                .style("width", 40);
        location
            .selectAll("cursorText")
            .data([d])
            .enter()
            .append("text")
                .attr("class", "label")
                .text(d => d)
                .attr("x", d => x(d))
                .attr("y", y(groupName) + y.bandwidth() * 1.5)
                .attr("text-anchor", "middle")
                .attr("font-family", "sans-serif")
                .attr("fill", "currentColor")
                .attr("font-size", "11px")
    }

    function onMouseOut() { 
        graph.selectAll("#cursor").remove();
    }
}


export { vtest, initViolin };