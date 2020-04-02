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

var chr_Red = d3.scaleLinear()
    .domain([0, 100])
    .range(["white", "red"]);

var chr_Orange = d3.scaleLinear()
    .domain([0, 200])
    .range(["white", "gold"]);

// var chr_Orange = d3.scaleOrdinal(d3.schemeOranges[5]);

var hex_Red = d3.scaleLinear()
    .domain([0, 10])
    .range(["white", "red"]);

var hex_Orange = d3.scaleLinear()
    .domain([0, 100])
    .range(["white", "gold"]);

var colorBlack = d3.scaleLinear()
    .domain([0, 10])
    .range(["white", "black"]);


Promise.all([
    d3.json("data/ukr_adm1_lite.json"),
    d3.csv("data/ukraine/confirmed.csv"),
    d3.csv("data/ukraine/suspected.csv"),
    d3.csv("data/ukraine/dead.csv"),
    d3.csv("data/ukraine/by_regions.csv")
]).then(function(files) {

    var regions = [];
    files[4].forEach(function (d) {
        regions.push(d.region)
    });


    const create_choropl_map = function(container, column, colorScale, tip) {

        var main_map = d3.select(container)
            .append('svg')
            .attr("id", "map")
            .attr("viewBox", "0 0 1200 800")
            .append("g")
            .attr("transform", "translate(" + margin.left + ", " + margin.top + ")");

        main_map.selectAll("path")
            .data(files[0].features)
            .enter()
            .append("path")
            .attr("class", "tip")
            .attr("d", path)
            .attr("fill", function (d) {
                var colorValue = files[4].filter(function (k) {
                    return k.region === d.properties.region_name;
                });
                if (colorValue.length > 0) {
                    return colorScale(colorValue[0][column])
                } else {
                    return "white"
                }
            })
            .attr("data-tippy-content", function(d) {
                var colorValue = files[4].filter(function (k) {
                    return k.region === d.properties.region_name;
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

    create_choropl_map("#ch_suspected", "suspected", chr_Orange, "К-ть осіб із підозрою: ");
    create_choropl_map("#ch_confirmed", "confirmed", chr_Red, "К-ть діагностованих випадків: ");
    create_choropl_map("#ch_died", "deaths", colorBlack, "Померло: ");



    const create_hex_map = function(df, container, colorScale, tip, colname) {
        df.forEach(function (d) {
            d[1] = +d.lat;
            d[0] = +d.lon;
            var p = projection(d);
            d[0] = p[0], d[1] = p[1];
        });

        var map = d3.select(container)
            .append('svg')
            .attr("id", "map")
            .attr("viewBox", "0 0 1200 800")
            .append("g")
            .attr("transform", "translate(" + margin.left + ", " + margin.top + ")");

        map.selectAll("path")
            .data(files[0].features)
            .enter()
            .append("path")
            .attr("d", path)
            .attr("class", "region");

        map.append("g")
            .attr("class", "hexagons")
            .selectAll("path")
            .data(hexbin(df).sort(function (a, b) {
                return b.length - a.length;
            }))
            .enter().append("path")
            .attr("d", function (d) {
                return hexbin.hexagon();
            })
            .attr("class", "tip")
            .attr("transform", function (d) {
                return "translate(" + d.x + "," + d.y + ")";
            })
            .style("fill", function (d) {
                return colorScale(d.length);
            })
            .attr("data-tippy-content", function(d) {
                let hosp = [];
                d.forEach(function(k){
                    if(k.hospital_name != "самоізоляція"){
                        if(!hosp.includes(k.hospital_name)){
                            hosp.push(k.hospital_name);
                        }

                    } else {
                        if(!hosp.includes(k.hospital_id)) {
                            hosp.push(k.hospital_id);
                        }
                    }

                });
                
                return hosp;

            })
            .on("click",  function(d) {
                console.log(d);
                for(var i = 0; i < d.length; i++){
                  console.log(d[i].hospital_name + ": " + d[i][colname])
                }
            });
        };

    create_hex_map(files[2], "#hex_suspected", hex_Orange, "К-ть осіб із підозрою: ", "suspected");
    create_hex_map(files[1], "#hex_confirmed", hex_Red, "К-ть діагностованих випадків: ", "confirmed");
    create_hex_map(files[3], "#hex_died", colorBlack, "Померло: ", "deaths");

    tippy('.tip', {
        arrow: false,
        arrowType: 'round',
        size: 'big',
        allowHTML: true
    });



   
});





