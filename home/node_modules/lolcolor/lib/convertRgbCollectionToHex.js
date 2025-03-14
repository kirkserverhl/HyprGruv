'use strict';

function padHex(hex) {
  return hex.length === 1 ? `0${hex}` : hex;;
}

function toHex(color) {
  const hex = color.toString(16);
  return padHex(hex);
}

function convertRgbToHex(r, g, b) {
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`
}

module.exports = function convertRgbCollectionToHex(rgbCollection) {
  return rgbCollection.map((rgbArr) => convertRgbToHex(...rgbArr));
};
