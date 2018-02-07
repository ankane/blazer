/*
 * Mapkick.js
 * Create beautiful maps with one line of JavaScript
 * https://github.com/ankane/mapkick.js
 * v0.0.1
 * MIT License
 */

/*jslint browser: true, indent: 2, plusplus: true, vars: true */

(function (window) {
  'use strict';

  var Mapkick = {
    Map: function (element, data, options) {
      var map;
      var routes = {};
      var groupedData = {};
      var timestamps = [];
      var timeIndex = 0;
      var bounds;

      function getJSON(element, url, success) {
        ajaxCall(url, success, function (jqXHR, textStatus, errorThrown) {
          var message = (typeof errorThrown === "string") ? errorThrown : errorThrown.message;
          // TODO show message
          console.log("ERROR: " + message);
        });
      }

      function ajaxCall(url, success, error) {
        var $ = window.jQuery || window.Zepto || window.$;

        if ($) {
          $.ajax({
            dataType: "json",
            url: url,
            success: success,
            error: error
          });
        } else {
          var xhr = new XMLHttpRequest();
          xhr.open("GET", url, true);
          xhr.setRequestHeader("Content-Type", "application/json");
          xhr.onload = function () {
            if (xhr.status === 200) {
              success(JSON.parse(xhr.responseText), xhr.statusText, xhr);
            } else {
              error(xhr, "error", xhr.statusText);
            }
          };
          xhr.send();
        }
      }

      function onMapLoad(callback) {
        if (map.loaded()) {
          callback();
        } else {
          map.on("load", callback);
        }
      }

      function toTimestamp(ts) {
        if (typeof ts === "number") {
          return ts;
        } else {
          return (new Date(ts)).getTime() / 1000;
        }
      }

      function generateReplayMap(element, data, options) {
        // group data
        for (var i = 0; i < data.length; i++) {
          var row = data[i];
          var ts = toTimestamp(row.time);
          if (ts) {
            if (!groupedData[ts]) {
              groupedData[ts] = [];
            }
            groupedData[ts].push(row);
            bounds.extend(rowCoordinates(row));
          }
        }

        for (i in groupedData) {
          if (groupedData.hasOwnProperty(i)) {
            timestamps.push(parseInt(i));
          }
        }
        timestamps.sort();

        // create map
        generateMap(element, groupedData[timestamps[timeIndex]], options);

        onMapLoad( function () {
          setTimeout(function () {
            nextFrame(element, options);
          }, 100);
        });
      }

      function nextFrame(element, options) {
        timeIndex++;

        updateMap(element, groupedData[timestamps[timeIndex]], options);

        if (timeIndex < timestamps.length - 1) {
          setTimeout(function () {
            nextFrame(element, options);
          }, 100);
        }
      }

      function fetchData(element, data, options, callback) {
        if (typeof data === "string") {
          getJSON(element, data, function (newData, status, xhr) {
            callback(element, newData, options);
          });
        } else if (typeof data === "function") {
          data( function (newData) {
            callback(element, newData, options);
          });
        } else {
          callback(element, data, options);
        }
      }

      function updateMap(element, data, options) {
        onLayersReady( function () {
          if (options.route) {
            recordRoutes(data, options.route);
            map.getSource("routes").setData(generateRoutesGeoJSON(data));
          }
          map.getSource("objects").setData(generateGeoJSON(data));
        });
      }

      function generateGeoJSON(data) {
        var geojson = {
          type: "FeatureCollection",
          features: []
        };

        for (var i = 0; i < data.length; i++) {
          var row = data[i];
          var properties = Object.assign({icon: "mapkick"}, row);
          geojson.features.push({
            type: "Feature",
            geometry: {
              type: "Point",
              coordinates: rowCoordinates(row),
            },
            properties: properties
          });
        }

        return geojson;
      }

      function rowCoordinates(row) {
        return [row.longitude || row.lng || row.lon, row.latitude || row.lat];
      }

      function routeId(row) {
        return row.id;
      }

      function recordRoutes(data, routeOptions) {
        for (var i = 0; i < data.length; i++) {
          var row = data[i];
          var route_id = routeId(row);
          if (!routes[route_id]) {
            routes[route_id] = [];
          }
          routes[route_id].push(rowCoordinates(row));
          if (routeOptions && routeOptions.limit && routes[route_id].length > routeOptions.limit) {
            routes[route_id].shift();
          }
        }
      }

      function generateRoutesGeoJSON(data) {
        var geojson = {
          type: "FeatureCollection",
          features: []
        };

        for (var i = 0; i < data.length; i++) {
          var row = data[i];
          geojson.features.push({
            type: "Feature",
            geometry: {
              type: "LineString",
              coordinates: routes[routeId(row)]
            }
          });
        }

        return geojson;
      }

      function addLayer(name, geojson) {
        map.addSource(name, {
          type: "geojson",
          data: geojson
        });

        map.addLayer({
          id: name,
          source: name,
          type: "symbol",
          layout: {
            "icon-image": "{icon}-15",
            "icon-allow-overlap": true,
            "text-field": "{label}",
            "text-size": 11,
            "text-anchor": "top",
            "text-offset": [0, 1],
            "text-allow-overlap": true
          }
        });

        // Create a popup, but don't add it to the map yet.
        var popup = new mapboxgl.Popup({
            closeButton: false,
            closeOnClick: false
        });

        map.on("mouseenter", name, function(e) {
          if (e.features[0].properties.tooltip) {
            // Change the cursor style as a UI indicator.
            map.getCanvas().style.cursor = "pointer";

            popup.options.offset = e.features[0].properties.icon === "mapkick" ? 40 : 14;

            // Populate the popup and set its coordinates
            // based on the feature found.
            popup.setLngLat(e.features[0].geometry.coordinates)
              .setText(e.features[0].properties.tooltip)
              .addTo(map);

            // fix blurriness for non-retina screens
            // https://github.com/mapbox/mapbox-gl-js/pull/3258
            if (popup._container.offsetWidth % 2 !== 0) {
              popup._container.style.width = popup._container.offsetWidth + 1 + "px";
            }
          }
        });

        map.on("mouseleave", name, function() {
          map.getCanvas().style.cursor = "";
          popup.remove();
        });
      }

      function generateMap(element, data, options) {
        var geojson = generateGeoJSON(data);
        options = options || {};

        geojson.features.forEach(function(feature) {
          bounds.extend(feature.geometry.coordinates);
        });

        map = new window.mapboxgl.Map({
            container: element,
            style: options.style || "mapbox://styles/mapbox/streets-v9",
            dragRotate: false,
            touchZoomRotate: false,
            center: options.center || bounds.getCenter(),
            zoom: options.zoom || 15
        });

        if (options.controls) {
          map.addControl(new mapboxgl.NavigationControl({showCompass: false}));
        }

        if (!options.zoom) {
          // hack to prevent error
          if (!map.style.stylesheet) {
            map.style.stylesheet = {};
          }
          map.fitBounds(bounds, {padding: 40, animate: false, maxZoom: 15});
        }

        onMapLoad( function () {
          if (options.route) {
            recordRoutes(data);

            map.addSource("routes", {
              type: "geojson",
              data: generateRoutesGeoJSON([])
            });

            map.addLayer({
              id: "routes",
              source: "routes",
              type: "line",
              layout: {
                "line-join": "round",
                "line-cap": "round"
              },
              paint: {
                "line-color": "#888",
                "line-width": 2
              }
            });
          }

          // TODO only load marker when needed
          // TODO allow other colors and sizes
          map.loadImage("https://a.tiles.mapbox.com/v4/marker/pin-m+f86767.png?access_token=" + window.mapboxgl.accessToken, function(error, image) {
            map.addImage("mapkick-15", image);

            addLayer("objects", geojson);

            layersReady = true;
            var cb;
            while ((cb = layersReadyQueue.shift())) {
              cb();
            }
          });
        });
      }

      var layersReady = false;
      var layersReadyQueue = [];
      function onLayersReady(callback) {
        if (layersReady) {
          callback();
        } else {
          layersReadyQueue.push(callback);
        }
      }

      // main

      options = options || {};
      bounds = new window.mapboxgl.LngLatBounds();

      if (options.replay) {
        fetchData(element, data, options, generateReplayMap);
      } else {
        fetchData(element, data, options, generateMap);

        if (options.refresh) {
          setInterval( function () {
            fetchData(element, data, options, updateMap);
          }, options.refresh * 1000);
        }
      }
    }
  };

  if (typeof module === "object" && typeof module.exports === "object") {
    module.exports = Mapkick;
  } else {
    window.Mapkick = Mapkick;
  }
}(window));
