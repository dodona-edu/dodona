import * as d3 from "d3";
import { RawData, SeriesGraph } from "visualisations/series_graph";

export class TimeseriesGraph extends SeriesGraph {
    protected readonly baseUrl = "/stats/timeseries?series_id=";
    private readonly margin = { top: 20, right: 40, bottom: 20, left: 140 };
    private readonly fontSize = 12;
    private readonly yAxisPadding = 40; // padding between y axis (labels) and the actual graph

    private readonly statusOrder = [
        "correct", "wrong", "compilation error", "runtime error",
        "time limit exceeded", "memory limit exceeded", "output limit exceeded",
    ];

    // axes
    private y: d3.ScaleBand<string>
    private x: d3.ScaleTime<number, number>
    private color: d3.ScaleSequential<string>;

    // data
    private maxStack = 0; // largest value (max of colour scale domain)
    private dateRange: number; // difference between first and last date in days
    private minDate: Date;
    private maxDate: Date;

    private data: {
        // eslint-disable-next-line camelcase
        ex_id: string,
        // eslint-disable-next-line camelcase
        ex_data:{date: Date; sum: number; [index: string]: number | Date}[]
    }[] = [];

    // svg elements
    private tooltip: d3.Selection<HTMLDivElement, unknown, HTMLElement, unknown>;

    /**
    * draws the graph's svg (and other) elements on the screen
    * No more data manipulation is done in this function
    */
    protected override draw(): void {
        this.height = 75 * this.exOrder.length;
        const innerHeight = this.height - this.margin.top - this.margin.bottom;
        const innerWidth = this.width - this.margin.left - this.margin.right;

        const darkMode = window.dodona.darkMode;
        const emptyColor = darkMode ? "#37474F" : "white"; // no data in cell
        const lowColor = darkMode ? "#01579B" : "#E3F2FD"; // almost no data in cell
        const highColor = darkMode ? "#039BE5" : "#0D47A1"; // a lot of data in cell

        this.svg = this.container
            .style("height", `${this.height}px`)
            .append("svg")
            .attr("height", this.height)
            .attr("width", this.width);

        // position graph
        this.graph = this.svg
            .append("g")
            .attr("transform",
                `translate(${this.margin.left}, ${this.margin.top})`);

        // init scales
        // Y scale for exercises
        this.y = d3.scaleBand()
            .range([innerHeight, 0])
            .domain(this.exOrder)
            .padding(.5);

        // Color scale
        this.color = d3.scaleSequential(d3.interpolate(lowColor, highColor))
            .domain([0, this.maxStack]);

        const end = new Date(this.maxDate);
        end.setHours(0, 0, 0, 0); // bin and domain seem to handle end differently

        // x scale
        this.x = d3.scaleTime()
            .domain([this.minDate, end])
            .range([0, innerWidth]);


        // init axes
        const yAxis = this.graph.append("g").call(d3.axisLeft(this.y).tickSize(0))
            .attr("transform", `translate(-${this.yAxisPadding}, -${this.y.bandwidth()/2})`);

        yAxis
            .select(".domain").remove();
        yAxis
            .selectAll(".tick text")
            .call(this.formatTitle, this.margin.left-this.yAxisPadding, this.exMap);

        // add x-axis
        this.graph.append("g")
            .attr("transform", `translate(0, ${innerHeight-this.y.bandwidth()/2})`)
            .call(
                d3.axisBottom(this.x)
                    .ticks(15, I18n.t("date.formats.weekday_short"))
            );

        // init tooltip
        this.tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);

        // make sure cell size isn't bigger than bandwidth
        const rectSize = Math.min(this.y.bandwidth()*1.5, innerWidth / this.dateRange - 5);
        // add cells
        this.graph.selectAll(".rectGroup")
            .data(this.data)
            .enter()
            .append("g")
            .attr("class", "rectGroup")

            // eslint-disable-next-line camelcase
            .each(({ ex_data, ex_id }, i, group) => {
                d3.select(group[i]).selectAll("rect")
                    .data(ex_data, d => d["date"].getTime())
                    .enter()
                    .append("rect")
                    .attr("class", "day-cell")
                    .classed("empty", d => d.sum === 0)
                    .attr("rx", 6)
                    .attr("ry", 6)
                    .attr("fill", emptyColor)
                    .attr("x", d => this.x(d.date)-rectSize/2)
                    .attr("y", this.y(ex_id)-rectSize/2)
                    .on("mouseover", (_e, d) => this.tooltipHover(d))
                    .on("mousemove", e => this.tooltipMove(e))
                    .on("mouseout", () => this.tooltipOut())
                    .transition().duration(500)
                    .attr("width", rectSize)
                    .attr("height", rectSize)
                    .transition().duration(500)
                    .attr("fill", d => d.sum === 0 ? "" : this.color(d.sum));
            });
    }

    /**
     * Transforms the data from the server into a form usable by the graph.
     *
     * @param {RawData} raw The unprocessed return value of the fetch
     */
    protected override processData({ data, exercises }: RawData): void {
        // the type of one datum in the ex_data array
        type Datum = {date: (Date | string); status: string; count: number};

        this.parseExercises(exercises, data.map(ex => ex.ex_id));

        data.forEach(ex => {
            // convert dates form strings to actual date objects
            ex.ex_data.forEach((d: Datum) => {
                d.date = new Date(d.date);
                // make sure they are set to midnight
                d.date.setHours(0, 0, 0, 0);
            });
        });

        const [minDate, maxDate] = d3.extent(
            data.flatMap(ex => ex.ex_data),
            (d: Datum) => d.date as Date
        );
        this.minDate = new Date(minDate);
        this.maxDate = new Date(maxDate);
        this.maxDate.setHours(23, 59, 59, 99); // set end right before midnight

        this.dateRange = d3.timeDay.count(this.minDate, this.maxDate) + 1; // dateRange in days
        const threshold = d3.scaleTime()
            .domain([this.minDate.getTime(), this.maxDate.getTime()])
            .ticks(d3.timeDay);

        // eslint-disable-next-line camelcase
        data.forEach(({ ex_id, ex_data }) => {
            // bin per day
            const binned = d3.bin()
                .value(d => d.date.getTime())
                .thresholds(threshold)
                .domain([this.minDate.getTime(), this.maxDate.getTime()])(ex_data);

            const parsedData = [];
            // reduce bins to a single record per bin (see this.data)
            binned.forEach((bin, i) => {
                const newDate = new Date(this.minDate);
                newDate.setDate(newDate.getDate() + i);
                const sum = d3.sum(bin, r => r["count"]);
                this.maxStack = Math.max(this.maxStack, sum);
                parsedData.push(bin.reduce((acc, r) => {
                    acc.date = r.date;
                    acc.sum = sum;
                    acc[r.status] = r.count;
                    return acc;
                }, this.statusOrder.reduce((acc, s) => {
                    acc[s] = 0; // make sure record is initialized with 0 counts
                    return acc;
                }, { "date": newDate, "sum": 0 })));
            });
            this.data.push({ ex_id: String(ex_id), ex_data: parsedData });
        });
    }

    // tooptip functions

    /**
     * Function when mouse is hovered over a rectangle, makes the tooltip appear
     * and sets the tooltip message
     * @param {Object} d datum for a single rectangle
     */
    private tooltipHover(
        d: {
        [index: string]: number | Date;
        date: Date;
        sum: number;
    }): void {
        this.tooltip.transition()
            .duration(200)
            .style("opacity", .9);
        let message = `${this.longDateFormat(d.date)}<br>
        ${I18n.t("js.submissions")} :<br>${d.sum} ${I18n.t("js.total")}`;
        this.statusOrder.forEach(s => {
            if (d[s]) {
                message += `<br>${d[s]} ${s}`;
            }
        });
        this.tooltip.html(message);
    }

    /**
     * Function when mouse is moved over rectangle, sets the tooltip position
     * @param {*} e event parameter, used to determine mouse position
     */
    private tooltipMove(e: unknown): void {
        const bbox = this.tooltip.node().getBoundingClientRect();
        this.tooltip
            .style(
                "left",
                `${d3.pointer(e, this.svg.node())[0]-bbox.width * 1.1}px`
            )
            .style(
                "top",
                `${d3.pointer(e, this.svg.node())[1]-bbox.height*1.1}px`
            );
    }

    /**
     * Function when mouse is moved out of a rectangle, makes tooltip disappear.
     */
    private tooltipOut(): void {
        this.tooltip.transition()
            .duration(500)
            .style("opacity", 0);
    }
}
