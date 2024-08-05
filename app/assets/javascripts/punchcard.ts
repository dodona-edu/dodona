import * as d3 from "d3";
import { i18n } from "i18n/i18n";

const containerSelector = "#punchcard-container";
const margin = { top: 10, right: 10, bottom: 20, left: 70 };

type chartType = d3.Selection<SVGGElement, unknown, HTMLElement, unknown>;

function initPunchcard(url: string): void {
    // If this is defined outside of a function, the locale always defaults to "en".
    const labelsY = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"].map(k => i18n.t(`js.weekdays.long.${k}`));

    const container = d3.select(containerSelector);
    const width = (container.node() as Element).getBoundingClientRect().width;
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
        .text(i18n.t("js.loading"))
        .attr("x", innerWidth / 2)
        .attr("y", innerHeight / 2)
        .style("text-anchor", "middle");

    const processor = (data): void => {
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
        .tickFormat(hour => `${(hour as number) < 10 ? "0" : ""}${hour}:00`)
        .tickPadding(10);
    const yAxis = d3.axisLeft(y)
        .ticks(7)
        .tickSize(0)
        .tickFormat((_d, i) => labelsY[i])
        .tickPadding(10);

    renderAxes(xAxis, yAxis, chart, innerHeight);
}

function renderAxes(xAxis: d3.Axis<d3.NumberValue>, yAxis: d3.Axis<d3.NumberValue>, chart: chartType, innerHeight: number): void {
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

function renderCard(data: Array<[string, number]>, unitSize: number, chart: chartType, x: d3.ScaleLinear<number, number>, y: d3.ScaleLinear<number, number>): void {
    const maxVal = d3.max(data, d => d[1]);
    const radius = d3.scaleSqrt()
        .domain([0, maxVal])
        .range([0, unitSize / 2]);

    chart.selectAll("text.loading-text").remove();

    const circles = chart.selectAll("circle")
        .data(data);

    const updates = circles.enter().append("circle");
    updates.attr("cx", d => x(parseInt(d[0].split(",")[1])))
        .attr("cy", d => y(parseInt(d[0].split(",")[0])))
        .transition()
        .delay(d => 500 + 20 * (parseInt(d[0].split(",")[0]) + parseInt(d[0].split(",")[1])))
        .duration(800)
        .ease(d3.easeBackOut)
        .attr("r", d => radius(d[1]));
    updates.append("svg:title")
        .text(d => d[1]);
    circles.exit().remove();
}

export { initPunchcard };

