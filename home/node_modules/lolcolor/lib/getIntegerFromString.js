'use strict';

const crypto = require('crypto');
const isHexEven = require('./isHexEven');
const splitStringIntoChunks = require('./splitStringIntoChunks');

module.exports = function getIntegerFromString(maxInteger, str) {
  const chunkCount = Math.ceil(Math.log2(maxInteger)); // 3 bits to make 8
  const chunks = splitStringIntoChunks(str, chunkCount);

  const hashedChunks = chunks
    .map(chunk => crypto
      .createHash('md5')
      .update(chunk, 'utf-8')
      .digest('hex')
    );

  const selection = hashedChunks
    // Convert to single bit of a binary number, according to index
    .map((chunk, idx) => isHexEven(chunk) * Math.pow(2, idx))
    // Add together to get complete decimal integer
    .reduce((acc, current) => acc + current, 0);

  return selection;
};
