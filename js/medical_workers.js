/**
 * Created by yevheniia on 28.04.20.
 */
d3.csv("data/ukraine/medical.csv").then(function(medical) {
    const parseDate = d3.timeParse("%Y-%m-%d");


    const min_date = d3.min(medical, function(d){ return parseDate(d.zvit_date)});
    const max_date = d3.max(medical, function(d){ return parseDate(d.zvit_date)});
    const formatDate = d3.timeFormat("%d/%m");
    d3.selectAll(".current-date").text(formatDate(max_date));

    medical.forEach(function(d){
        d.zvit_date = parseDate(d.zvit_date);
        d.is_medical = +d.is_medical;
        d.medical_comsum = +d.medical_comsum;
        d.medical_percent = +d.medical_percent;
        d.medical_total = +d.medical_total;
        d.percent_total = Math.floor(+d.percent_total);
    });

    var chartOuterWidth = 250;
    var chartInnerWidth = 200;

    var chartOuterHeight = 250;
    var chartInnerHeight = 150;

    var nested = d3.nest()
        .key(function(d){ return d.registration_area; })
        .entries(medical);


    // nested.sort(function(a,b) { return b.values[1].medical_total - a.values[1].medical_total});

    const yScale = d3.scaleLinear()
        .range([chartInnerHeight, 0]);

    const xScale = d3.scaleTime()
        .domain([min_date, max_date])
        .range([0, chartInnerWidth]);


    const width = d3.select("#medical").node().getBoundingClientRect().width;
    const columns = Math.floor(width/chartOuterWidth);
    const height = nested.length / columns * chartOuterHeight;

    const chart_container = d3.select("#medical");

    const svg = chart_container.selectAll("svg")
        .data(nested)
        .enter()
        .insert("svg", ".source")
        .attr("width", chartOuterWidth)
        .attr("height", chartOuterHeight)
        .attr("class", "multiple");


    const multiple =svg.append("g")
        .attr("transform", "translate(" + 20 + "," + 40 + ")");


    multiple.append("g")
        .attr("transform", "translate(0," + chartInnerHeight + ")")
        .attr("class", "x axis")
        .call(d3.axisBottom(xScale)
            .tickFormat(function(d) { return d3.timeFormat("%m/%y")(d) })
            .ticks(d3.timeDay.filter(d => d3.timeDay.count(0, d) % 60 === 0))
    )

    multiple.append("g")
        .attr("class", "y axis");

    var text = multiple.append("text")
        .attr("transform", "translate(0," + -20 + ")")
        .attr("x", "90")
        .attr("text-anchor", "middle")
        .style("font-weight", "bold");


    var line = multiple
        .append("path")
        .attr("class", "med-line")
        .style("fill", "none")
        .style("stroke", "#cf1e25")
        .style("stroke-width", 2);


   drawMedical("medical_percent", "percent_total", "%");


   d3.select("#medical_percent").on("click", function(){
       d3.select("#medical_percent").classed("med-covid-active", true);
       d3.select("#is_medical").classed("med-covid-active", false);
       drawMedical("medical_percent", "percent_total", " %")
   });

   d3.select("#is_medical").on("click", function(){
       d3.select("#medical_percent").classed("med-covid-active", false);
       d3.select("#is_medical").classed("med-covid-active", true);
       drawMedical("is_medical", "medical_total", "чол.")
   });



  function drawMedical(yValue, label_value, label){


      svg.sort(function(a,b){ return b.values[1][label_value] - a.values[1][label_value]});


      // var cases_by_region = d3.nest()
      //     .key(function(d) { return d.priority_hosp_area; })
      //     .rollup(function(v) { return d3.sum(v, function(d) { return d.is_medical; }); })
      //     .object(medical);


      yScale.domain([0, d3.max(medical, function(d){ return d[yValue]})]);


      multiple.select(".y.axis")
          .transition()
          .duration(500)
          .call(d3.axisLeft(yScale)
              .ticks(5)
              .tickSize(-chartInnerWidth));

      text
          .transition()
          .duration(500)
          .text(function(d, i) {
                  return d.key + " (" +  d.values[1][label_value] + " " + label + ")"
          });


      line
          .transition()
          .duration(500)
          .attr("d", function(d){
              return d3.line()
                  .x(function(d, i) { return xScale(d.zvit_date); })
                  .y(function(d) { return yScale(d[yValue]); })
                  (d.values)
          });
  }

});