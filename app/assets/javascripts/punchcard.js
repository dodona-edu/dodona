import * as d3 from "d3";

const containerSelector = "#punchcard-container";
const margin = { top: 10, right: 10, bottom: 20, left: 70 };
const labelsX = [...Array(24).keys()];

function initPunchcard(url) {
    // If this is defined outside of a function, the locale always defaults to "en".
    const labelsY = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"].map(k => I18n.t(`js.weekdays.long.${k}`));

    const container = d3.select(containerSelector);
    const width = container.node().getBoundingClientRect().width;
    const innerWidth = width - margin.left - margin.right;
    const unitSize = innerWidth / 24;
    const innerHeight = unitSize * 7;
    const height = innerHeight + margin.top + margin.bottom;

    const chart = container.append("svg")
        // When resizing, the svg will scale as well. Doesn't work perfectly.
        .attr("viewBox", `0,0,${width},${height}`)
        .style("overflow-x", "scroll")
        .append("g")
        .attr("transform", `translate(${margin.left}, ${margin.top})`);

    const x = d3.scaleLinear()
        .domain([0, 23])
        .range([unitSize / 2, innerWidth - unitSize / 2]);

    const y = d3.scaleLinear()
        .domain([0, 6])
        .range([unitSize / 2, innerHeight - unitSize / 2]);

    chart.append("text")
        .attr("class", "loading-text")
        .text(I18n.t("js.loading"))
        .attr("x", innerWidth / 2)
        .attr("y", innerHeight / 2)
        .style("text-anchor", "middle");

    const processor = data => {
        if (data["status"] === "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }
        renderCard(Object.entries(data), unitSize, chart, x, y);
    };
    d3.json(url)
        .then(processor);

    const xAxis = d3.axisBottom(x)
        .ticks(24)
        .tickSize(0)
        .tickFormat((d, i) => labelsX[i])
        .tickPadding(10);
    const yAxis = d3.axisLeft(y)
        .ticks(7)
        .tickSize(0)
        .tickFormat((d, i) => labelsY[i])
        .tickPadding(10);

    renderAxes(xAxis, yAxis, chart, innerHeight);
}

function renderAxes(xAxis, yAxis, chart, innerHeight) {
    chart.append("g")
        .attr("class", "axis")
        .attr("transform", `translate(0, ${innerHeight})`)
        .call(xAxis);

    chart.append("g")
        .attr("class", "axis")
        .call(yAxis);

    d3.selectAll(".axis > path")
        .style("display", "none");
}

function renderCard(data, unitSize, chart, x, y) {
    const maxVal = d3.max(data, d => d.value);
    const radius = d3.scaleSqrt()
        .domain([0, maxVal])
        .range([0, unitSize / 2]);

    chart.selectAll("text.loading-text").remove();

    const circles = chart.selectAll("circle")
        .data(data);

    const updates = circles.enter().append("circle");
    updates.attr("cx", d => x(parseInt(d.key.split(",")[1])))
        .attr("cy", d => y(parseInt(d.key.split(",")[0])))
        .transition()
        .delay(d => 500 + 20 * (parseInt(d.key.split(",")[0]) + parseInt(d.key.split(",")[1])))
        .duration(800)
        .ease(d3.easeBackOut)
        .attr("r", d => radius(d.value));
    updates.append("svg:title")
        .text(d => d.value);
    circles.exit().remove();
}

export { initPunchcard };

