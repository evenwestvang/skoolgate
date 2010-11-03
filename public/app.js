/* Inits */

var map = null;
var currentInfoBox = null;

function initialize() {
  jQuery.event.add(window, "resize", resizeFrame);
  CFInstall.check({
     mode: "overlay",
     destination: "http://skoleporten.bengler.no"
   });
   initMaps();
}

function resizeFrame() {
    $("#map_canvas").css('height',$(window).height());
}

/* Maps */

function initMaps() {
  var latlng = new google.maps.LatLng(59.86176086468102, 10.75612752648925);
  var myOptions = {
    zoom: 11,
    center: latlng,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    mapTypeControl: false,
    navigationControlOptions: { 
      style: google.maps.NavigationControlStyle.DEFAULT}
  };
  map = new google.maps.Map(document.getElementById("map_canvas"),
      myOptions);
  var styledMap = new google.maps.StyledMapType(
      style);
  map.mapTypes.set('styled', styledMap);
  map.setMapTypeId('styled');
  var markerKeeper = new MarkerKeeper(map);
}

function MarkerKeeper() {
  var markers = new Array;
  var markerHash = new Object;
  var previousQueryTime = new Date().getTime();
  var showPrimaries = true;
  var showSecondaries = true;
  var detailLevel = 0;

  this.map = map;

  google.maps.event.addListener(this.map, "click", function() {
    closeAnyInfoboxes();
  });
  google.maps.event.addListener(this.map, "drag", function() {
    getMarkersForBounds();
  });
  google.maps.event.addListener(this.map, "idle", function() {
    getMarkersForBounds(true);
  });
  google.maps.event.addListenerOnce(this.map, "tilesloaded", function() {
    getMarkersForBounds();
  });
  google.maps.event.addListener(this.map, "zoom_changed", function() {
    closeAnyInfoboxes();
    zoomChanged();
  });

  function closeAnyInfoboxes() {
    if (currentInfoBox != undefined) {
      currentInfoBox.close();
      currentInfoBox = undefined;
    }
  }

  function addMarker(marker) {
    marker.setMap(this.map);  
    markers.push(marker);
    markerHash[marker.ident] = true
  }

  function cullAllMarkers() {
    markers = markers.filter(function(m) {
      deleteMarker(m);
    });
  }

  function cullMarkersByBounds() {
    var bounds = this.map.getBounds();
    markers = markers.filter(function(m) {
      if (!bounds.contains(m.position)) {
        deleteMarker(m);
        return false
      }
      return true
    });
  }

  function deleteMarker(marker) {
    marker.setMap(null);
    delete markerHash[marker.ident];
  }

  function updateViewStats() {
    disp_list = new Array
    if (detailLevel == 0) {
      if (showPrimaries) disp_list.push("barneskoler");
      if (showSecondaries) disp_list.push("ungdomsskoler");
    } else {
      disp_list.push("kommuner");
    }
    s = "Viser " + markers.length + " " + disp_list.join(' og ')
    $('#view_stats').text(s);
  }

  function zoomChanged() {
    zoom = map.getZoom();
    previous_level = detailLevel;
    if (zoom < 9) {
      detailLevel = 1;
    } else {
      detailLevel = 0;
    }
    if (detailLevel != previous_level) {
      cullAllMarkers();
      if (detailLevel == 1) {
        $('.header_search_ui').addClass('less_details');
      } else {
        $('.header_search_ui').removeClass('less_details');        
      }
    }
    getMarkersForBounds();
  }

  function getMarkersForBounds(force) {
    cullMarkersByBounds()
    var current_time = new Date().getTime();
    if (current_time - this.previousQueryTime < 600 && !force) return;
    this.previousQueryTime = current_time;
    var bounds = this.map.getBounds();
    queryPack = [bounds.getSouthWest().lat(), bounds.getSouthWest().lng(), 
                 bounds.getNorthEast().lat(), bounds.getNorthEast().lng(),
                 detailLevel].join('/');
    $.getJSON('/get_markers/' + queryPack, function(data, textStatus) {
      $(data).each(function(i, item) {
        if (markerHash[item.id] == undefined) {
          var size = Math.ceil((item.body / 25)+11);
          if (detailLevel != 0) {
            size = (size / 25) + 10;
          }
          var latlng = new google.maps.LatLng(item.lat, item.lon);
          var icon_url = ButtonFactory.create(item.avg, size);
          var image = new google.maps.MarkerImage(icon_url, 
            new google.maps.Size(size, size),
            new google.maps.Point(0, 0),
            new google.maps.Point(size/2, size/2)
          );
          var marker = new google.maps.Marker({
                ident: item.id,
                position: latlng,
                title: item.name,
                icon: image
            });
          addMarker(marker);
          google.maps.event.addListener(marker, 'click', function() {
            markerClicked(map,marker);
          });
        }
      }); 
    updateViewStats();
    });
  };
  return { 
  }

  function markerClicked(map, marker) {
    var boxText = document.createElement("div");
    // We should probably insert this into the the DOM through sass and read it from there
    boxText.style.cssText = "border: 1px solid black;margin-top: 8px; background: black; padding: 5px; border-radius:3px; -moz-border-radius:3px; webkit-border-radius:3px; -moz-box-shadow #000 5px 5px 10px; -webkit-box-shadow #000 5px 5px 10px; box-shadow #000 5px 5px 10px;";
    // Offloading server. Doing all processing client side
    $.getJSON('/marker_info/' + marker.ident, function(data, textStatus) {

      var primarySchoolTests = new Array
      var secondarySchoolTests = new Array

      $(data.test_results).each(function(i,result) {
        if (result.school_year == 5) {
          primarySchoolTests.push(result); 
        } else {
          secondarySchoolTests.push(result); 
        }
      });
      var yearNames = []
      if (primarySchoolTests.length > 0) {
        yearNames.push ("Barneskole")
      } 
      if (secondarySchoolTests.length > 0) {
        yearNames.push ("Ungdomsskole")
      }
      data.level_name = yearNames.join(' og ');
      
      infoBox = $("#schoolInfoBoxTemplate").tmpl(data).appendTo($(boxText));
      test_sets = [primarySchoolTests, secondarySchoolTests];
      $(test_sets).each(function(i, set) {
        if (set.length > 0) {
          set_node = $("#schoolInfoBoxTemplateTestSet").tmpl({year: set[0].school_year}).appendTo(infoBox);
          $(set).each(function(i,result) {
            if(result.school_year == 5) {
              result.max_score = 3;
            } else if (result.school_year == 8) {
              result.max_score = 5;
            }
            if (result.normalized_result == undefined) {
              result.normalized_result = 0;
              result.result = 0;
            }
            result.percentage = result.normalized_result * 100;
            result.humanizedTestCode = humanizeTestCode(result.test_code);
            $("#schoolInfoBoxTemplateTest").tmpl(result).appendTo($(set_node));
          })
        };
      })
    });

    closeAnyInfoboxes();
    infoBoxOptions.content = boxText;
    currentInfoBox = new InfoBox(infoBoxOptions);                
    currentInfoBox.open(map, marker);
  }

  function humanizeTestCode(test_code) {
    if (test_code.match('REG')) { return "regning" };
    if (test_code.match('LES')) { return "lesning" };
    if (test_code.match('ENG')) { return "engelsk" };
  }

};

var ButtonFactory = (function() {
  return new function() {
    var h = 1;
    var s = 100;
    var l = 45;
    var a = 0.8;

    var getColor = function(val) {
      return "hsla(" + val +"," + s + "%," + l +"%," + a +")";
    };

    var getColor1 = function(val) {
      return "hsla(" + val +"," + s + "%," + (l*0.75) +"%," + a +")";
    };

    // draws a rounded rectangle
    var drawRect = function(context, x, y, width, height, size) {
      var radius = 5
      width = height = size;
      context.beginPath();
      context.moveTo(x + radius, y);
      context.lineTo(x + width - radius, y);
      context.quadraticCurveTo(x + width, y, x + width, y + radius);
      context.lineTo(x + width, y + height - radius);
      context.quadraticCurveTo(x + width, y + height, x + width -
      radius, y + height);
      context.lineTo(x + radius, y + height);
      context.quadraticCurveTo(x, y + height, x, y + height - radius);
      context.lineTo(x, y + radius);
      context.quadraticCurveTo(x, y, x + radius, y);
      context.closePath();
    }

    this.createCanvas = function(t, size) {
      var canvas = document.createElement("canvas");
      canvas.width = size;
      canvas.height = size;
      var context = canvas.getContext("2d");
      if(t != 0 && t != undefined) {
        var t = t - 0.5
        var log_curve = (1 / (1 + Math.pow(Math.E,-t))) - 0.5
        var color_val = 40 + (log_curve * 700) 
        var color0 = getColor(color_val);
        var stroke = getColor1(color_val);
      } else {
        var color0 = "Silver";
        var stroke = "rgba(100,100,100,1)"
      }
      context.clearRect(0,0,size,size);
      context.fillStyle = color0;
      context.strokeStyle = stroke;
      drawRect(context, 0, 0, size, size, size);
      context.fill();
      context.stroke();
      return canvas;
    };

    this.create = function(label, range) {
      var canvas = this.createCanvas(label, range);
      return canvas.toDataURL();
    };
  }
})();

// Config hashes

var infoBoxOptions = {
  disableAutoPan: false,
  maxWidth: 0,
  pixelOffset: new google.maps.Size(-140, 10),
  zIndex: 0,
  boxStyle: {
    opacity: 1,
    width: "340px"
   },
  closeBoxMargin: "10px 2px 2px 2px",
  closeBoxURL: "http://www.google.com/intl/en_us/mapfiles/close.gif",
  infoBoxClearance: new google.maps.Size(1, 1),
  isHidden: false,
  pane: "floatPane",
  enableEventPropagation: false
};

var style = [
  {
    featureType: "landscape",
    elementType: "all",
    stylers: [
      { visibility: "simplified" },
      { saturation: -98 },
      { lightness: -58 },
      { gamma: 0.73 }
    ]
  },{
    featureType: "water",
    elementType: "all",
    stylers: [
      { visibility: "on" },
      { hue: "#0091ff" },
      { saturation: -52 },
      { lightness: -47 }
    ]
  },{
    featureType: "road",
    elementType: "all",
    stylers: [
      { visibility: "on" },
      { lightness: -59 },
      { gamma: 0.84 },
      { saturation: -99 }
    ]
  },{
    featureType: "road",
    elementType: "labels",
    stylers: [
      { visibility: "off" },
      { saturation: -100 }
    ]
  },{
    featureType: "poi",
    elementType: "all",
    stylers: [
      { visibility: "off" }
    ]
  },{
    featureType: "administrative",
    elementType: "labels",
    stylers: [
      { visibility: "on" },
      { gamma: .5 },
      { saturation: -24 },
      { lightness: -51 }
    ]
  },{
    featureType: "transit",
    elementType: "all",
    stylers: [
      { visibility: "off" }
    ]
  }
]
