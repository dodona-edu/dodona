let initPunchcard = function (url) {
    $.ajax({
        type: "GET",
        contentType: "application/json",
        url: url,
        dataType: "json",
        success: function (data) {
            drawPunchCard(data);
        },
        failure: function () {
            console.log("Failed to load submission data");
        },
    });
};

const margin = {top: 20, right: 20, bottom: 40, left: 100};
const width = 600;
const height = 400;
const labelsX = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
const labelsY = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

function formatData(data) {
    // Map submission times to days and hours. We want the week to start on Monday, but getDay() returns 0 for Sunday.
    let mapDates = data.map(s => {
        let d = new Date(s.created_at);
        let day = d.getDay() - 1;
        if (day === -1) {
            day = 6;
        }
        return [day, d.getHours()];
    });

    // Kind of hacky? Use an object as an accumulator. An object can only have strings as keys, so the array is
    // converted to a string. Find the value if the key already exists and add 1, else just use 1 as the key.
    let counts = mapDates.reduce((acc, curr) => {
        acc[curr] = (acc[curr] + 1) || 1;
        return acc;
    }, {});

    // Get the keys from the previous generated object and map over them, adding the count back to the array.
    let sumSubmissions = Object.keys(counts).map(function (key) {
        let keyArray = key.split(",");
        keyArray.push(counts[key]);
        return keyArray;
    });
    return sumSubmissions;
}

function drawPunchCard(data) {
    const submissionData = formatData(data);

    initChart(submissionData);
}

function initChart(data) {
    // Constants to use, need changing if something more responsive is needed.
    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;
    const unitWidth = innerWidth / 24;
    const unitHeight = innerHeight / 24;
    const unitSize = Math.min(unitWidth, unitHeight);

    const chart = d3.select("#punchcard-container").append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform", `translate(${margin.left}, ${margin.top})`);

    const x = d3.scaleLinear()
        .domain([0, 23])
        .range([unitWidth / 2, innerWidth - unitWidth / 2]);

    const y = d3.scaleLinear()
        .domain([0, 6])
        .range([unitHeight / 2, innerHeight - unitHeight / 2]);

    const xAxis = d3.axisBottom(x)
        .ticks(24)
        .tickFormat((d, i) => labelsX[i]);

    const yAxis = d3.axisLeft(y)
        .ticks(7)
        .tickFormat((d, i) => labelsY[i]);

    renderAxes(xAxis, yAxis, chart, innerHeight);
    renderCard(data, unitSize, chart, x, y);
}

function renderAxes(xAxis, yAxis, chart, innerHeight) {
    chart.append("g")
        .attr("class", "xaxis")
        .attr("transform", `translate(0, ${innerHeight})`)
        .call(xAxis);

    chart.append("g")
        .attr("class", "yaxis")
        .call(yAxis);
}

function renderCard(data, unitSize, chart, x, y) {
    const maxVal = d3.max(data, d => d[2]);

    let radius = d3.scaleSqrt()
        .domain([0, maxVal])
        .range([0, unitSize / 2]);

    let circles = chart.selectAll("circle")
        .data(data);

    let updates = [circles, circles.enter().append("circle")];
    updates.forEach(group => {
        group.attr("cx", d => x(d[1]))
            .attr("cy", d => y(d[0]))
            .attr("r", d => radius(d[2]))
            .style("fill", "grey");
    });

    circles.exit().remove();
}

export {initPunchcard};
