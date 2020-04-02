Promise.all([
    d3.csv("data/ukraine/cases_by_date.csv"),
    d3.csv("data/ukraine/cases_by_region.csv")
]).then(function(data) {

    var parseDate = d3.timeParse("%Y-%m-%d");
    const formatDate = d3.timeFormat("%d/%m");
    var bisectDate = d3.bisector(function(d) { return d.date; }).left;

    data[0] = data[0].filter(function(d){
        return d.comsum > 0
    });

    const max_date = d3.max(data[0], function(d){ return parseDate(d.date)});
    d3.selectAll(".current-date").text(formatDate(max_date));

    var margin = {top: 10, right: 100, bottom: 50, left: 35};
    var widther = d3.select("#total_amount").node().getBoundingClientRect().width;

    var width = widther - margin.left - margin.right,
        height = 300 - margin.top - margin.bottom;


    var svg = d3.select("#total_amount")
        .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var xScale = d3.scaleTime().range([0, width]);
    var yScale = d3.scaleLinear() .range([height, 0]);

    var yAxis = d3.axisLeft(yScale)
        .ticks(6)
        .tickSize(-width)
        .tickPadding(8);

    var xAxis = d3.axisBottom(xScale)
        .tickPadding(8)
        // .tickSize(height)
        .ticks(numTicks(width))
        .tickFormat(d3.timeFormat("%d/%m"));

    var area = d3.line()
        .x(function(d) { return xScale(d.date); })
        // .y0(yScale(0))
        .y(function(d) { return yScale(d.comsum); });

        data[0].forEach(function(d) {
            d.comsum = +d.comsum;
            d.date = parseDate(d.date);
        });

        data[0].sort(function(a,b) { return a.date - b.date; });

        xScale.domain(d3.extent(data[0], function(d) { return d.date; }));
        yScale.domain(d3.extent(data[0], function(d) { return d.comsum; }));

        var yAxisGroup = svg.append("g")
            .attr("class", "y axis")
            .call(yAxis);

        var xAxisGroup = svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + height + ")")
            .call(xAxis)
            // .selectAll("text")
            // .attr("y", 0)
            // .attr("x", 9)
            // .attr("dy", ".35em")
            // .attr("transform", "rotate(90)")
            // .style("text-anchor", "start")
            ;

        var drawline = svg.append("path")
            .datum(data[0])
            .attr("class", "line")
            .attr("d", area);

        var focus = svg.append("g")
            .attr("class", "focus")
            .style("display", "none");

        focus.append("circle")
            .attr("r", 4);

        focus.append("text")
            .attr("x", 9)
            .attr("dy", ".35em");

        var overlay = svg.append("rect")
            .attr("class", "overlay")
            .attr("width", width)
            .attr("height", height)
            .on("mouseover", function() { focus.style("display", null); })
            .on("mouseout", function() { focus.style("display", "none"); })
            .on("mousemove", mousemove);

        function mousemove() {
            var x0 = xScale.invert(d3.mouse(this)[0]),
                i = bisectDate(data[0], x0, 1),
                d0 = data[0][i - 1],
                d1 = data[0][i],
                d = x0 - d0.date > d1.date - x0 ? d1 : d0;

            focus.attr("transform", "translate(" + xScale(d.date) + "," + yScale(d.comsum) + ")");
            focus.select("text").text(formatDate(d.date) + " - " + d.comsum);
        }




//Determines number of ticks base on width
    function numTicks(widther) {
        if (widther <= 900) {
            return 6;
            console.log("return 4");
        }
        else {
            return 12;
            console.log("return 5");
        }
    }


});