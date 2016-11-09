/* Author: PowerRank
Modified M. Dickey 3/16/16
*/

/*jslint white: false, debug: false, devel: true, onevar: false, plusplus: false, browser: true, bitwise: false, maxerr: 200 */
/*global jQuery: false, $: false, log: false, window: false, WSJNG: false, _: false */

// Just in case there's a console.log hanging around.... neutralize it on weak browsers
if (!window.console) { window.console = { "log": function() {} }; }

var r = gRSize()*0.8;

var svg = d3.select("#"+the_div_name).append("svg")
    .attr("width", d3.select("#"+the_div_name).style("width"))
    .attr("height", d3.select("#"+the_div_name).style("width"))
    .style("background","#fff")
    .append("g")
    .attr("id", "bracket_viz")
    .attr("transform", "translate(" + (r) + "," + (r) + ") scale(1)");

//svg.append("circle").attr("r",r).style("fill",'red')

// label for BOTTOM RIGHT
svg.append("text").attr("class","region")
    .text("South")
    .attr("x", r*1.2)
    .attr("y", r*1) 
    .attr("text-anchor","middle")
    .style('font', '2.5em Gill Sans, sans-serif')
    .style('fill', '#e3e3f2')
   .style('font-weight','bold');

// label for TOP LEFT
svg.append("text").attr("class","region")
    .text("Midwest")
    .attr("x", -r*1.2)
    .attr("y", -r*1) 
    .attr("text-anchor","middle")
    .style('font', '2.5em Gill Sans, sans-serif')
    .style('fill', '#e3e3f2')
   .style('font-weight','bold');

// label for TOP RIGHT
svg.append("text").attr("class","region")
    .text("East")
    .attr("x", r*1.2)
    .attr("y", -r*1) 
    .attr("text-anchor","middle")
    .style('font', '2.5em Gill Sans, sans-serif')
    .style('fill', '#e3e3f2')
   .style('font-weight','bold');

// label for BOTTOM LEFT
svg.append("text")
    .text("West").attr("class","region")
    .attr("x", -r*1.2)
    .attr("y", r*1) 
    .attr("text-anchor","middle")
   .style('font', '2.5em Gill Sans, sans-serif')
    .style('fill', '#e3e3f2')
   .style('font-weight','bold');

function Team(name) {
    this.name = name;
    this.seed = 0;
    this.region = 0; 
	this.color = "";
    this.probs = []; // prob of making it to each game
    this.stillin = 1; // is team still in tournament?
}

function Game(num, flag) {
    this.name = num;
    this.region = 0;
    this.teams = [];     // possible teams playing in this game
    this.prevGames = []; // parent games
    this.played = flag;  // has the game been played?
}

function isDefined(element, index, array) {
    return (element != undefined);        
}

function hasValue(element, index, array) {
    if (element > 0) {
        return 1;
    } else {
        return 0;
    }
}

// recursively create the tree structure so D3 can display it correctly
function travelTree(onegame) {
    //document.write(onegame.name);
    var returnArray = [];
    var h;
    // figure out all the child games first
    if (onegame.prevGames.length > 0) {
            onegame.prevGames.forEach(function (g) {
            //document.write("-->");
            h = new Object();
            h.name = g.name;
            h.children = travelTree(g);
            h.teams = g.teams;
            h.region = g.region;
            h.played = g.played;
            returnArray.push(h);
        });
    } 
    // in the first round, some games are not symmetric, so need to allow
    // for specifying a team as a child
    if (onegame.prevGames.length < 2) {
        onegame.teams.forEach(function (t){
            if (t.probs[onegame.name] >0) {
                var skipThis = false;
                if (onegame.prevGames.length == 1) {
                    onegame.prevGames[0].teams.forEach(function (t2) {
                        if (t2.name == t.name) {
                            skipThis = true;
                        }
                    });
                }
                if (!skipThis) {
                    h = new Object();
                    h.name = t.name;
                    h.children = [];
					h.color = t.color;
                    h.stillin = t.stillin;
                    h.probs = t.probs;
                    h.seed = t.seed;
                    h.region = t.region;
                    returnArray.push(h);
                }
            } 
            })
    } 
    return returnArray;

}

function parseCSV(onerow, rowindex) {            
    if (rowindex == 0){
        // first row has all the teams
        onerow.forEach(function(oneteam, teamindex){
            if (teamindex > 0) {  // ignore entry one
                allTeams.push(new Team(oneteam)); 
            }
        });
    } else if (rowindex == 1) {
        // second row is each team's color
        onerow.forEach(function (onecolor, teamindex) {
            if (teamindex > 0) {  // ignore entry one
                allTeams[teamindex-1].color = onecolor;
            }
        });
    }else if (rowindex == 2) {
        // third row is each team's seed
        onerow.forEach(function (oneseed, teamindex) {
            if (teamindex > 0) {  // ignore entry one
                allTeams[teamindex-1].seed = oneseed;
            }
        });
    } else if (rowindex == 3) {
        // fourth row is each team's regions
        onerow.forEach(function (oneregion, teamindex) {
            if (teamindex > 0) {  // ignore entry one
                allTeams[teamindex-1].region = oneregion;
            }
        });
    } else if (rowindex == 4) {
        // fifth row indicates if a team is still in the tournament
        onerow.forEach(function (oneflag, teamindex) {
            if (teamindex > 0) {  // ignore entry one
                allTeams[teamindex-1].stillin = oneflag;
            }
        });                
    } else {
        realrowindex = rowindex-5;
        // all other rows are games
        onerow.forEach(function(oneprob, teamindex) {

            if (teamindex == 0) { // first entry is the played flag
                allGames.push(new Game(realrowindex, oneprob));
            } else {
                var thisTeam = allTeams[teamindex-1];
                var thisGame = allGames[allGames.length-1];
                if (oneprob > 0) {
                    thisGame.teams.push(thisTeam);
                    // find this game's ancestors
                    var lastGame = thisTeam.probs.map(hasValue).lastIndexOf(1);
                    if (lastGame > -1) {
                        if (thisGame.prevGames.length == 0) {
                            thisGame.prevGames.push(allGames[lastGame]);
                        } else {
                            var addThis = true;
                            thisGame.prevGames.forEach(function (g) {
                                if (allGames[lastGame] == g) {
                                    addThis = false;
                                }
                            });
                            if (addThis) {
                                thisGame.prevGames.push(allGames[lastGame]);
                            }

                        }
                    }
                }                    
                thisTeam.probs[realrowindex] = oneprob;   
            }
        });
    }
}
function padWithSpace(num) {
    if (num < 10) {
        return " " + num.toString();
    } else {
        return num.toString();        
    }
}

// for debugging purposes
function printTree(node) {
    if (node.children.length > 0) {
        document.writeln(" { name = " + node.name + ",");
        document.write("   children (" + node.children.length + ") = [<br>    ");
        node.children.forEach(function (c) {
            printTree(c);
            document.write(",");                
        });
        document.write("] } <br>");            
    } else {
        document.writeln("{ name = " + node.name + "}");
    }

}

function teamover(t) {

	// Running the below makes all links weighted and colored according to a team's data
	// ^ We'll need to restrict this to the links we want.
	//d3.selectAll("path.link")
	//	.transition().duration(100).style("stroke", function(){return t.color}).style("stroke-width",2+t.probs[1]*2)

		
		
    d3.select(this).selectAll("text")
        .transition().duration(100).attr("fill","#000").style("font-weight", "bold");	
	
    svg.selectAll("g.futuregame").select("circle")
        .transition().duration(100)
        .attr("r",5)   // this is in case you roll from one team to next w/o activating teamout
        .style("fill","#ccc").style("stroke","#ccc");

    t.probs.forEach(function (p, gameindex) {
        if (p>0) {
            if (allGames[gameindex].played==0) {
            svg.selectAll("g.g"+gameindex).select("circle")
                .transition().duration(100)
                .attr("r",10)
                .style("fill",function(){return t.color}).style("stroke","#000");
            svg.selectAll("g.g"+gameindex).append("text")
                .text((Math.round(p*1000)/10)+"%")
                .attr("class", "prob")
                .attr("x", 10)
                .attr("y", -15)
                .style("text-anchor", "middle")
                .attr("transform", function(z) {return "rotate(" + (90-z.x) + ")"; })
                .style("fill","000")
                .style("font-size","1.2em")
				.style("font-weight","bold");  
            }
        }        
    })
    
	// To do #2: add to teamover() function, a function to select all nodes
    // selectAll("g.g"+linkindex) and apply what I want it to look like
	
	// list of all game indices for a team
	var gamedict = {};
	var count = 1;
	gamedict[1] = t.name.toLowerCase().replace(/\W/g,"_");
	t.probs.forEach(function(p,gameindex){
		if(p>0){
			count = count + 1;
			gamedict[count] = gameindex;
		};
	});
	
	count = 1;
	t.probs.forEach(function (p, gameindex) {
		if (p>0) {
            svg.selectAll("path.link"+gamedict[count+1]+gamedict[count])
                .transition().duration(100)
                .style("stroke",function(){return t.color}).style("stroke-width", 2+25*p+"px");
			count = count + 1
        }
    })
}

function teamout(t,i){
    d3.select(this).selectAll("text")
        .transition().duration(100).attr("fill","#aaa").style("font-weight", "normal");;
    
	d3.selectAll("path")
		.transition().duration(100).style("stroke","#ddd").style("stroke-width","2px")
	
    svg.selectAll("g.futuregame").select("circle")
        .transition().duration(100)
        .attr("r",5)
        .style("fill","#99c").style("stroke","#99c");
    
    t.probs.forEach(function (p, gameindex) {
        if (p>0) { 
            svg.selectAll("g.g"+gameindex).select("text.prob").remove();
            
        }   
    });

}
function gameover(d, i) {
    // find the maximum probability to color it differently
	var probArray = [];
	d.teams.forEach(function (t) {
		probArray.push(Math.round(t.probs[d.name]*1000)/10);
	});
	var maxProb = Math.max.apply( Math, probArray );
	
	svg.selectAll("g.futuregame").select("circle")
        .transition().duration(100)
        .attr("r",5)   // this is in case you roll from one team to next w/o activating teamout
        .style("fill","#ccc").style("stroke","#ccc");

    d3.select(this)
    .transition().duration(100)
    .attr("r",10)
    .style("stroke", "black").style("stroke-width", "2px");   
	
    d.teams.forEach(function (t) {
        if (t.stillin==1) {
			if((Math.round(t.probs[d.name]*1000)/10) != maxProb){
				var nameText = svg.selectAll("g."+t.name.toLowerCase().replace(/\W/g,"_"))
					.selectAll("text")
					.transition().duration(100).attr("fill", "#000");
				svg.selectAll("g."+t.name.toLowerCase().replace(/\W/g,"_"))
					.append("text")
					.attr("class", "prob")
					.text((Math.round(t.probs[d.name]*1000)/10)+"%")
					.attr("x", function(d) { return d.x < 180 ? 10 : -10; })
					.attr("y",10)
					.style("text-anchor", function(z) { return z.x < 180 ? "end" : "start"; })
					.attr("transform", function(z) { 
					   
						return z.x < 180 ? null : "rotate(180)"; })                
					.style("fill","#A9A9A9")
					.style("font-size","1.2em");
			}
			if((Math.round(t.probs[d.name]*1000)/10) == maxProb){
				var nameText = svg.selectAll("g."+t.name.toLowerCase().replace(/\W/g,"_"))
					.selectAll("text")
					.transition().duration(100).attr("fill", "#000")
												.style("font-weight", "bold");
				svg.selectAll("g."+t.name.toLowerCase().replace(/\W/g,"_"))
					.append("text")
					.attr("class", "prob")
					.text((Math.round(t.probs[d.name]*1000)/10)+"%")
					.attr("x", function(d) { return d.x < 180 ? 10 : -10; })
					.attr("y",10)
					.style("text-anchor", function(z) { return z.x < 180 ? "end" : "start"; })
					.attr("transform", function(z) { 
					   
						return z.x < 180 ? null : "rotate(180)"; })                
					.style("fill",function(){return t.color})
					.style("font-size","1.3em")
					.style("font-weight","bold");
			}
        }
    });

}
function gameout(d, i) {
    svg.selectAll("g.futuregame").select("circle")
        .transition().duration(100)
        .attr("r",5)
        .style("fill","#99c").style("stroke","#99c");

    d3.select(this)
    .transition().duration(100)
    .attr("r",5)
    .style("stroke", "#99c").style("stroke-width", "2px");

    d.teams.forEach(function (t) {
        if (t.stillin ==1) {
            svg.selectAll("g."+t.name.toLowerCase().replace(/\W/g,"_"))
                    .selectAll("text")
                    .transition().duration(100).attr("fill", "#aaa")
												.style("font-weight", "normal");
            svg.selectAll("g."+t.name.toLowerCase().replace(/\W/g,"_"))
                    .select("text.prob").remove();
        }
    });       
}

// START MAIN JS STUFF
//
// these will hold the teams/games as they are being parsed from CSV
var allTeams = [];
var allGames = [];

// read in CSV file and parse each row
d3.text(the_file_name, function(data) {        

    // save the CSV data as objects in allTeams and allGames
    var rows = d3.csv.parseRows(data);
	console.log(rows)
    rows.forEach(parseCSV); 

    // generate tree structure from the data that was read in
    var finalgame = allGames[allGames.length-1];
    var gameTree = new Object();
    gameTree.name = finalgame.name;
    gameTree.children = travelTree(finalgame);
    gameTree.teams = allTeams;
    gameTree.played = finalgame.played;

	//console.log(gameTree);

    // time to visualize!
    var tree = d3.layout.tree()
        .size([360, r])
        .separation(function(a, b) { 
            if (a.region != b.region) {
                return 1;
            } else {
                return (a.parent == b.parent ? 3 : 3) / a.depth; 
            }   
        });

    var diagonal = d3.svg.diagonal.radial()
        .projection(function(d) { return [d.y+5,  d.x / 180 * Math.PI]; });

    var nodes = tree.nodes(gameTree);
    var links = tree.links(nodes);

	
	// #1: set a class name for each link (source, target)... CHECK!
    var drawlink = svg.selectAll("path.link")
        .data(links)
        .enter()
        .append("path")
        .attr("class", function(d){
						if(isNaN(Number(d.target.name))){
							console.log(d.target.name.toLowerCase().replace(/\W/g,"_"))
							return "link" + d.source.name + d.target.name.toLowerCase().replace(/\W/g,"_")}
						else{return "link" + d.source.name + d.target.name}
						})
        .style("fill","none")
        .style("stroke","#ddd")
        .style("stroke-width","2px")
        .attr("d", diagonal);

    var drawnode = svg.selectAll("g.node")
    .data(nodes)
    .enter().append("g")
    .attr("class","node")
    .attr("transform", function(d) { return "rotate(" + (d.x-90) + ")translate(" + d.y + ")"; });

    var playedGameNodes = drawnode.filter(function (d) {
        return ((typeof(d.name) == "number") && (d.played==1));       
    });

    var futureGameNodes = drawnode.filter(function (d) {
        return ((typeof(d.name) == "number") && (d.played==0));       
    });

    var teamInNodes = drawnode.filter(function (d) {
        return ((typeof(d.name) == "string") && (d.stillin==1));       
    });

    var teamOutNodes = drawnode.filter(function (d) {
        return ((typeof(d.name) == "string") && (d.stillin==0));       
    });
    
    var teamNodes = drawnode.filter(function (d) {
        return (typeof(d.name) == "string");       
    });

    playedGameNodes.attr("class", function(d) {return "node playedgame g" + d.name;})
        .append("circle").attr("r",3)
        .style("stroke", "#ccc").style("stroke-width", "2px")
        .style("fill", "#fff");

    futureGameNodes.attr("class", function(d) {return "node futuregame g" + d.name;})
        .append("circle").attr("r",5)            
        .style("stroke", "#99c").style("stroke-width", "2px")
        .style("fill", "#99c")
        .on("mouseover", gameover)
        .on("mouseout", gameout);

    teamNodes
    .attr("class", function (d) { return "node team " + d.name.toLowerCase().replace(/\W/g,"_"); })
    .append("text")
    .attr("x", function(d) { return d.x < 180 ? 40 : -40; })
    .attr("y", 10) 
    .attr('class','team_labels')
    .style('cursor','pointer')
    .style('font', '1.4em Gill Sans, sans-serif')
    .attr("text-anchor", function(d) { return d.x < 180 ? "start" : "end"; })
    .attr("transform", function(d) { return d.x < 180 ? null : "rotate(180)"; })
    .text(function(d) { return d.name; });
    
    teamNodes
    .append("text")
    .attr("x", function(d) { return d.x < 180 ? 25 : -25; })
    .attr("y", 10) 
    .attr("text-anchor", "middle")
    .style('cursor','pointer')
    .style('font', '1.4em Gill Sans, sans-serif')
   .attr("transform", function(d) { return d.x < 180 ? null : "rotate(180)"; })
    .text(function(d) { return d.seed; });
    
    teamInNodes.selectAll("text")
    .attr("fill", "#aaa");
        
    teamOutNodes.selectAll("text")
    .attr("fill", "#ddd").style("text-decoration","none");
    
    teamInNodes
    .on("mouseover", teamover)
    .on("mouseout", teamout);
    
   	$(window).resize(function() {
		checkSizes();
	});
	checkSizes();
    
    
    
});

function gRSize(){
	return (parseInt(d3.select("#"+the_div_name).style("width"))-0)/2;
}

function checkSizes(){
	
	var longestLabel = 0;
	d3.selectAll('.team_labels').each(function(d){
		longestLabel = Math.max(longestLabel, d.y+d3.select(this).node().getBBox().width+12);
	})	
	r = gRSize();
		
	d3.select("#bracket_viz").attr("transform", "translate(" + (r) + "," + (r) + ") scale(" + Math.abs(r/longestLabel) + ")")
	
}