const margin = { top: 0, right: 0, bottom: 0, left: 0},
    width = 1200 - margin.left - margin.right,
    height = 800 - margin.top - margin.bottom;

var projection = d3.geoMercator()
    .scale(3000)
    .center([30, 50]);

var path = d3.geoPath()
    .projection(projection);


var hexbin = d3.hexbin()
    .extent([[-margin.left, -margin.top], [width + margin.right, height + margin.bottom]])
    .radius(15);

var chr_Red = d3.scaleSqrt()
    .range(["white", "#cf1e25"]);

var hex_Red = d3.scaleSqrt()
    .range(["white", "#cf1e25"]);



Promise.all([
    d3.json("data/ukr_adm1_lite.json"), //files[0]
    d3.csv("data/ukraine/cases_by_region.csv"), //files[4]
    d3.csv("data/ukraine/death_cases.csv")  //files[3]

    // d3.csv("data/ukraine/confirmed_cases_1.csv"), //files[1]
    // d3.csv("data/ukraine/confirmed_cases_2.csv") //files[2]
    // d3.csv("data/ukraine/suspected_cases.csv"),

]).then(function(files) {

    // files[4].forEach(function(d){
    //     files[3].push(d)
    // });

    var totalConfirmed = 0;
    var totalSuspected = 0;
    var totalDeaths = 0;

    var regions = [];
    files[1].forEach(function (d, i) {
        d.new_confirm = +d.new_confirm;
        d.new_susp = +d.new_susp;
        d.new_death = +d.new_death;
        d.registration_area = d.registration_area.replace("м. Київ", "Київ");
        regions.push(d.registration_area);
        totalConfirmed += d.new_confirm;
        totalSuspected += d.new_susp;
        totalDeaths += d.new_death;
    });


    d3.select("#confirmed_amount").html(totalConfirmed);
    d3.select("#suspected_amount").html(totalSuspected);
    d3.select("#deaths_amount").html(totalDeaths);

    // map by region
    const create_choropl_map = function(container, column, colorScale, tip) {
        colorScale.domain([0, d3.max(files[1], function(d){ return d[column] }) ]);


        let map = d3.select(container)
            .append('svg')
            .attr("id", "map")
            .attr("viewBox", "0 0 1200 800")
            .append("g")
            .attr("transform", "translate(" + margin.left + ", " + margin.top + ")");


        map.selectAll("path")
            .data(files[0].features)
            .enter()
            .append("path")
            .attr("class", "tip")
            .attr("d", path)
            .attr("fill", function (d) {
                var colorValue = files[1].filter(function (k) {
                    return k.registration_area === d.properties.region_name;
                });
                if (colorValue.length > 0) {
                    return colorScale(colorValue[0][column])
                } else {
                    return "white"
                }
            })
            .attr("data-tippy-content", function(d) {
                var colorValue = files[1].filter(function (k) {
                    return k.registration_area === d.properties.region_name;
                });
                if (colorValue.length > 0) {
                    if(d.properties.region_name != "Київ") {
                        return d.properties.region_name + " область. <br>" + tip +colorValue[0][column]
                    } else {
                        return d.properties.region_name + ". <br>" + tip +colorValue[0][column]
                    }
                } else {
                    return d.properties.region_name + ". Немає даних"
                }
            })
            .attr("stroke", "grey")
            .attr("stroke-width", "1px");
    };

    create_choropl_map("#ch_suspected", "new_susp", chr_Red, "К-ть осіб із підозрою: ");
    create_choropl_map("#ch_confirmed", "new_confirm", chr_Red, "К-ть діагностованих випадків: ");
    create_choropl_map("#ch_died", "new_death", chr_Red, "Померло: ");


    /* hexagonic map */
    // const create_hex_map = function(df, container, colorScale, tip, colname) {
    //     df.forEach(function (d) {
    //         d[1] = +d.legal_entity_lat;
    //         d[0] = +d.legal_entity_lng;
    //         var p = projection(d);
    //         d[0] = p[0], d[1] = p[1];
    //         d[colname] = +d[colname];
    //     });
    //
    //     var total_cases = df.reduce(function(a, b) {
    //         return a + b[colname];
    //     }, 0);
    //
    //     // d3.select("#"+colname+"_amount")
    //     //     .text(total_cases);
    //
    //     colorScale.domain([0, d3.max(hexbin(df), function(d){ return d.length })]);
    //
    //     let svg = d3.select(container)
    //         .append('svg')
    //         .attr("id", "map")
    //         .attr("viewBox", "0 0 1200 800");
    //
    //     let map = svg.append("g")
    //         .attr("transform", "translate(" + margin.left + ", " + margin.top + ")");
    //
    //     map.selectAll("path")
    //         .data(files[0].features)
    //         .enter()
    //         .append("path")
    //         .attr("d", path)
    //         .attr("class", "region");
    //
    //     map.append("g")
    //         .attr("class", "hexagons")
    //         .selectAll("path")
    //         .data(hexbin(df).sort(function (a, b) {
    //             return b.length - a.length;
    //         }))
    //         .enter()
    //         .append("path")
    //         .attr("d", function (d) { return hexbin.hexagon(); })
    //         .attr("class", "tip")
    //         .attr("transform", function (d) {
    //             return "translate(" + d.x + "," + d.y + ")";
    //         })
    //         .style("fill", function (d) {
    //             return colorScale(d.length);
    //         })
    //         .attr("data-tippy-content", function(d) {
    //             return tip + d.length
    //         });
    //     };

    //create_hex_map(files[2], "#hex_suspected", hex_Red, "К-ть осіб із підозрою: ", "new_susp");
    // create_hex_map(files[1], "#hex_confirmed", hex_Red, "К-ть діагностованих випадків: ", "new_confirm");
    // create_hex_map(files[2], "#hex_died", hex_Red, "Померло: ", "new_death");

    d3.selectAll(".spinner").remove();


    tippy('.tip', {
        arrow: false,
        arrowType: 'round',
        size: 'big',
        allowHTML: true
    });



   
});





