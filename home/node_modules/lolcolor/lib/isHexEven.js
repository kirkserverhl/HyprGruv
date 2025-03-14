'use strict';

module.exports = function isHexEven(hexString) {
  const evenValues = ['0', '2', '4', '6', '8', 'a', 'c', 'e'];
  const lastValue = hexString[hexString.length - 1];
  return evenValues.includes(lastValue) ? 1 : 0;
};
