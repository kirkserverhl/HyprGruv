'use strict';

const convertRgbCollectionToHex = require('./convertRgbCollectionToHex');
const getIntegerFromString = require('./getIntegerFromString');

const colors = {
  rgb: [
    [255, 0, 0], // red
    [255, 127, 0], // orange
    [255, 255, 0], // yellow
    [0, 255, 0], // green
    [0, 0, 255], // blue
    [159, 0, 197], // purple
    [150, 75, 0], // brown
    [0, 0, 0], // black
  ],
  hsl: [
    [0, 1.00, 0.50], // red
    [30, 1.00, 0.50], // orange
    [60, 1.00, 0.50], // yellow
    [120, 1.00, 0.50], // green
    [240, 1.00, 0.50], // blue
    [288, 1.00, 0.39], // purple
    [30, 1.00, 0.29], // brown
    [0, 0.00, 0.00], // black
  ],
};

colors.hex = convertRgbCollectionToHex(colors.rgb);

module.exports = function getColorStringFrom8() {
  const selection = getIntegerFromString(7, this.base);

  return colors[this.colorModel][selection];
};
