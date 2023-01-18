/*
 * Mapkick.js v0.2.0
 * Create beautiful, interactive maps with one line of JavaScript
 * https://github.com/ankane/mapkick.js
 * MIT License
 */

(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.Mapkick = factory());
})(this, (function () { 'use strict';

  function getElement(element) {
    if (typeof element === "string") {
      var elementId = element;
      element = document.getElementById(element);
      if (!element) {
        throw new Error("No element with id " + elementId)
      }
    }
    return element
  }

  function createMarkerImage(library, color) {
    // set height to center vertically
    var height = 71;
    var width = 27;
    var scale = 2;

    // get marker svg
    var svg = (new library.Marker())._element.querySelector("svg");

    // make displayable and center vertically
    svg.removeAttribute("display");
    svg.setAttribute("xmlns", "http://www.w3.org/2000/svg");
    svg.setAttribute("height", height);
    svg.setAttribute("width", width);
    svg.setAttribute("viewBox", ("0 0 " + width + " " + height));

    // check for hex or named color
    if (!/^#([0-9a-f]{3}){1,2}$/i.test(color) && !/^[a-z]+$/i.test(color)) {
      throw new Error("Invalid color")
    }

    // set color
    svg.querySelector("*[fill='#3FB1CE']").setAttribute("fill", color);

    // add border to inner circle
    var circles = svg.querySelectorAll("circle");
    var circle = circles[circles.length - 1];
    if (circles.length == 1) {
      // need to insert new circle for mapbox-gl v2
      var c = circle.cloneNode();
      c.setAttribute("fill", "#000000");
      c.setAttribute("opacity", 0.25);
      circle.parentNode.insertBefore(c, circle);
    }
    circle.setAttribute("r", 4.5);

    // create image
    var image = new Image(width * scale, height * scale);
    image.src = "data:image/svg+xml;utf8," + (encodeURIComponent(svg.outerHTML));
    return image
  }

  var maps = {};

  var Map = function Map(element, data, options) {
    var this$1$1 = this;

    if (!Mapkick.library && typeof window !== "undefined") {
      Mapkick.library = window.mapboxgl || window.maplibregl || null;
    }

    var library = Mapkick.library;
    if (!library) {
      throw new Error("No mapping library found")
    }

    var map;
    var trails = {};
    var groupedData = {};
    var timestamps = [];
    var timeIndex = 0;

    element = getElement(element);

    if (element.id) {
      maps[element.id] = this;
    }

    function getJSON(element, url, success) {
      var xhr = new XMLHttpRequest();
      xhr.open("GET", url, true);
      xhr.setRequestHeader("Content-Type", "application/json");
      xhr.onload = function () {
        if (xhr.status === 200) {
          success(JSON.parse(xhr.responseText));
        } else {
          showError(element, xhr.statusText);
        }
      };
      xhr.send();
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
        return ts
      } else {
        return (new Date(ts)).getTime() / 1000
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

      for (var i$1 in groupedData) {
        if (Object.prototype.hasOwnProperty.call(groupedData, i$1)) {
          timestamps.push(parseInt(i$1));
        }
      }
      timestamps.sort();

      // create map
      generateMap(element, groupedData[timestamps[timeIndex]], options);

      onMapLoad(function () {
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

    function showError(element, message) {
      element.textContent = message;
    }

    function fetchData(element, data, options, callback) {
      if (typeof data === "string") {
        getJSON(element, data, function (newData) {
          callback(element, newData, options);
        });
      } else if (typeof data === "function") {
        try {
          data(function (newData) {
            callback(element, newData, options);
          }, function (message) {
            showError(element, message);
          });
        } catch (err) {
          showError(element, "Error");
          throw err
        }
      } else {
        callback(element, data, options);
      }
    }

    function updateMap(element, data, options) {
      onLayersReady(function () {
        if (options.trail) {
          recordTrails(data, options.trail);
          map.getSource("trails").setData(generateTrailsGeoJSON(data));
        }
        map.getSource("objects").setData(generateGeoJSON(data, options));
      });
    }

    function generateGeoJSON(data, options) {
      var geojson = {
        type: "FeatureCollection",
        features: []
      };

      for (var i = 0; i < data.length; i++) {
        var row = data[i];
        var properties = Object.assign({}, row);

        if (!properties.icon) {
          properties.icon = options.defaultIcon || "mapkick";
        }
        properties.mapkickIconSize = properties.icon === "mapkick" ? 0.5 : 1;

        geojson.features.push({
          type: "Feature",
          id: i,
          geometry: {
            type: "Point",
            coordinates: rowCoordinates(row),
          },
          properties: properties
        });
      }

      return geojson
    }

    function rowCoordinates(row) {
      return [row.longitude || row.lng || row.lon, row.latitude || row.lat]
    }

    function getTrailId(row) {
      return row.id
    }

    function recordTrails(data, trailOptions) {
      for (var i = 0; i < data.length; i++) {
        var row = data[i];
        var trailId = getTrailId(row);
        if (!trails[trailId]) {
          trails[trailId] = [];
        }
        trails[trailId].push(rowCoordinates(row));
        if (trailOptions && trailOptions.len && trails[trailId].length > trailOptions.len) {
          trails[trailId].shift();
        }
      }
    }

    function generateTrailsGeoJSON(data) {
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
            coordinates: trails[getTrailId(row)]
          }
        });
      }

      return geojson
    }

    function addLayer(name, geojson) {
      map.addSource(name, {
        type: "geojson",
        data: geojson
      });

      // use a symbol layer for markers for performance
      // https://docs.mapbox.com/help/getting-started/add-markers/#approach-1-adding-markers-inside-a-map
      map.addLayer({
        id: name,
        source: name,
        type: "symbol",
        layout: {
          "icon-image": "{icon}-15",
          "icon-allow-overlap": true,
          "icon-size": {type: "identity", property: "mapkickIconSize"},
          "text-field": "{label}",
          "text-size": 11,
          "text-anchor": "top",
          "text-offset": [0, 1],
          "text-allow-overlap": true
        }
      });

      var hover = !("hover" in tooltipOptions) || tooltipOptions.hover;

      var popupOptions = {
        closeButton: false,
        closeOnClick: false
      };
      if (!hover) {
        popupOptions.anchor = "bottom";
      }

      // create a popup
      var popup = new library.Popup(popupOptions);

      // ensure tooltip is visible
      var panMap = function (map, popup) {
        var style = window.getComputedStyle(popup.getElement());
        var matrix = new DOMMatrixReadOnly(style.transform);
        var padding = 5;
        var extra = 5;
        var top = matrix.m42;
        var left = matrix.m41;

        // TODO add right and bottom
        if (top < padding || left < padding) {
          map.panBy([Math.min(left - padding - extra, 0), Math.min(top - padding - extra, 0)]);
        }
      };

      var showPopup = function (e) {
        var feature = selectedFeature(e);
        var tooltip = feature.properties.tooltip;

        if (!tooltip) {
          return
        }

        if (feature.properties.icon === "mapkick") {
          popup.options.offset = {
            "top": [0, 14],
            "top-left": [0, 14],
            "top-right": [0, 14],
            "bottom": [0, -44],
            "bottom-left": [0, -44],
            "bottom-right": [0, -44],
            "left": [14, 0],
            "right": [-14, 0]
          };
        } else {
          popup.options.offset = 14;
        }

        // add the tooltip
        popup.setLngLat(feature.geometry.coordinates);
        if (tooltipOptions.html) {
          popup.setHTML(tooltip);
        } else {
          popup.setText(tooltip);
        }
        popup.addTo(map);

        // fix blurriness for non-retina screens
        // https://github.com/mapbox/mapbox-gl-js/pull/3258
        if (popup._container.offsetWidth % 2 !== 0) {
          popup._container.style.width = popup._container.offsetWidth + 1 + "px";
        }

        panMap(map, popup);
      };

      var getLatitude = function (feature) {
        return feature.geometry.coordinates[1]
      };

      var selectedFeature = function (e) {
        var features = e.features;
        var selected = features[0];
        for (var i = 1; i < features.length; i++) {
          var feature = features[i];
          // no need to handle ties since this is stable
          if (getLatitude(feature) < getLatitude(selected)) {
            selected = feature;
          }
        }
        return selected
      };

      if (!hover) {
        var currentPoint = null;

        map.on("click", name, function (e) {
          var point = selectedFeature(e).id;
          if (point !== currentPoint) {
            showPopup(e);
            currentPoint = point;
            e.mapkickPopupOpened = true;
          }
        });

        map.on("click", function (e) {
          if (!e.mapkickPopupOpened) {
            popup.remove();
            currentPoint = null;
          }
        });
      }

      map.on("mouseenter", name, function (e) {
        var tooltip = selectedFeature(e).properties.tooltip;

        if (tooltip) {
          map.getCanvas().style.cursor = "pointer";

          if (hover) {
            showPopup(e);
          }
        }
      });

      map.on("mouseleave", name, function () {
        map.getCanvas().style.cursor = "";

        if (hover) {
          popup.remove();
        }
      });
    }

    var generateMap = function (element, data, options) {
      var geojson = generateGeoJSON(data, options);
      options = options || {};

      for (var i = 0; i < geojson.features.length; i++) {
        bounds.extend(geojson.features[i].geometry.coordinates);
      }

      // remove any child elements
      element.textContent = "";

      var style = options.style;
      if (!style) {
        var isMapLibre = !("accessToken" in library) || /^1\.1[45]/.test(library.version);
        if (isMapLibre) {
          throw new Error("style required for MapLibre")
        } else {
          style = "mapbox://styles/mapbox/streets-v12";
        }
      }

      var mapOptions = {
        container: element,
        style: style,
        dragRotate: false,
        touchZoomRotate: false,
        center: options.center || bounds.getCenter(),
        zoom: options.zoom || 15
      };
      if (!options.style) {
        mapOptions.projection = "mercator";
      }
      if (options.accessToken) {
        mapOptions.accessToken = options.accessToken;
      }
      map = new library.Map(mapOptions);

      if (options.controls) {
        map.addControl(new library.NavigationControl({showCompass: false}));
      }

      if (!options.zoom) {
        // hack to prevent error
        if (!map.style.stylesheet) {
          map.style.stylesheet = {};
        }
        map.fitBounds(bounds, {padding: 40, animate: false, maxZoom: 15});
      }

      this$1$1.map = map;

      onMapLoad(function () {
        if (options.trail) {
          recordTrails(data);

          map.addSource("trails", {
            type: "geojson",
            data: generateTrailsGeoJSON([])
          });

          map.addLayer({
            id: "trails",
            source: "trails",
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

        var color = markerOptions.color || "#f84d4d";
        var image = createMarkerImage(library, color);
        image.addEventListener("load", function () {
          map.addImage("mapkick-15", image);

          addLayer("objects", geojson);

          layersReady = true;
          var cb;
          while ((cb = layersReadyQueue.shift())) {
            cb();
          }
        });
      });
    };

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
    options = Object.assign({}, Mapkick.options, options);
    var tooltipOptions = options.tooltips || {};
    var markerOptions = options.markers || {};
    var bounds = new library.LngLatBounds();

    if (options.replay) {
      fetchData(element, data, options, generateReplayMap);
    } else {
      fetchData(element, data, options, generateMap);

      if (options.refresh) {
        this.intervalId = setInterval(function () {
          fetchData(element, data, options, updateMap);
        }, options.refresh * 1000);
      }
    }
  };

  Map.prototype.getMapObject = function getMapObject () {
    return this.map
  };

  Map.prototype.destroy = function destroy () {
    this.stopRefresh();

    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  };

  Map.prototype.stopRefresh = function stopRefresh () {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  };

  var Mapkick = {
    Map: Map,
    maps: maps,
    options: {},
    library: null
  };

  Mapkick.use = function (library) {
    Mapkick.library = library;
  };

  // not ideal, but allows for simpler integration
  if (typeof window !== "undefined" && !window.Mapkick) {
    window.Mapkick = Mapkick;

    window.dispatchEvent(new Event("mapkick:load"));
  }

  return Mapkick;

}));
