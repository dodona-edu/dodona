import * as d3 from "d3";

let selector = "";
const margin = { top: 20, right: 40, bottom: 80, left: 40 };
let width = 0;
let height = 0;
const bisector = d3.bisector((d: Date) => d.getTime()).left;


function insertFakeData(data): void {
    const end = new Date((data[Object.keys(data)[0]][0].date));
    const start = new Date(end);
    start.setDate(start.getDate() - 14);
    for (const exName of Object.keys(data)) {
        data[exName] = [];
        for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1 + Math.random()*2)) {
            if (Math.random() > 0.5) {
                data[exName].push({
                    "date": new Date(d),
                    "count": Math.round(Math.random()*20)
                });
            }
        }
    }
}

function thresholdTime(n, min, max): () => Date[] {
    return () => {
        return d3.scaleTime().domain([min, max]).ticks(n);
    };
}

function drawCumulativeTimeSeries(data, metaData, exMap): void {
    if (I18n.locale === "nl") {
        d3.timeFormatDefaultLocale({
            "dateTime": "%a %b %e %X %Y",
            "date": "%d%m/%Y",
            "time": "%H:%M:%S",
            "periods": ["", ""],
            "days": [
                "Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag", "Zondag"
            ],
            "shortDays": ["Ma", "Di", "Wo", "Do", "Vr", "Za", "Zo"],
            "months": [
                "Januari", "Februari", "Maart", "April", "Mei",
                "Juni", "Juli", "Augustus", "September", "Oktober", "November", "December"
            ],
            "shortMonths": [
                "Jan", "Feb", "Maa", "Apr", "Mei", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dec"
            ]
        });
    }
    const exOrder: string[] = exMap.map(ex => ex[0]).reverse();
    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;
    const dateFormat = d3.timeFormat("%A %B %d");
    const dateArray = d3.timeDays(metaData["minDate"], metaData["maxDate"]);
    dateArray.unshift(metaData["minDate"]);

    const mapEx = (target: string): string =>
        exMap.find(ex => target.toString() === ex[0].toString());

    const svg = d3.select(selector)
        .append("svg")
        .attr("width", width)
        .attr("height", height);

    // position graph
    const graph = svg
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    // common y scale per exercise
    const y = d3.scaleLinear()
        .domain([0, metaData["maxSum"]])
        .range([innerHeight, 0]);

    // y axis
    graph.append("g")
        .call(d3.axisLeft(y));

    // Show the X scale
    const x = d3.scaleTime()
        .domain([metaData["minDate"], metaData["maxDate"]])
        .range([0, innerWidth]);


    // Color scale
    const color = d3.scaleOrdinal()
        .range(d3.schemeDark2)
        .domain(exOrder);


    // add x-axis
    graph.append("g")
        .attr("transform", `translate(0, ${y(0)})`)
        .call(d3.axisBottom(x).ticks(metaData["dateRange"] / 2, "%a %b-%d"));

    const tooltip = graph.append("line")
        .attr("y1", 0)
        .attr("y2", innerHeight)
        .attr("pointer-events", "none")
        .attr("stroke", "currentColor")
        .style("width", 40);
    const tooltipLabel = graph.append("text")
        .attr("opacity", 0)
        .text("_") // dummy text to calculate height
        .attr("text-anchor", "start")
        .attr("fill", "currentColor")
        .attr("font-size", "12px");
    tooltipLabel
        .attr("y", margin.top + tooltipLabel.node().getBBox().height);
    const tooltipDots = graph.selectAll("dots")
        .data(Object.entries(data), d => d[0])
        .join("circle")
        .attr("r", 4)
        .attr("opacity", 0)
        .style("fill", d => color(d[0]));
    const tooltipDotLabels = graph.selectAll("dotlabels")
        .data(Object.entries(data), d => d[0])
        .join("text")
        .attr("text-anchor", "start")
        .attr("fill", d => color(d[0]))
        .attr("opacity", 0)
        .attr("font-size", "12px");

    let tooltipI = -1;

    const legend = svg.append("g");

    let legendX = 0;
    for (const ex of exOrder) {
        // add legend colors dots
        const group = legend.append("g");

        group
            .append("rect")
            .attr("x", legendX)
            .attr("y", 0)
            .attr("width", 15)
            .attr("height", 15)
            .attr("fill", color(ex) as string);

        // add legend text
        group
            .append("text")
            .attr("x", legendX + 20)
            .attr("y", 12)
            .attr("text-anchor", "start")
            .text(mapEx(ex)[1])
            .attr("fill", "currentColor")
            .style("font-size", "12px");

        legendX += group.node().getBBox().width + 20;
    }
    legend.attr(
        "transform",
        `translate(${width/2 - legend.node().getBBox().width/2},
        ${innerHeight+margin.top+margin.bottom/2})`
    );

    // add lines
    for (const exId of Object.keys(data)) {
        const exGroup = graph.append("g");
        const bins = data[exId];
        exGroup.selectAll("lines")
            .data([bins])
            .enter()
            .append("path")
            .attr("class", mapEx(exId))
            .style("stroke", color(exId) as string)
            .style("fill", "none")
            .attr("d", d3.line()
                .x(p => x(p[0]["x0"]))
                .y(p => y(p[1]))
                .curve(d3.curveMonotoneX)
            );
    }

    function bisect(mx: number): {"date": Date; "i": number} {
        if (!dateArray) {
            return { "date": new Date(0), "i": 0 };
        }
        const date = x.invert(mx);
        const index = bisector(dateArray, date, 1);
        const a = index > 0 ? dateArray[index-1] : metaData["minDate"];
        const b = index < dateArray.length ? dateArray[index] : metaData["maxDate"];
        if (date.getTime()-a.getTime() > b.getTime()-date.getTime()) {
            return { "date": b, "i": index };
        } else {
            return { "date": a, "i": index-1 };
        }
    }

    svg.on("mousemove", e => {
        if (!dateArray) {
            return;
        }
        const { date, i } = bisect(d3.pointer(e, graph.node())[0]);
        if (i !== tooltipI) {
            tooltipI = i;
            tooltip
                .attr("opacity", 1)
                .attr("x1", x(date))
                .attr("x2", x(date));
            tooltipLabel
                .attr("opacity", 1)
                .text(dateFormat(date))
                .attr(
                    "x",
                    x(date) - tooltipLabel.node().getBBox().width - 5 > 0 ?
                        x(date) - tooltipLabel.node().getBBox().width - 5 :
                        x(date) + 10
                );
            tooltipDots
                .attr("opacity", 1)
                .attr("cx", x(date))
                .attr("cy", d => y(d[1][i][1]));
            tooltipDotLabels
                .attr("opacity", 1)
                .text(d => d[1][i][1])
                .attr("x", x(date) + 5)
                .attr("y", d => y(d[1][i][1])-5);
        }
    });

    svg.on("mouseleave", () => {
        tooltipI = -1;
        tooltip
            .attr("opacity", 0);
        tooltipLabel
            .attr("opacity", 0);
        tooltipDots
            .attr("opacity", 0);
        tooltipDotLabels
            .attr("opacity", 0);
    });
}

function initCumulativeTimeseries(url, containerId, containerHeight: number): void {
    height = containerHeight;
    selector = containerId;
    const container = d3.select(selector);

    if (!height) {
        height = (container.node() as HTMLElement).clientHeight - 5;
    }
    container
        .html("") // clean up possible previous visualisations
        .style("height", `${height}px`) // prevent shrinking after switching graphs
        .style("display", "flex")
        .style("align-items", "center")
        .attr("class", "text-center")
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


        const data: {string: {date; status; count}[]} = raw.data;
        const metaData = {}; // used to store things needed to create scales
        if (Object.keys(data).length === 0) {
            container
                .style("height", "50px")
                .append("div")
                .text(I18n.t("js.no_data"))
                .style("margin", "auto");
            return;
        }

        height = 75 * Object.keys(raw.data).length;
        container.style("height", `${height}px`);
        // insertFakeData(data);
        metaData["minDate"] = d3.min(Object.values(data),
            records => d3.min(records, d =>new Date(d.date)));
        metaData["maxDate"] = d3.max(Object.values(data),
            records => d3.max(records, d =>new Date(d.date)));
        metaData["maxSum"] = 0;
        metaData["dateRange"] = Math.round(
            (metaData["maxDate"].getTime() - metaData["minDate"].getTime()) /
            (1000 * 3600 * 24)
        ); // dateRange in days
        Object.entries(data).forEach(entry => {
            const exId = entry[0];
            let records = entry[1];
            // parse datestring to date
            records.forEach(r => {
                r.date = new Date(r.date);
            });

            const binned = d3.bin()
                .value(d => d.date.getTime())
                .thresholds(
                    thresholdTime(metaData["dateRange"]+1, metaData["minDate"], metaData["maxDate"])
                ).domain([metaData["minDate"], metaData["maxDate"]])(records);

            records = undefined; // records no longer needed
            data[exId] = d3.zip(binned, d3.cumsum(binned, d => d.length ? d[0].count : 0));
            metaData["maxSum"] = Math.max(data[exId][data[exId].length-1][1], metaData["maxSum"]);
        });

        drawCumulativeTimeSeries(data, metaData, raw.exercises);
    };
    d3.json(url)
        .then(processor);
}
export { initCumulativeTimeseries };
