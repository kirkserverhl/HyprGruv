'use strict';

// const getColorString = require('./getColorString');
const getColorStringFrom256 = require('./getColorStringFrom256');
const getColorStringFrom64 = require('./getColorStringFrom64');
const getColorStringFrom8 = require('./getColorStringFrom8');

const isString = obj => typeof obj === 'string';

const COLOR_MODELS = {
  RGB: 'rgb',
  HEX: 'hex',
  HSL: 'hsl',
};

function ColorBuilder(base = '') {
  this.base = base;
  this.colorModel = COLOR_MODELS.RGB;
  this.getColorString = getColorStringFrom64;

  return this;
}

// asHex? i.e. #
// asName? i.e. 'red', 'green', etc.

// asHsl: [hhh, s.ss, l.ll]
ColorBuilder.prototype.asHsl = function asHsl() {
  this.colorModel = COLOR_MODELS.HSL;
  return this;
};

// asHsl: #rrggbb
ColorBuilder.prototype.asHex = function asHex() {
  this.colorModel = COLOR_MODELS.HEX;
  return this;
};

// asRgb: [rrr, ggg, bbb]
ColorBuilder.prototype.asRgb = function asRgb() {
  this.colorModel = COLOR_MODELS.RGB;
  return this;
};

ColorBuilder.prototype.butOnly256Colors = function butOnly256Colors() {
  this.getColorString = getColorStringFrom256;
  return this;
};

ColorBuilder.prototype.butOnly64Colors = function butOnly64Colors() {
  this.getColorString = getColorStringFrom64;
  return this;
};

ColorBuilder.prototype.butOnly8Colors = function butOnly8Colors() {
  this.getColorString = getColorStringFrom8;
  return this;
};

ColorBuilder.prototype.fromString = function fromString(str) {
  this.base = str;
  return this;
};

ColorBuilder.prototype._createHex = function _createHex() {
  if (isString(this.base)) {
    return this.getColorString();
  }
};

ColorBuilder.prototype._createHsl = function _createHsl() {
  if (isString(this.base)) {
    return this.getColorString();
  }
};

ColorBuilder.prototype._createRgb = function _createRgb() {
  if (isString(this.base)) {
    return this.getColorString();
  }
};

ColorBuilder.prototype.create = function toString() {
  if (this.colorModel === COLOR_MODELS.HEX) return this._createHex();
  if (this.colorModel === COLOR_MODELS.HSL) return this._createHsl();
  if (this.colorModel === COLOR_MODELS.RGB) return this._createRgb();
};

module.exports = ColorBuilder;
