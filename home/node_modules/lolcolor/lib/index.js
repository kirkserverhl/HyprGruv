'use strict';

const ColorBuilder = require('./ColorBuilder');

function convertStringToColor(str) {
  const colorBuilder = new ColorBuilder();
  return colorBuilder.fromString(str).asRgb().butOnly64Colors().create();
}

convertStringToColor.ColorBuilder = ColorBuilder;

module.exports = convertStringToColor;
