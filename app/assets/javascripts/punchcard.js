let initPunchcard = function (url) {
    $.ajax({
        type: "GET",
        contentType: "application/json",
        url: url,
        dataType: "json",
        success: function (data) {
            initChart(data);
        },
        failure: function () {
            console.log("Failed to load submission data");
        },
    });
};

const margin = {top: 10, right: 10, bottom: 20, left: 70};
const labelsX = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
const labelsY = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

function initChart(data) {
    const container = d3.select("#punchcard-container");
    const width = container.node().getBoundingClientRect().width;
    const innerWidth = width - margin.left - margin.right;
    const unitSize = innerWidth / 24;
    const innerHeight = unitSize * 7;
    const height = innerHeight + margin.top + margin.bottom;

    const chart = container.append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform", `translate(${margin.left}, ${margin.top})`);

    const x = d3.scaleLinear()
        .domain([0, 23])
        .range([unitSize / 2, innerWidth - unitSize / 2]);

    const y = d3.scaleLinear()
        .domain([0, 6])
        .range([unitSize / 2, innerHeight - unitSize / 2]);

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
    renderCard(data, unitSize, chart, x, y);
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
    const maxVal = d3.max(data, d => d[2]);
    const minVal = d3.min(data, d => d[2]);

    let radius = d3.scaleSqrt()
        .domain([0, maxVal])
        .range([0, unitSize / 2]);

    let gradient = d3.scaleLinear()
        .domain([minVal, maxVal])
        .rangeRound([255 * 0.8, 0]);

    let circles = chart.selectAll("circle")
        .data(data);

    let updates = [circles, circles.enter().append("circle")];
    updates.forEach(group => {
        group.attr("cx", d => x(d[1]))
            .attr("cy", d => y(d[0]))
            .attr("r", d => radius(d[2]))
            .style("fill", d => {
                const gr = gradient(d[2]);
                return `rgb(${gr},${gr},${gr})`;
            });
    });



    circles.exit().remove();
}

export {initPunchcard};
